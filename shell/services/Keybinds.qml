pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../lib/keys.mjs" as K
import "../lib/perf.mjs" as P

Singleton {
    id: root

    readonly property var wanted: Settings.values.keybinds
    readonly property bool supported: Compositor.name === "hyprland" || Compositor.name === "sway"
    property var applied: ({})
    readonly property bool lite: Settings.values.performance || Settings.values.toggleState.performance === true

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

    function trim(on: bool): void {
        const args = P.perfArgs(Compositor.name, Compositor.usingLua, on);
        if (Demo.enabled || args === null)
            return;
        Quickshell.execDetached(args);
        if (!on && Compositor.name === "sway")
            rebind.restart();
    }

    onWantedChanged: root.apply(false)
    onLiteChanged: root.trim(root.lite)
    Component.onCompleted: {
        root.apply(false);
        if (root.lite)
            root.trim(true);
    }

    Timer {
        id: rebind
        interval: 600
        onTriggered: root.apply(true)
    }

    Connections {
        target: Compositor.name === "hyprland" ? Hyprland : null
        ignoreUnknownSignals: true
        function onRawEvent(event) {
            if (event.name !== "configreloaded")
                return;
            root.apply(true);
            if (root.lite)
                root.trim(true);
        }
    }
}
