pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../lib/keys.mjs" as K

Singleton {
    id: root

    readonly property var wanted: Settings.values.keybinds
    readonly property bool supported: Compositor.name === "hyprland" || Compositor.name === "sway"
    property var applied: ({})

    function apply(force: bool): void {
        if (Demo.enabled || !root.supported) {
            root.applied = root.wanted;
            return;
        }
        const d = K.diff(force ? {} : root.applied, root.wanted);
        if (!force)
            for (const combo of d.unbind)
                Quickshell.execDetached(K.unbindArgs(Compositor.name, Compositor.usingLua, combo));
        for (const b of d.bind)
            Quickshell.execDetached(K.bindArgs(Compositor.name, Compositor.usingLua, b[0], b[1]));
        root.applied = root.wanted;
    }

    onWantedChanged: root.apply(false)
    Component.onCompleted: root.apply(false)

    Connections {
        target: Compositor.name === "hyprland" ? Hyprland : null
        ignoreUnknownSignals: true
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.apply(true);
        }
    }
}
