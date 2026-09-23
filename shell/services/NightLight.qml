pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool demo: Demo.enabled
    property bool installed: false
    readonly property bool available: root.demo || root.installed
    readonly property bool enabled: Settings.values.nightLight.enabled
    readonly property int temperature: Settings.values.nightLight.temperature
    property string error: ""

    function setEnabled(v: bool): void {
        root.error = "";
        if (v && !root.demo)
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
        Settings.set("nightLight.enabled", v);
    }

    Process {
        id: probe
        command: ["sh", "-c", "command -v wlsunset"]
        running: true
        onExited: code => root.installed = code === 0
    }

    Process {
        id: sunset
        command: ["wlsunset", "-T", String(root.temperature + 1), "-t", String(root.temperature)]
        running: !root.demo && root.installed && root.enabled
        onExited: code => {
            if (root.enabled && code !== 0)
                root.error = "wlsunset exited with code " + code;
        }
    }
}
