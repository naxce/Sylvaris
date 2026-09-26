#!/usr/bin/env python3
import configparser
import json
import os
import subprocess
import sys

PREF = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'


def write(path, content):
    try:
        with open(path) as f:
            if f.read() == content:
                return "same"
    except OSError:
        pass
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".part"
    with open(tmp, "w") as f:
        f.write(content)
    os.replace(tmp, path)
    return "written"


def ensure_line(path, line, first=False):
    if os.path.exists(path):
        with open(path) as f:
            text = f.read()
        if line in text.splitlines():
            return "ok"
        if os.path.realpath(path).startswith("/nix/store/"):
            return "add this line yourself: " + line
        new = line + "\n" + text if first else text + ("" if text.endswith("\n") or text == "" else "\n") + line + "\n"
        try:
            with open(path, "w") as f:
                f.write(new)
        except OSError:
            return "add this line yourself: " + line
        return "added"
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(line + "\n")
    return "created"


def profiles(root):
    ini = os.path.join(root, "profiles.ini")
    if not os.path.exists(ini):
        return []
    cp = configparser.ConfigParser()
    try:
        cp.read(ini)
    except configparser.Error:
        return []
    out = []
    for sec in cp.sections():
        if not sec.startswith("Profile") or "Path" not in cp[sec]:
            continue
        p = cp[sec]["Path"]
        path = os.path.join(root, p) if cp[sec].get("IsRelative", "1") == "1" else p
        if os.path.isdir(path):
            out.append(path)
    return out


def firefox(op):
    results = []
    for root in op["roots"]:
        for prof in profiles(root):
            chrome = os.path.join(prof, "chrome")
            results.append({"path": os.path.join(chrome, "sylvaris.css"), "status": write(os.path.join(chrome, "sylvaris.css"), op["content"])})
            results.append({"path": os.path.join(chrome, "userChrome.css"), "status": ensure_line(os.path.join(chrome, "userChrome.css"), '@import "sylvaris.css";', first=True)})
            results.append({"path": os.path.join(prof, "user.js"), "status": ensure_line(os.path.join(prof, "user.js"), PREF)})
    return results


def _skip(t, i):
    while i < len(t):
        if t[i] in " \t\r\n":
            i += 1
        elif t.startswith("//", i):
            j = t.find("\n", i)
            i = len(t) if j < 0 else j + 1
        elif t.startswith("/*", i):
            j = t.find("*/", i + 2)
            i = len(t) if j < 0 else j + 2
        else:
            break
    return i


def _string_end(t, i):
    i += 1
    while i < len(t):
        if t[i] == "\\":
            i += 2
        elif t[i] == '"':
            return i + 1
        else:
            i += 1
    raise ValueError("unterminated string")


def _value_end(t, i):
    if t[i] == '"':
        return _string_end(t, i)
    if t[i] in "{[":
        depth = 0
        while i < len(t):
            i = _skip(t, i)
            c = t[i]
            if c == '"':
                i = _string_end(t, i)
                continue
            if c in "{[":
                depth += 1
            elif c in "}]":
                depth -= 1
                if depth == 0:
                    return i + 1
            i += 1
        raise ValueError("unterminated value")
    while i < len(t) and t[i] not in ",}]\n":
        i += 1
    return i


def set_jsonc_key(text, key, value):
    body = json.dumps(value, indent=2).replace("\n", "\n  ")
    i = _skip(text, 0)
    if i >= len(text) or text[i] != "{":
        raise ValueError("not a JSON object")
    start = i + 1
    i = start
    while True:
        i = _skip(text, i)
        if i >= len(text):
            raise ValueError("unterminated object")
        if text[i] == "}":
            return text[:start] + "\n  " + json.dumps(key) + ": " + body + "," + text[start:]
        if text[i] == ",":
            i += 1
            continue
        if text[i] != '"':
            raise ValueError("unexpected character")
        j = _string_end(text, i)
        name = json.loads(text[i:j])
        i = _skip(text, j)
        if i >= len(text) or text[i] != ":":
            raise ValueError("missing colon")
        vs = _skip(text, i + 1)
        ve = _value_end(text, vs)
        if name == key:
            return text[:vs] + body + text[ve:]
        i = ve


def vscode(op):
    results = []
    for d in op["dirs"]:
        if not os.path.isdir(d):
            results.append({"path": d, "status": "skipped, " + d + " does not exist"})
            continue
        path = os.path.join(d, "settings.json")
        if os.path.realpath(path).startswith("/nix/store/"):
            results.append({"path": path, "status": "failed: settings.json is managed by Nix"})
            continue
        try:
            with open(path) as f:
                text = f.read()
        except FileNotFoundError:
            text = "{}"
        if text.strip() == "":
            text = "{}"
        try:
            new = set_jsonc_key(text, "workbench.colorCustomizations", op["colors"])
            new = set_jsonc_key(new, "editor.tokenColorCustomizations", {"textMateRules": op["tokenColors"]})
        except ValueError as e:
            results.append({"path": path, "status": "failed: settings.json could not be read, " + str(e)})
            continue
        results.append({"path": path, "status": write(path, new)})
    return results


def apply(ops):
    results = []
    for op in ops:
        start = len(results)
        needs = op.get("needs")
        if needs and not os.path.isdir(needs):
            if op["op"] != "run":
                results.append({"path": op.get("path", ""), "status": "skipped, " + needs + " does not exist", "target": op.get("target", "")})
            continue
        try:
            if op["op"] == "write":
                results.append({"path": op["path"], "status": write(op["path"], op["content"])})
            elif op["op"] == "line":
                results.append({"path": op["path"], "status": ensure_line(op["path"], op["line"])})
            elif op["op"] == "run":
                subprocess.run(op["argv"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
            elif op["op"] == "firefox":
                results.extend(firefox(op))
            elif op["op"] == "vscode":
                results.extend(vscode(op))
        except OSError as e:
            results.append({"path": op.get("path", ""), "status": "failed: " + e.strerror})
        for r in results[start:]:
            r["target"] = op.get("target", "")
    return results


def main():
    try:
        ops = json.loads(sys.stdin.read() or "[]")
    except ValueError:
        ops = []
    if not isinstance(ops, list):
        ops = []
    sys.stdout.write(json.dumps(apply(ops)) + "\n")


if __name__ == "__main__":
    main()
