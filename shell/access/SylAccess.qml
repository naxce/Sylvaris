import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs
import qs.services
import qs.components
import qs.settings
import "../lib/access.mjs" as A
import "../lib/icons.mjs" as Icons

Popup {
    id: root

    readonly property var cfg: Settings.values.access
    readonly property var can: A.supports(Compositor.name)
    readonly property string shaderDir: Qt.resolvedUrl("../assets/shaders").toString().replace("file://", "")
    property bool started: false
    property var tools: ({})
    property var applied: []

    namespace: "sylaccess"
    corner: "top-center"
    panelWidth: Tokens.accessWidth
    panelHeight: Tokens.accessHeight

    function apply(): void {
        if (Demo.enabled || Compositor.name !== "hyprland")
            return;
        const cmds = A.hyprCommands(Compositor.usingLua, root.cfg, root.shaderDir);
        root.applied = cmds;
        for (const c of cmds)
            Quickshell.execDetached(["hyprctl"].concat(c));
        if (root.cfg.cursor > 0)
            Quickshell.execDetached(["hyprctl", "setcursor", Quickshell.env("XCURSOR_THEME") || "default", String(root.cfg.cursor)]);
    }

    function zoom(value: string): void {
        const now = root.cfg.zoom;
        const next = value === "in" ? now + 0.5 : value === "out" ? now - 0.5 : Number(value);
        if (!(next >= 1 && next <= 5) && value !== "in" && value !== "out")
            throw new Error("usage: access zoom <in|out|1..5>");
        Settings.set("access.zoom", Math.max(1, Math.min(5, Math.round(next * 10) / 10)));
    }

    function filter(name: string): void {
        if (A.FILTERS.indexOf(name) < 0)
            throw new Error("usage: access filter <" + A.FILTERS.join("|") + ">");
        Settings.set("access.filter", name);
    }

    function toggleTool(bin: string, args: var): void {
        if (!root.tools[bin])
            return;
        Quickshell.execDetached(["sh", "-c", "pkill -x \"$0\" || exec \"$@\"", bin].concat([bin]).concat(args));
    }

    function state(): var {
        return Object.assign({
            open: root.shown,
            compositor: Compositor.name,
            applied: root.applied,
            tools: root.tools
        }, root.cfg);
    }

    onCfgChanged: {
        if (root.started)
            root.apply();
    }

    Component.onCompleted: {
        root.started = true;
        if (root.cfg.zoom !== 1 || root.cfg.filter !== "none" || root.cfg.cursor > 0)
            root.apply();
    }

    Connections {
        target: Compositor.name === "hyprland" ? Hyprland : null
        ignoreUnknownSignals: true
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.apply();
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "for t in orca wvkbd-mobintl; do command -v $t >/dev/null 2>&1 && echo $t; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const t of text.split("\n").filter(Boolean))
                    out[t] = true;
                root.tools = out;
            }
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 22
        contentHeight: page.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        AccessPage {
            id: page
            width: parent.width
            access: root
        }
    }
}
