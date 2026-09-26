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
