pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool demo: Demo.enabled
    readonly property string conName: "sylvaris-hotspot"
    property bool installed: false
    readonly property bool available: root.demo || (root.installed && NetworkService.hasWifi)
    property bool active: false
    property bool profileExists: false
    property string error: ""

    function refresh(): void {
        if (root.demo || !root.installed || query.running)
            return;
        query.running = true;
    }

    function start(ssid: string, password: string, band: string): void {
        if (password.length < 8) {
            root.error = "The password needs at least 8 characters";
            return;
        }
        root.error = "";
        Settings.set("hotspot.ssid", ssid);
        Settings.set("hotspot.band", band);
        if (root.demo) {
            root.active = true;
            root.profileExists = true;
            return;
        }
        startProc.command = ["nmcli", "device", "wifi", "hotspot", "con-name", root.conName, "ssid", ssid, "password", password, "band", band];
        startProc.running = true;
    }

    function resume(): bool {
        if (!root.profileExists)
            return false;
        if (root.demo)
            root.active = true;
        else
            upProc.running = true;
        return true;
    }

    function stop(): void {
        if (root.demo)
            root.active = false;
        else
            downProc.running = true;
    }

    Process {
        id: probe
        command: ["sh", "-c", "command -v nmcli"]
        running: true
        onExited: code => {
            root.installed = code === 0;
            root.refresh();
        }
    }

    Process {
        id: query
        command: ["nmcli", "-t", "-f", "NAME,ACTIVE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                let exists = false;
                let active = false;
                for (const line of text.split("\n")) {
                    const i = line.lastIndexOf(":");
                    if (i < 0 || line.slice(0, i) !== root.conName)
                        continue;
                    exists = true;
                    active = line.slice(i + 1) === "yes";
                }
                root.profileExists = exists;
                root.active = active;
            }
        }
    }

    Process {
        id: startProc
        stderr: StdioCollector {
            id: startErr
        }
        onExited: code => {
            if (code !== 0)
                root.error = startErr.text.trim() || "nmcli could not start the hotspot";
            root.refresh();
        }
    }

    Process {
        id: upProc
        command: ["nmcli", "connection", "up", root.conName]
        onExited: root.refresh()
    }

    Process {
        id: downProc
        command: ["nmcli", "connection", "down", root.conName]
        onExited: root.refresh()
    }
}
