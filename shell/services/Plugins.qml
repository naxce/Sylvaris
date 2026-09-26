pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../lib/plugins.mjs" as P

Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/sylvaris/plugins"
    readonly property var cfg: Settings.values.plugins
    property var list: []
    property string problem: ""
    property bool busy: installer.running

    function refresh(): void {
        scan.running = false;
        scan.running = true;
    }

    function byId(id: string): var {
        return root.list.find(p => p.id === id && p.ok) || null;
    }

    function isEnabled(id: string): bool {
        return root.cfg.enabled[id] === true;
    }

    function active(kind: string): var {
        return root.list.filter(p => p.ok && p.manifest.kind === kind && root.isEnabled(p.id));
    }

    function url(p: var): string {
        return "file://" + p.dir + "/" + p.manifest.entry;
    }

    function api(id: string): var {
        return {
            id: id,
            config: root.cfg.config[id] || {},
            set: (key, value) => Settings.set("plugins.config." + id + "." + key, value),
            run: words => Ipc.run(words)
        };
    }

    function setEnabled(id: string, on: bool): void {
        const next = Object.assign({}, root.cfg.enabled);
        next[id] = on;
        Settings.set("plugins.enabled", next);
    }

    function create(id: string, kind: string): void {
        if (!P.isPluginModule("plugin:" + id))
            throw new Error("a plugin id is lowercase letters, digits and dashes");
        if (P.KINDS.indexOf(kind) < 0)
            throw new Error("kind must be one of " + P.KINDS.join(", "));
        if (root.list.some(p => p.id === id))
            throw new Error(id + " already exists");
        const files = P.skeleton(id, kind);
        writer.command = ["sh", "-c", "mkdir -p \"$0\" && printf '%s' \"$1\" > \"$0/plugin.json\" && printf '%s' \"$2\" > \"$0/Plugin.qml\"", root.dir + "/" + id, files["plugin.json"], files["Plugin.qml"]];
        writer.running = true;
    }

    function install(source: string): void {
        const m = /^https:\/\/[A-Za-z0-9.-]+\/[A-Za-z0-9._\/-]+?\/([a-z0-9][a-z0-9-]{0,39})(\.git)?\/?$/.exec(source || "");
        if (m === null)
            throw new Error("give an https git address whose last part is the plugin id, like https://github.com/you/uptime");
        if (root.list.some(p => p.id === m[1]))
            throw new Error(m[1] + " is already installed");
        root.problem = "";
        installer.command = ["git", "clone", "--depth", "1", "--", source, root.dir + "/" + m[1]];
        installer.running = true;
    }

    function remove(id: string): void {
        if (!P.isPluginModule("plugin:" + id) || !root.list.some(p => p.id === id))
            throw new Error("no plugin called " + id);
        const next = Object.assign({}, root.cfg.enabled);
        delete next[id];
        Settings.set("plugins.enabled", next);
        writer.command = ["rm", "-rf", "--", root.dir + "/" + id];
        writer.running = true;
    }

    function state(): var {
        return {
            dir: root.dir,
            problem: root.problem,
            plugins: root.list.map(p => ({
                        id: p.id,
                        ok: p.ok,
                        error: p.error,
                        kind: p.ok ? p.manifest.kind : "",
                        enabled: root.isEnabled(p.id)
                    }))
        };
    }

    Component.onCompleted: root.refresh()

    Process {
        id: scan
        command: ["sh", "-c", "for d in \"$0\"/*/; do [ -d \"$d\" ] || continue; printf '@@%s\\n' \"$d\"; cat \"$d/plugin.json\" 2>/dev/null; echo; done", root.dir]
        stdout: StdioCollector {
            onStreamFinished: root.list = P.parseScan(text)
        }
    }

    Process {
        id: writer
        onExited: root.refresh()
    }

    Process {
        id: installer
        property string errors: ""
        stderr: StdioCollector {
            onStreamFinished: installer.errors = text.trim()
        }
        onExited: code => {
            root.problem = code === 0 ? "" : installer.errors.split("\n").pop() || "git clone failed";
            root.refresh();
        }
    }
}
