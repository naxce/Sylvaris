import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.services
import qs.components
import "../lib/capture.mjs" as K
import "../lib/icons.mjs" as Icons

Popup {
    id: root

    readonly property var cfg: Settings.values.capture
    readonly property string home: Quickshell.env("HOME")
    property string kind: "shot"
    property string mode: "region"
    property var rects: []
    property string last: ""
    property string problem: ""
    property real recordStart: 0
    property real tick: 0
    readonly property bool recording: recorder.running

    namespace: "sylcapture"
    corner: "top-center"
    panelWidth: Tokens.captureWidth
    panelHeight: Tokens.captureHeight

    function shoot(mode: string): void {
        root.kind = "shot";
        root.start(mode);
    }

    function record(mode: string): void {
        if (root.recording)
            return;
        root.kind = "video";
        root.start(mode === "screen" ? "screen" : "region");
    }

    function start(requested: string): void {
        const mode = requested === "area" ? "region" : requested;
        if (["region", "window", "screen"].indexOf(mode) < 0)
            throw new Error("usage: capture shot <region|window|screen> or capture record <region|screen>");
        root.mode = mode;
        root.problem = "";
        root.close();
        if (mode === "window" && root.kind === "shot")
            rectsProc.running = true;
        else
            later.restart();
    }

    function stop(): void {
        if (root.recording)
            recorder.signal(2);
    }

    function state(): var {
        return {
            open: root.shown,
            recording: root.recording,
            last: root.last,
            problem: root.problem
        };
    }

    function notify(title: string, file: string): void {
        if (!Demo.enabled)
            Quickshell.execDetached(["notify-send", "-a", "Sylvaris", "-i", file, title, file]);
    }

    Timer {
        id: later
        interval: 320
        onTriggered: {
            const out = Compositor.focusedName();
            const dir = K.expand(root.kind === "video" ? root.cfg.videos : root.cfg.folder, root.home);
            const name = K.fileName(root.kind, new Date());
            if (root.kind === "video") {
                recorder.command = ["sh", "-c", "mkdir -p \"$0\"; f=\"$0/$1\"; if [ \"$2\" = region ]; then g=$(slurp -d) || exit 3; set -- -g \"$g\"; else set -- -o \"$3\"; fi; if [ \"$4\" = 1 ]; then set -- \"$@\" \"--audio=$(pactl get-default-sink).monitor\"; fi; echo \"$f\"; exec wf-recorder \"$@\" -f \"$f\"", dir, name, root.mode, out, root.cfg.audio ? "1" : "0"];
                recorder.running = true;
                root.recordStart = Date.now();
            } else {
                shooter.command = ["sh", "-c", "mkdir -p \"$0\"; f=\"$0/$1\"; [ \"$5\" = 1 ] || f=\"${XDG_RUNTIME_DIR:-/tmp}/sylvaris-shot.png\"; case \"$2\" in region) g=$(slurp -d) || exit 3 ;; window) g=$(printf '%s\\n' \"$6\" | slurp -r) || exit 3 ;; *) g= ;; esac; sleep \"$3\"; if [ -n \"$g\" ]; then grim -g \"$g\" \"$f\"; else grim -o \"$7\" \"$f\"; fi || exit 4; [ \"$4\" = 1 ] && wl-copy -t image/png < \"$f\"; echo \"$f\"", dir, name, root.mode, String(root.cfg.delay), root.cfg.copy ? "1" : "0", root.cfg.save ? "1" : "0", root.rects.join("\n"), out];
                shooter.running = true;
            }
        }
    }

    Process {
        id: rectsProc
        command: Compositor.name === "hyprland" ? ["sh", "-c", "hyprctl -j clients; echo; echo '\u001e'; hyprctl -j monitors"] : Compositor.name === "sway" ? ["swaymsg", "-t", "get_tree"] : ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (Compositor.name === "hyprland") {
                        const parts = text.split("\u001e");
                        root.rects = K.hyprRects(JSON.parse(parts[0]), JSON.parse(parts[1]));
                    } else if (Compositor.name === "sway") {
                        root.rects = K.swayRects(JSON.parse(text));
                    } else {
                        root.rects = [];
                    }
                } catch (e) {
                    root.rects = [];
                }
                if (root.rects.length === 0)
                    root.mode = "region";
                later.restart();
            }
        }
    }

    Process {
        id: shooter
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim();
                if (f !== "") {
                    root.last = f;
                    root.notify(root.cfg.save ? "Screenshot saved" : "Screenshot copied", f);
                }
            }
        }
        onExited: code => {
            if (code === 4)
                root.problem = "grim could not take the screenshot";
        }
    }

    Process {
        id: recorder
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("/") === 0)
                    root.last = line;
            }
        }
        onExited: code => {
            if (root.last !== "" && code !== 3)
                root.notify("Recording saved", root.last);
        }
    }

    Timer {
        running: root.recording
        interval: 500
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick = Date.now()
    }

    LazyLoader {
        active: root.recording

        PanelWindow {
            anchors.top: true
            margins.top: Tokens.edgeMargin + Tokens.barItemHeight + 10
            implicitWidth: pill.width
            implicitHeight: pill.height
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "sylcapture-pill"

            Item {
                id: pill
                width: pillRow.implicitWidth + 28
                height: 40

                Glass {
                    anchors.fill: parent
                    radius: height / 2
                    offColor: Theme.surface
                    offBorder: Theme.line
                }

                Row {
                    id: pillRow
                    anchors.centerIn: parent
                    spacing: 10

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10
                        height: 10
                        radius: 5
                        color: Theme.danger

                        SequentialAnimation on opacity {
                            running: root.recording
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 0.3
                                duration: 700
                            }
                            NumberAnimation {
                                to: 1
                                duration: 700
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: K.elapsed(root.tick - root.recordStart)
                        color: Theme.text
                        font.family: Tokens.fontMono
                        font.pixelSize: Tokens.bodySize
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        height: 26
                        radius: 13
                        color: stopArea.containsMouse ? Theme.danger : Qt.alpha(Theme.danger, 0.75)

                        Rectangle {
                            anchors.centerIn: parent
                            width: 9
                            height: 9
                            radius: 2
                            color: Theme.base
                        }

                        MouseArea {
                            id: stopArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.stop()
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: 22

        Row {
            id: head
            spacing: 10

            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.GLYPHS.camera
                size: 20
                color: Theme.accent
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Capture"
                color: Theme.text
                font.family: Tokens.fontUi
                font.pixelSize: Tokens.titleSize
                font.weight: Font.DemiBold
            }
        }

        Segmented {
            id: kindPick
            anchors.right: parent.right
            anchors.verticalCenter: head.verticalCenter
            width: 220
            options: [
                {
                    key: "shot",
                    label: "Screenshot"
                },
                {
                    key: "video",
                    label: "Record"
                }
            ]
            current: root.kind
            onPicked: key => root.kind = key
        }

        Row {
            id: modes
            anchors.top: head.bottom
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Repeater {
                model: root.kind === "video" ? [
                    {
                        key: "region",
                        label: "Area",
                        glyph: Icons.GLYPHS.region
                    },
                    {
                        key: "screen",
                        label: "Screen",
                        glyph: Icons.GLYPHS.displays
                    }
                ] : [
                    {
                        key: "region",
                        label: "Area",
                        glyph: Icons.GLYPHS.region
                    },
                    {
                        key: "window",
                        label: "Window",
                        glyph: Icons.GLYPHS.windowPick
                    },
                    {
                        key: "screen",
                        label: "Screen",
                        glyph: Icons.GLYPHS.displays
                    }
                ]

                delegate: Item {
                    id: tile
                    required property var modelData
                    width: 118
                    height: 104
                    scale: tileArea.pressed ? 0.95 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: Tokens.stateDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Glass {
                        anchors.fill: parent
                        radius: Tokens.radiusCard
                        inner: true
                        hot: tileArea.containsMouse
                        lit: tileArea.containsMouse
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Glyph {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.kind === "video" && tile.modelData.key !== "window" ? (tileArea.containsMouse ? Icons.GLYPHS.record : tile.modelData.glyph) : tile.modelData.glyph
                            size: 30
                            color: tileArea.containsMouse ? Theme.onAccent : root.kind === "video" ? Theme.danger : Theme.accent
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.label
                            color: tileArea.containsMouse ? Theme.onAccent : Theme.text
                            font.family: Tokens.fontUi
                            font.pixelSize: Tokens.bodySize
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: tileArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.kind === "video" ? root.record(tile.modelData.key) : root.shoot(tile.modelData.key)
                    }
                }
            }
        }

        Column {
            anchors.top: modes.bottom
            anchors.topMargin: 20
            width: parent.width
            spacing: 10

            Row {
                spacing: 10
                visible: root.kind === "shot"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 110
                    text: "Delay"
                    color: Theme.textDim
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.smallSize
                }

                Segmented {
                    width: 260
                    options: K.DELAYS.map(d => ({
                                key: String(d),
                                label: d === 0 ? "None" : d + " s"
                            }))
                    current: String(root.cfg.delay)
                    onPicked: key => Settings.set("capture.delay", Number(key))
                }
            }

            Row {
                spacing: 10
                visible: root.kind === "video"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 110
                    text: "Desktop sound"
                    color: Theme.textDim
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.smallSize
                }

                Toggle {
                    checked: root.cfg.audio
                    onToggled: v => Settings.set("capture.audio", v)
                }
            }

            Text {
                width: parent.width
                text: root.problem !== "" ? root.problem : root.kind === "video" ? "Saves to " + root.cfg.videos : (root.cfg.copy ? "Copies to the clipboard" : "") + (root.cfg.copy && root.cfg.save ? " and saves to " : root.cfg.save ? "Saves to " : "") + (root.cfg.save ? root.cfg.folder : "")
                elide: Text.ElideMiddle
                color: root.problem !== "" ? Theme.danger : Theme.textDim
                font.family: Tokens.fontUi
                font.pixelSize: Tokens.smallSize
            }
        }
    }
}
