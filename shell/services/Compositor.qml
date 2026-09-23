pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.I3
import "../lib/screens.mjs" as Screens

Singleton {
    id: root

    readonly property string name: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ? "hyprland" : Quickshell.env("NIRI_SOCKET") ? "niri" : Quickshell.env("SWAYSOCK") ? "sway" : "unknown"
    property string niriFocused: ""
    property var pending: []

    function focusedName(): string {
        if (root.name === "hyprland")
            return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        if (root.name === "sway")
            return I3.focusedMonitor ? I3.focusedMonitor.name : "";
        if (root.name === "niri")
            return root.niriFocused;
        return "";
    }

    function screenNames(): var {
        const out = [];
        for (const s of Quickshell.screens)
            out.push(s.name);
        return out;
    }

    function screenFor(name: string): var {
        const i = Screens.pickScreen(root.screenNames(), name);
        return i < 0 ? null : Quickshell.screens[i];
    }

    function flush(): void {
        const callbacks = root.pending;
        root.pending = [];
        for (const cb of callbacks)
            cb();
    }

    function refresh(callback: var): void {
        if (root.name !== "niri") {
            callback();
            return;
        }
        root.pending = root.pending.concat([callback]);
        niriTimeout.restart();
        if (!niriQuery.running)
            niriQuery.running = true;
    }

    Timer {
        id: niriTimeout
        interval: 300
        onTriggered: root.flush()
    }

    Process {
        id: niriQuery
        command: ["niri", "msg", "--json", "focused-output"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.niriFocused = JSON.parse(text).name;
                } catch (e) {
                    root.niriFocused = "";
                }
                niriTimeout.stop();
                root.flush();
            }
        }
    }
}
