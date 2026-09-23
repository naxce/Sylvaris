pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool demo: Demo.enabled
    property string tool: ""
    property bool enabled: false
    readonly property bool available: root.demo || root.tool !== ""

    function refresh(): void {
        if (root.demo || root.tool === "" || query.running)
            return;
        query.command = root.tool === "swaync" ? ["swaync-client", "-D"] : ["makoctl", "mode"];
        query.running = true;
    }

    function setEnabled(v: bool): void {
        if (!root.demo) {
            if (root.tool === "swaync")
                Quickshell.execDetached(["swaync-client", v ? "-dn" : "-df"]);
            else if (root.tool === "mako")
                Quickshell.execDetached(["makoctl", "mode", v ? "-a" : "-r", "do-not-disturb"]);
        }
        root.enabled = v;
    }

    Process {
        id: probe
        running: true
        command: ["sh", "-c", "if command -v swaync-client >/dev/null; then echo swaync; elif command -v makoctl >/dev/null; then echo mako; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.tool = text.trim();
                root.refresh();
            }
        }
    }

    Process {
        id: query
        stdout: StdioCollector {
            onStreamFinished: root.enabled = root.tool === "swaync" ? text.trim() === "true" : text.split("\n").indexOf("do-not-disturb") >= 0
        }
    }
}
