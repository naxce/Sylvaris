import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs
import qs.services
import qs.components
import "../lib/bar.mjs" as B
import "../lib/eq.mjs" as E
import "../lib/wm.mjs" as W
import "../lib/power.mjs" as Pw
import "../lib/icons.mjs" as Icons
import "../lib/settings.mjs" as S

Scope {
    id: root

    property bool shown: false
    property bool wanted: false
    property var screenInfo: null
    property real reveal: 0
    property real dive: 0
    property real swap: 1
    property real time: 0
    property string section: ""
    property string shownSection: ""
    property int hovered: -1
    property string memory: ""
    property string uptimeText: ""
    readonly property string version: "0.2.0"
    readonly property bool hasBattery: UPower.displayDevice !== null && UPower.displayDevice.isLaptopBattery
    readonly property var cons: Settings.values.constellation
    readonly property var sections: [
        {
            key: "general",
            label: "General",
            glyph: Icons.GLYPHS.tune
        },
        {
            key: "appearance",
            label: "Appearance",
            glyph: Icons.GLYPHS.theme
        },
        {
            key: "motion",
            label: "Motion",
            glyph: Icons.GLYPHS.bolt
        },
        {
            key: "wallpaper",
            label: "Wallpaper",
            glyph: Icons.GLYPHS.image
        },
        {
            key: "bar",
            label: "Bar",
            glyph: Icons.GLYPHS.grid
        },
        {
            key: "deck",
            label: "Deck",
            glyph: Icons.GLYPHS.pin
        },
        {
            key: "launcher",
            label: "Launcher",
            glyph: Icons.GLYPHS.apps
        },
        {
            key: "notifications",
            label: "Notifications",
            glyph: Icons.GLYPHS.bell
        },
        {
            key: "sound",
            label: "Sound",
            glyph: Icons.GLYPHS.volume
        },
        {
            key: "displays",
            label: "Displays",
            glyph: Icons.GLYPHS.displays
        },
        {
            key: "clock",
            label: "Sky",
            glyph: Icons.GLYPHS.night
        },
        {
            key: "weather",
            label: "Weather",
            glyph: Icons.GLYPHS.partlyCloudy
        },
        {
            key: "power",
            label: "Power",
            glyph: Icons.GLYPHS.power
        },
        {
            key: "diver",
            label: "Diver",
            glyph: Icons.GLYPHS.planner
        },
        {
            key: "commands",
            label: "Commands",
            glyph: Icons.GLYPHS.keyboard
        }
    ]
    readonly property var corners: [
        {
            key: "top-left",
            label: "Left"
        },
        {
            key: "top-center",
            label: "Center"
        },
        {
            key: "top-right",
            label: "Right"
        }
    ]
    readonly property var glassKeys: [
        {
            key: "opacity",
            label: "Panel opacity",
            max: 1
        },
        {
            key: "layerOpacity",
            label: "Tile opacity",
            max: 1
        },
        {
            key: "tint",
            label: "Accent tint",
            max: 1
        },
        {
            key: "sheen",
            label: "Sheen",
            max: 1
        },
        {
            key: "flow",
            label: "Sheen movement",
            max: 3
        },
        {
            key: "rim",
            label: "Rim light",
            max: 1
        },
        {
            key: "grain",
            label: "Grain",
            max: 0.2
        }
    ]
    readonly property var binds: [
        {
            label: "Control center",
            key: "A",
            command: "sylvaris center"
        },
        {
            label: "Clock and calendar",
            key: "D",
            command: "sylvaris clock"
        },
        {
            label: "Notifications",
            key: "N",
            command: "sylvaris notify"
        },
        {
            label: "App launcher",
            key: "Space",
            command: "sylvaris pad"
        },
        {
            label: "Media",
            key: "P",
            command: "sylvaris media open"
        },
        {
            label: "Theme picker",
            key: "T",
            command: "sylvaris theme"
        },
        {
            label: "Power menu",
            key: "Escape",
            command: "sylvaris power"
        },
        {
            label: "Wallpaper picker",
            key: "W",
            command: "sylvaris paper"
        },
        {
            label: "Settings",
            key: "comma",
            command: "sylvaris settings"
        },
        {
            label: "Play or pause",
            key: "XF86AudioPlay",
            command: "sylvaris media toggle"
        },
        {
            label: "Volume up",
            key: "XF86AudioRaiseVolume",
            command: "sylvaris audio up 5"
        },
        {
            label: "Volume down",
            key: "XF86AudioLowerVolume",
            command: "sylvaris audio down 5"
        }
    ]

    signal opened
    signal partRequested(string name, string arg)

    function phase(a: real, b: real): real {
        const t = Math.max(0, Math.min(1, (root.reveal - a) / (b - a)));
        return 1 - Math.pow(1 - t, 3);
    }

    function sectionInfo(key: string): var {
        return root.sections.filter(s => s.key === key)[0] || null;
    }

    function show(screen: var): void {
        root.screenInfo = screen;
        root.shown = true;
        statsFile.reload();
        uptimeFile.reload();
        hideAnim.stop();
        showAnim.restart();
        root.opened();
    }

    function open(): void {
        if (root.wanted)
            return;
        root.wanted = true;
        Compositor.refresh(() => {
            if (root.wanted)
                root.show(Compositor.screenFor(Compositor.focusedName()));
        });
    }

    function toggleOn(screen: var): void {
        if (root.wanted) {
            root.close();
            return;
        }
        root.wanted = true;
        root.show(screen);
    }

    function close(): void {
        root.wanted = false;
        if (!root.shown)
            return;
        showAnim.stop();
        hideAnim.restart();
    }

    function toggle(): void {
        if (root.wanted)
            root.close();
        else
            root.open();
    }

    function go(name: string): void {
        if (name === root.section)
            return;
        root.section = name;
        swapAnim.restart();
    }

    function back(): void {
        if (root.section !== "")
            root.go("");
        else
            root.close();
    }

    function showSection(name: string): void {
        root.go(name !== "" && root.sectionInfo(name) !== null ? name : name === "" ? root.section : "");
        root.open();
    }

    function hand(name: string, arg: string): void {
        root.close();
        root.partRequested(name, arg);
    }

    function glass(key: string): real {
        return Resin.values[key];
    }

    function node(i: int, n: int, rx: real, ry: real): var {
        const a = -Math.PI / 2 + Math.PI * 2 * i / Math.max(1, n) + root.time * 0.05;
        return {
            x: Math.cos(a) * rx,
            y: Math.sin(a) * ry,
            depth: (Math.sin(a) + 1) / 2
        };
    }

    function star(i: int): var {
        const r = n => {
            const x = Math.sin(i * 12.9898 + n * 78.233) * 43758.5453;
            return x - Math.floor(x);
        };
        return {
            x: r(1),
            y: r(2),
            size: 1 + r(3) * 2.2,
            speed: 0.4 + r(4) * 1.4,
            glow: r(5)
        };
    }

    onSectionChanged: {
        if (root.section !== "")
            diveIn.restart();
        else
            diveOut.restart();
    }

    NumberAnimation {
        id: showAnim
        target: root
        property: "reveal"
        to: 1
        duration: Math.round(900 * Tokens.pace)
    }

    NumberAnimation {
        id: hideAnim
        target: root
        property: "reveal"
        to: 0
        duration: Tokens.exitDuration + 120
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.exitCurve
        onFinished: root.shown = false
    }

    NumberAnimation {
        id: diveIn
        target: root
        property: "dive"
        to: 1
        duration: Tokens.moveDuration + 120
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.moveCurve
    }

    NumberAnimation {
        id: diveOut
        target: root
        property: "dive"
        to: 0
        duration: Tokens.moveDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.moveCurve
    }

    SequentialAnimation {
        id: swapAnim

        NumberAnimation {
            target: root
            property: "swap"
            to: 0
            duration: root.shownSection === "" ? 0 : Tokens.exitDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.exitCurve
        }
        ScriptAction {
            script: {
                root.shownSection = root.section;
                content.contentY = 0;
            }
        }
        NumberAnimation {
            target: root
            property: "swap"
            to: 1
            duration: Tokens.enterDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.enterCurve
        }
    }

    FileView {
        id: statsFile
        path: "/proc/self/status"
        printErrors: false
        onLoaded: {
            const m = /VmRSS:\s+(\d+)/.exec(text());
            root.memory = m ? Math.round(Number(m[1]) / 1024) + " MB" : "";
        }
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        printErrors: false
        onLoaded: root.uptimeText = Pw.uptime(Number(text().split(" ")[0]))
    }

    Timer {
        interval: 5000
        running: root.shown
        repeat: true
        onTriggered: {
            statsFile.reload();
            uptimeFile.reload();
        }
    }

    PanelWindow {
        id: win
        visible: root.shown
        screen: root.screenInfo
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "sylsettings"
        WlrLayershell.keyboardFocus: root.wanted ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        readonly property real side: Math.min(400, Math.max(300, width * 0.17))
        readonly property real gutter: Math.max(24, width * 0.018)
        readonly property real midX: win.gutter * 2 + win.side
        readonly property real midW: win.width - (win.gutter * 2 + win.side) * 2

        onVisibleChanged: {
            if (visible)
                keys.forceActiveFocus();
        }

        FrameAnimation {
            running: win.visible && !Tokens.lite && (root.cons.speed > 0 || root.cons.stars)
            onTriggered: root.time += frameTime * Math.max(0.2, root.cons.speed)
        }

        Backdrop {
            anchors.fill: parent
            opacity: root.phase(0, 0.3)
        }

        Item {
            anchors.fill: parent
            visible: root.cons.stars && !Tokens.lite
            opacity: root.phase(0.1, 0.6)

            Repeater {
                model: 90

                delegate: Rectangle {
                    required property int index
                    readonly property var s: root.star(index)
                    x: s.x * win.width
                    y: s.y * win.height
                    width: s.size
                    height: s.size
                    radius: s.size / 2
                    color: s.glow > 0.8 ? Theme.accentHi : Theme.text
                    opacity: (0.15 + 0.35 * s.glow) * (0.6 + 0.4 * Math.sin(root.time * s.speed + index))
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.back()
        }

        Item {
            id: keys
            focus: true
            Keys.onEscapePressed: root.back()
            Keys.onLeftPressed: root.hovered = (root.hovered - 1 + root.sections.length) % root.sections.length
            Keys.onRightPressed: root.hovered = (root.hovered + 1) % root.sections.length
            Keys.onReturnPressed: {
                if (root.hovered >= 0)
                    root.go(root.sections[root.hovered].key);
            }
        }

        Item {
            id: hub
            readonly property real cx: win.midX + win.midW / 2
            readonly property real cy: win.height * 0.5
            readonly property real rx: Math.min(win.midW * 0.42, 560)
            readonly property real ry: Math.min(win.height * 0.3, hub.rx * 0.52)
            readonly property real mini: 0.38
            readonly property real targetY: win.gutter + 20 + (hub.ry + 70) * hub.mini
            anchors.fill: parent
            opacity: root.phase(0.1, 0.5) * (1 - 0.2 * root.dive)

            transform: [
                Scale {
                    origin.x: hub.cx
                    origin.y: hub.cy
                    xScale: 1 - (1 - hub.mini) * root.dive
                    yScale: 1 - (1 - hub.mini) * root.dive
                },
                Translate {
                    y: (hub.targetY - hub.cy) * root.dive
                }
            ]

            Shape {
                anchors.fill: parent
                visible: root.cons.ring
                opacity: root.phase(0.15, 0.55) * 0.8
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: Qt.alpha(Theme.text, 0.14)
                    strokeWidth: 1.5
                    fillColor: "transparent"
                    strokeStyle: ShapePath.DashLine
                    dashPattern: [2, 9]

                    PathAngleArc {
                        centerX: hub.cx
                        centerY: hub.cy
                        radiusX: hub.rx * (0.7 + 0.3 * root.phase(0.15, 0.55))
                        radiusY: hub.ry * (0.7 + 0.3 * root.phase(0.15, 0.55))
                        startAngle: 0
                        sweepAngle: 360
                    }
                }
            }

            Repeater {
                model: root.cons.links ? root.sections : []

                delegate: Shape {
                    id: link
                    required property var modelData
                    required property int index
                    readonly property var p: root.node(link.index, root.sections.length, hub.rx, hub.ry)
                    readonly property bool on: root.hovered === link.index || root.section === link.modelData.key
                    anchors.fill: parent
                    opacity: root.phase(0.35, 0.8) * (link.on ? 0.85 : 0.14)
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: link.on ? 2.5 : 1.5
                        strokeColor: link.on ? Theme.accentHi : Theme.text
                        fillColor: "transparent"
                        startX: hub.cx
                        startY: hub.cy
                        PathQuad {
                            controlX: hub.cx + link.p.x * 0.5 + 30 * Math.sin(root.time * 0.7 + link.index)
                            controlY: hub.cy + link.p.y * 0.5 - 24
                            x: hub.cx + link.p.x
                            y: hub.cy + link.p.y
                        }
                    }
                }
            }

            Item {
                x: hub.cx - width / 2
                y: hub.cy - height / 2
                width: 170
                height: 170
                opacity: root.phase(0.05, 0.45)
                scale: 0.6 + 0.4 * root.phase(0.05, 0.45)

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 30 + 8 * Math.sin(root.time * 1.3)
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Qt.alpha(Theme.accent, 0.35)
                }

                Glass {
                    anchors.fill: parent
                    radius: width / 2
                    raised: true
                    lit: root.section !== ""
                }

                Glyph {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -12
                    text: root.section === "" ? Icons.GLYPHS.settings : root.sectionInfo(root.section).glyph
                    size: 54
                    color: root.section === "" ? Theme.accent : Theme.onAccent
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 30
                    text: root.section === "" ? "Settings" : "Back"
                    color: root.section === "" ? Theme.textSoft : Theme.onAccent
                    font.family: Tokens.fontUi
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go("")
                }
            }

            Repeater {
                model: root.sections

                delegate: Item {
                    id: star
                    required property var modelData
                    required property int index
                    readonly property var p: root.node(star.index, root.sections.length, hub.rx, hub.ry)
                    readonly property bool on: root.section === star.modelData.key
                    readonly property bool hot: root.hovered === star.index
                    readonly property real arrive: root.phase(0.25 + 0.4 * star.index / root.sections.length, 0.65 + 0.3 * star.index / root.sections.length)
                    x: hub.cx + star.p.x * (0.4 + 0.6 * star.arrive) - width / 2
                    y: hub.cy + star.p.y * (0.4 + 0.6 * star.arrive) - height / 2
                    width: 104
                    height: 104
                    z: star.hot ? 3 : 1 + star.p.depth
                    opacity: star.arrive
                    scale: (0.5 + 0.5 * star.arrive) * (0.86 + 0.14 * star.p.depth) * (starArea.pressed ? 0.92 : star.hot || star.on ? 1.14 : 1)

                    Behavior on scale {
                        enabled: star.arrive >= 1
                        NumberAnimation {
                            duration: Tokens.stateDuration + 80
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Tokens.springCurve
                        }
                    }

                    Glass {
                        anchors.fill: parent
                        radius: width / 2
                        raised: star.hot || star.on
                        lit: star.on
                        hot: star.hot
                    }

                    Glyph {
                        anchors.centerIn: parent
                        text: star.modelData.glyph
                        size: 36
                        color: star.on ? Theme.onAccent : star.hot ? Theme.accentHi : Theme.text
                    }

                    Text {
                        visible: root.cons.labels || star.hot
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: 10
                        text: star.modelData.label
                        color: star.hot || star.on ? Theme.text : Theme.textSoft
                        font.family: Tokens.fontUi
                        font.pixelSize: 16
                        font.weight: star.hot || star.on ? Font.DemiBold : Font.Medium
                        style: Text.Raised
                        styleColor: Qt.alpha("#000000", 0.3)
                    }

                    MouseArea {
                        id: starArea
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hovered = star.index
                        onExited: {
                            if (root.hovered === star.index)
                                root.hovered = -1;
                        }
                        onClicked: root.go(star.modelData.key)
                    }
                }
            }
        }

        Text {
            x: hub.cx - width / 2
            y: win.height - 120
            visible: root.dive < 0.99
            opacity: root.phase(0.6, 1) * (1 - root.dive)
            text: root.hovered >= 0 ? "Open " + root.sections[root.hovered].label.toLowerCase() : "Pick a star to change that part of Sylvaris"
            color: Theme.textSoft
            font.family: Tokens.fontUi
            font.pixelSize: 20
        }

        SidePanel {
            id: leftPanel
            x: win.gutter - (1 - root.phase(0.3, 0.8)) * 60
            y: win.gutter
            width: win.side
            height: win.height - win.gutter * 2
            opacity: root.phase(0.3, 0.8)
            title: "Constellation"
            glyph: Icons.GLYPHS.stars

            ConstellationControls {
                width: parent.width
            }
        }

        SidePanel {
            id: rightPanel
            x: win.width - win.gutter - win.side + (1 - root.phase(0.35, 0.85)) * 60
            y: win.gutter
            width: win.side
            height: win.height - win.gutter * 2
            opacity: root.phase(0.35, 0.85)
            title: "Statistics"
            glyph: Icons.GLYPHS.chart

            StatsAbout {
                width: parent.width
                version: root.version
                memory: root.memory
                uptime: root.uptimeText
                onReload: Quickshell.reload(false)
            }
        }

        Item {
            id: sheet
            readonly property real startY: win.gutter + 30 + (hub.ry + 70) * 2 * hub.mini
            x: win.midX + (win.midW - width) / 2
            y: sheet.startY + (1 - root.dive) * 80
            width: Math.min(win.midW - win.gutter, 860)
            height: win.height - sheet.startY - win.gutter
            visible: root.dive > 0.01
            opacity: root.dive

            MouseArea {
                anchors.fill: parent
            }

            Glass {
                anchors.fill: parent
                radius: Tokens.radiusPanel
                raised: true
                offColor: Theme.surface
                offBorder: Theme.line
            }

            Row {
                id: sheetHead
                x: 30
                y: 24
                spacing: 14
                opacity: root.swap

                Glyph {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.shownSection === "" ? "" : root.sectionInfo(root.shownSection).glyph
                    size: 24
                    color: Theme.accent
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.shownSection === "" ? "" : root.sectionInfo(root.shownSection).label
                    color: Theme.text
                    font.family: Tokens.fontUi
                    font.pixelSize: 26
                    font.weight: Font.DemiBold
                }
            }

            Glyph {
                anchors.right: parent.right
                anchors.rightMargin: 28
                anchors.verticalCenter: sheetHead.verticalCenter
                text: Icons.GLYPHS.close
                size: 20
                color: sheetClose.containsMouse ? Theme.text : Theme.textDim

                MouseArea {
                    id: sheetClose
                    anchors.fill: parent
                    anchors.margins: -10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go("")
                }
            }

            Flickable {
                id: content
                x: 30
                y: sheetHead.y + sheetHead.height + 22
                width: parent.width - 60
                height: parent.height - y - 20
                clip: true
                contentHeight: page.item ? page.item.implicitHeight + 20 : 0
                boundsBehavior: Flickable.StopAtBounds
                opacity: root.swap

                Loader {
                    id: page
                    width: content.width
                    y: (1 - root.swap) * 18
                    sourceComponent: ({
                            general: generalPage,
                            appearance: appearancePage,
                            motion: motionPage,
                            wallpaper: wallpaperPage,
                            bar: barPage,
                            deck: deckPage,
                            launcher: launcherPage,
                            notifications: notificationsPage,
                            sound: soundPage,
                            displays: displaysPage,
                            clock: clockPage,
                            weather: weatherPage,
                            power: powerPage,
                            diver: diverPage,
                            commands: commandsPage
                        })[root.shownSection] || null
                }
            }
        }
    }

    Component {
        id: generalPage

        Column {
            spacing: 24

            Card {
                title: "Panels"

                SettingRow {
                    title: "Control center"
                    subtitle: "Where SylCenter and SylMedia open"

                    Segmented {
                        width: 300
                        options: root.corners
                        current: Settings.values.center.corner
                        onPicked: key => Settings.set("center.corner", key)
                    }
                }

                SettingRow {
                    title: "Clock"
                    subtitle: "Where SylClock opens"

                    Segmented {
                        width: 300
                        options: root.corners
                        current: Settings.values.clock.corner
                        onPicked: key => Settings.set("clock.corner", key)
                    }
                }

                SettingRow {
                    title: "Notifications"
                    subtitle: "Where toasts and the notification center appear"
                    last: true

                    Segmented {
                        width: 300
                        options: root.corners
                        current: Settings.values.notifications.corner
                        onPicked: key => Settings.set("notifications.corner", key)
                    }
                }
            }

            Card {
                title: "Parts"
                note: "An excluded part is not loaded, and neither is anything only it uses. The same switch works without this panel: sylvaris set parts.<name> false"

                Repeater {
                    model: Object.keys(S.PARTS)

                    delegate: SettingRow {
                        required property string modelData
                        required property int index
                        title: "Syl" + modelData.charAt(0).toUpperCase() + modelData.slice(1)
                        subtitle: "parts." + modelData
                        last: index === Object.keys(S.PARTS).length - 1

                        Toggle {
                            checked: Settings.values.parts[modelData]
                            onToggled: v => Settings.set("parts." + modelData, v)
                        }
                    }
                }
            }

            Card {
                title: "From config.json"
                note: "These live in " + Config.path + ", which Sylvaris never writes. Edit that file or your Nix config; changes apply as soon as it is saved."

                Repeater {
                    model: ["avatar", "terminal", "lockCommand", "themeHook", "themesDir"]

                    delegate: SettingRow {
                        required property string modelData
                        required property int index
                        title: modelData
                        last: index === 4

                        Text {
                            width: Math.min(implicitWidth, 380)
                            text: Config.values[modelData] === "" ? "not set" : Config.values[modelData]
                            elide: Text.ElideMiddle
                            color: Theme.textSoft
                            font.family: Tokens.fontMono
                            font.pixelSize: Tokens.smallSize
                        }
                    }
                }
            }
        }
    }

    Component {
        id: appearancePage

        Column {
            spacing: 24

            Card {
                title: "Theme"

                SettingRow {
                    title: Theme.theme.name || "Built-in"
                    subtitle: Theme.theme.description || "The active theme"

                    Chip {
                        text: "Open the theme picker"
                        glyph: Icons.GLYPHS.theme
                        onClicked: root.hand("theme", "")
                    }
                }

                SettingRow {
                    title: "Apply directly"
                    last: true

                    Flow {
                        width: 420
                        spacing: 6
                        layoutDirection: Qt.RightToLeft

                        Repeater {
                            model: Theme.ids

                            delegate: Chip {
                                required property string modelData
                                text: Theme.catalog[modelData] !== undefined ? Theme.catalog[modelData].name : modelData
                                lit: modelData === Theme.currentId
                                onClicked: Theme.apply(modelData)
                            }
                        }
                    }
                }
            }

            Card {
                title: "Resin Glass"
                note: "Every panel, tile and card is drawn in translucent glass. Blur comes from your compositor."

                SettingRow {
                    title: "Glass"
                    subtitle: "Off brings back solid panels"

                    Toggle {
                        checked: Resin.enabled
                        onToggled: v => Settings.set("glass.enabled", v)
                    }
                }

                Repeater {
                    model: root.glassKeys

                    delegate: SettingRow {
                        required property var modelData
                        required property int index
                        title: modelData.label
                        last: index === root.glassKeys.length - 1
                        opacity: Resin.enabled ? 1 : 0.45

                        Slider {
                            width: 300
                            value: root.glass(modelData.key) / modelData.max
                            label: root.glass(modelData.key).toFixed(modelData.max < 1 ? 3 : 2)
                            onMoved: v => Settings.set("glass." + modelData.key, Math.round(v * modelData.max * 1000) / 1000)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: barPage

        Column {
            spacing: 24

            Card {
                title: "SylBar"

                SettingRow {
                    title: "Show the bar"

                    Toggle {
                        checked: Settings.values.bar.enabled
                        onToggled: v => Settings.set("bar.enabled", v)
                    }
                }

                SettingRow {
                    title: "Edge"
                    subtitle: "Where the bar sits; left and right make it vertical"

                    Segmented {
                        width: 320
                        current: Settings.values.bar.position
                        options: B.POSITIONS.map(p => ({
                                    key: p,
                                    label: p.charAt(0).toUpperCase() + p.slice(1)
                                }))
                        onPicked: key => Settings.set("bar.position", key)
                    }
                }

                SettingRow {
                    title: "Style"
                    subtitle: "Separate glass islands for each side, or one continuous slab"

                    Segmented {
                        width: 240
                        current: Settings.values.bar.style
                        options: [
                            {
                                key: "islands",
                                label: "Islands"
                            },
                            {
                                key: "slab",
                                label: "Slab"
                            }
                        ]
                        onPicked: key => Settings.set("bar.style", key)
                    }
                }

                SettingRow {
                    title: "Floating"
                    subtitle: "A gap around the bar, or one that touches the edge"
                    last: true

                    Toggle {
                        checked: Settings.values.bar.floating
                        onToggled: v => Settings.set("bar.floating", v)
                    }
                }
            }

            Card {
                title: "Modules"
                note: "Click a module to move it along or remove it; add the ones you are missing to any side. Tray apps live in a drawer behind the arrow." + (root.hasBattery ? "" : " This computer has no battery, so the battery module stays hidden and the rest fill its place.")

                Repeater {
                    model: ["left", "center", "right"]

                    delegate: Item {
                        id: side
                        required property string modelData
                        property int picked: -1
                        readonly property var list: Settings.values.bar[modelData]
                        width: parent.width
                        height: sideFlow.implicitHeight + 50

                        Text {
                            y: 14
                            text: side.modelData.charAt(0).toUpperCase() + side.modelData.slice(1)
                            color: Theme.textDim
                            font.family: Tokens.fontUi
                            font.pixelSize: Tokens.smallSize
                            font.weight: Font.DemiBold
                        }

                        Flow {
                            id: sideFlow
                            y: 38
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: side.list

                                delegate: Row {
                                    required property string modelData
                                    required property int index
                                    spacing: 4

                                    Chip {
                                        text: modelData
                                        opacity: modelData === "battery" && !root.hasBattery ? 0.35 : 1
                                        lit: side.picked === index
                                        onClicked: side.picked = side.picked === index ? -1 : index
                                    }

                                    Repeater {
                                        model: side.picked === index ? [
                                            {
                                                glyph: Icons.GLYPHS.chevronLeft,
                                                act: -1
                                            },
                                            {
                                                glyph: Icons.GLYPHS.chevronRight,
                                                act: 1
                                            },
                                            {
                                                glyph: Icons.GLYPHS.close,
                                                act: 0
                                            }
                                        ] : []

                                        delegate: Chip {
                                            required property var modelData
                                            glyph: modelData.glyph
                                            onClicked: {
                                                const list = side.list;
                                                const i = side.picked;
                                                if (modelData.act === 0) {
                                                    Settings.set("bar." + side.modelData, list.filter((m, k) => k !== i));
                                                    side.picked = -1;
                                                } else {
                                                    Settings.set("bar." + side.modelData, B.shift(list, i, modelData.act));
                                                    side.picked = Math.max(0, Math.min(list.length - 1, i + modelData.act));
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: B.unused(Settings.values.bar)

                                delegate: Chip {
                                    required property string modelData
                                    readonly property bool dead: modelData === "battery" && !root.hasBattery
                                    text: modelData
                                    glyph: Icons.GLYPHS.plus
                                    opacity: dead ? 0.25 : 0.6
                                    enabled: !dead
                                    onClicked: Settings.set("bar." + side.modelData, side.list.concat([modelData]))
                                }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            visible: side.modelData !== "right"
                            width: parent.width
                            height: 1
                            color: Qt.alpha(Theme.text, 0.08)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: deckPage

        Column {
            spacing: 24

            Card {
                title: "SylDeck"

                SettingRow {
                    title: "Show the deck"
                    subtitle: "A dock for pinned and running apps along the bottom"

                    Toggle {
                        checked: Settings.values.deck.enabled
                        onToggled: v => Settings.set("deck.enabled", v)
                    }
                }

                SettingRow {
                    title: "Hover effect"
                    subtitle: "Bloom lifts one icon with a glow, magnify grows its neighbours too"

                    Segmented {
                        width: 300
                        current: Settings.values.deck.effect
                        options: [
                            {
                                key: "bloom",
                                label: "Bloom"
                            },
                            {
                                key: "magnify",
                                label: "Magnify"
                            },
                            {
                                key: "none",
                                label: "None"
                            }
                        ]
                        onPicked: key => Settings.set("deck.effect", key)
                    }
                }

                SettingRow {
                    title: "Reserve space"
                    subtitle: "Off lets windows go underneath the deck"

                    Toggle {
                        checked: Settings.values.deck.reserve
                        onToggled: v => Settings.set("deck.reserve", v)
                    }
                }

                SettingRow {
                    title: "Hide automatically"
                    subtitle: "Slides away until the pointer reaches the bottom edge"

                    Toggle {
                        checked: Settings.values.deck.autohide
                        onToggled: v => Settings.set("deck.autohide", v)
                    }
                }

                SettingRow {
                    title: "Icon size"

                    Stepper {
                        value: Settings.values.deck.size
                        from: 36
                        to: 96
                        onStepped: v => Settings.set("deck.size", v)
                    }
                }

                SettingRow {
                    title: "Power button"

                    Segmented {
                        width: 280
                        current: Settings.values.deck.power
                        options: [
                            {
                                key: "start",
                                label: "Start"
                            },
                            {
                                key: "end",
                                label: "End"
                            },
                            {
                                key: "none",
                                label: "None"
                            }
                        ]
                        onPicked: key => Settings.set("deck.power", key)
                    }
                }

                SettingRow {
                    title: "App launcher button"
                    last: true

                    Segmented {
                        width: 280
                        current: Settings.values.deck.pad
                        options: [
                            {
                                key: "start",
                                label: "Start"
                            },
                            {
                                key: "end",
                                label: "End"
                            },
                            {
                                key: "none",
                                label: "None"
                            }
                        ]
                        onPicked: key => Settings.set("deck.pad", key)
                    }
                }
            }

            Card {
                title: "Pinned apps"
                note: Settings.values.deck.pinned.length === 0 ? "Nothing pinned yet. Right-click an app in SylPad or in the deck to keep it here." : ""

                Repeater {
                    model: Settings.values.deck.pinned

                    delegate: SettingRow {
                        required property string modelData
                        required property int index
                        readonly property var entry: Demo.enabled ? Apps.byId(modelData) : DesktopEntries.byId(modelData)
                        title: entry ? entry.name : modelData
                        subtitle: modelData
                        last: index === Settings.values.deck.pinned.length - 1

                        Row {
                            spacing: 6

                            Repeater {
                                model: [
                                    {
                                        glyph: Icons.GLYPHS.up,
                                        act: -1
                                    },
                                    {
                                        glyph: Icons.GLYPHS.down,
                                        act: 1
                                    },
                                    {
                                        glyph: Icons.GLYPHS.close,
                                        act: 0
                                    }
                                ]

                                delegate: Chip {
                                    required property var modelData
                                    glyph: modelData.glyph
                                    onClicked: {
                                        const list = Settings.values.deck.pinned;
                                        Settings.set("deck.pinned", modelData.act === 0 ? list.filter((p, k) => k !== index) : B.shift(list, index, modelData.act));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: launcherPage

        Column {
            spacing: 24

            Card {
                title: "SylPad"
                note: "Open it with the apps button on the bar or deck, or bind `sylvaris pad` to a key."

                SettingRow {
                    title: "Layout"
                    subtitle: "A full-screen grid, or a compact list in the middle of the screen"

                    Segmented {
                        width: 260
                        current: Settings.values.pad.mode
                        options: [
                            {
                                key: "launchpad",
                                label: "Launchpad"
                            },
                            {
                                key: "list",
                                label: "List"
                            }
                        ]
                        onPicked: key => Settings.set("pad.mode", key)
                    }
                }

                SettingRow {
                    title: "Columns"

                    Stepper {
                        value: Settings.values.pad.columns
                        from: 3
                        to: 10
                        onStepped: v => Settings.set("pad.columns", v)
                    }
                }

                SettingRow {
                    title: "Rows"
                    last: true

                    Stepper {
                        value: Settings.values.pad.rows
                        from: 2
                        to: 8
                        onStepped: v => Settings.set("pad.rows", v)
                    }
                }
            }
        }
    }

    Component {
        id: notificationsPage

        Column {
            spacing: 24

            Card {
                title: "SylNotify"

                SettingRow {
                    title: "Do not disturb"
                    subtitle: "Only urgent notifications pop up; everything still lands in the notification center"

                    Toggle {
                        checked: Dnd.enabled
                        onToggled: v => Dnd.setEnabled(v)
                    }
                }

                SettingRow {
                    title: "Toast duration"
                    subtitle: "Unless the app asks for something else"
                    last: true

                    Slider {
                        width: 300
                        value: (Settings.values.notifications.timeout - 1000) / 59000
                        label: (Settings.values.notifications.timeout / 1000).toFixed(0) + " s"
                        onMoved: v => Settings.set("notifications.timeout", Math.round(1000 + v * 59) * 1000)
                    }
                }
            }

            Card {
                title: "Daemon"
                note: Notifications.enabled ? "Sylvaris is your notification daemon. Stop swaync, mako or dunst so it can receive notifications." : "notifications.server is false in config.json, so another daemon handles notifications."
            }
        }
    }

    Component {
        id: soundPage

        Column {
            spacing: 24

            Card {
                title: "Output"

                Repeater {
                    model: Audio.sinks

                    delegate: SettingRow {
                        required property var modelData
                        required property int index
                        title: modelData.name
                        last: index === Audio.sinks.length - 1

                        Chip {
                            text: modelData.current ? "In use" : "Use"
                            lit: modelData.current
                            onClicked: Audio.setDefault(modelData.key)
                        }
                    }
                }
            }

            Card {
                title: "Equalizer"

                SettingRow {
                    title: "Equalizer"
                    subtitle: "Preset: " + E.PRESET_NAMES[Equalizer.cfg.preset]

                    Row {
                        spacing: 10

                        Chip {
                            text: "Adjust"
                            glyph: Icons.GLYPHS.equalizer
                            onClicked: root.hand("media", "sound")
                        }

                        Toggle {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: Equalizer.cfg.enabled
                            onToggled: v => Equalizer.set({
                                    enabled: v
                                })
                        }
                    }
                }

                SettingRow {
                    title: "Spatial audio"
                    subtitle: "Headphone crossfeed"
                    last: true

                    Toggle {
                        checked: Equalizer.cfg.spatial
                        onToggled: v => Equalizer.set({
                                spatial: v
                            })
                    }
                }
            }
        }
    }

    Component {
        id: displaysPage

        Column {
            spacing: 24

            Card {
                title: "Night light"

                SettingRow {
                    title: "Night light"
                    subtitle: NightLight.available ? "Warmer colours through wlsunset" : "Install wlsunset to use night light"

                    Toggle {
                        checked: NightLight.enabled
                        onToggled: v => NightLight.setEnabled(v)
                    }
                }

                SettingRow {
                    title: "Colour temperature"
                    last: true

                    Slider {
                        width: 300
                        value: (NightLight.temperature - 2500) / 4000
                        label: NightLight.temperature + " K"
                        onMoved: v => Settings.set("nightLight.temperature", Math.round((2500 + v * 4000) / 100) * 100)
                    }
                }
            }

            Card {
                title: "Screens"

                SettingRow {
                    title: "Arrange displays"
                    subtitle: "Resolution, refresh rate, scale and position, with automatic revert"
                    last: true

                    Chip {
                        text: "Open"
                        glyph: Icons.GLYPHS.displays
                        onClicked: root.hand("center", "displays")
                    }
                }
            }
        }
    }

    Component {
        id: clockPage

        Column {
            spacing: 24

            Card {
                title: "Location"
                note: "SylClock uses your location for the sun and moon. Set `location = { latitude = …; longitude = …; }` in config.json or your Nix config to override the time zone guess."

                SettingRow {
                    title: "Source"

                    Text {
                        text: Sky.source === "config" ? "config.json" : Sky.source === "timezone" ? "Time zone (" + Sky.zone + ")" : "Unknown"
                        color: Theme.textSoft
                        font.family: Tokens.fontUi
                        font.pixelSize: Tokens.bodySize
                    }
                }

                SettingRow {
                    title: "Coordinates"
                    last: true

                    Text {
                        text: Sky.available ? Sky.latitude.toFixed(2) + ", " + Sky.longitude.toFixed(2) : "—"
                        color: Theme.textSoft
                        font.family: Tokens.fontMono
                        font.pixelSize: Tokens.bodySize
                    }
                }
            }
        }
    }

    Component {
        id: weatherPage

        Column {
            spacing: 24

            Card {
                title: "Weather"
                note: Weather.error !== "" ? Weather.error : Weather.available ? "Now " + Weather.data.temp + Weather.data.unit + ", " + Weather.now.label.toLowerCase() + ". Forecasts come from Open-Meteo for the location below." : "Forecasts come from Open-Meteo for the location below."

                SettingRow {
                    title: "Show the weather"
                    subtitle: "In SylClock, refreshed in the background"

                    Toggle {
                        checked: Settings.values.weather.enabled
                        onToggled: v => Settings.set("weather.enabled", v)
                    }
                }

                SettingRow {
                    title: "Units"

                    Segmented {
                        width: 240
                        current: Settings.values.weather.units
                        options: [
                            {
                                key: "metric",
                                label: "°C · km/h"
                            },
                            {
                                key: "imperial",
                                label: "°F · mph"
                            }
                        ]
                        onPicked: key => Settings.set("weather.units", key)
                    }
                }

                SettingRow {
                    title: "Refresh every"
                    last: true

                    Stepper {
                        value: Settings.values.weather.refresh
                        from: 10
                        to: 360
                        step: 10
                        suffix: " min"
                        onStepped: v => Settings.set("weather.refresh", v)
                    }
                }
            }
        }
    }

    Component {
        id: motionPage

        Column {
            spacing: 24

            Card {
                title: "Motion"
                note: "Every panel opens, moves and closes with the same motion. Speed stretches or shortens all of it at once."

                SettingRow {
                    title: "Animation speed"
                    subtitle: Settings.values.motion.scale === 1 ? "Default" : Settings.values.motion.scale < 1 ? "Faster" : "Slower"

                    Slider {
                        width: 300
                        value: (Settings.values.motion.scale - 0.25) / 1.75
                        label: "×" + (1 / Settings.values.motion.scale).toFixed(2)
                        onMoved: v => Settings.set("motion.scale", Math.round((0.25 + v * 1.75) * 20) / 20)
                    }
                }

                SettingRow {
                    title: "Reduce motion"
                    subtitle: "Panels appear and disappear without moving"
                    last: true

                    Toggle {
                        checked: Settings.values.motion.reduced
                        onToggled: v => Settings.set("motion.reduced", v)
                    }
                }
            }

            Card {
                title: "Performance"
                note: "Also turns on with the Performance toggle in SylCenter."

                SettingRow {
                    title: "Performance mode"
                    subtitle: "Drops blurred backdrops, grain, sheen and ambient movement, and shortens every animation"
                    last: true

                    Toggle {
                        checked: Settings.values.performance
                        onToggled: v => Settings.set("performance", v)
                    }
                }
            }
        }
    }

    Component {
        id: wallpaperPage

        Column {
            spacing: 24

            Card {
                title: "SylPaper"
                note: "The wallpaper follows the theme. Pick another image for a theme or for one screen in the picker."

                SettingRow {
                    title: "Draw the wallpaper"
                    subtitle: "Turn off if another program such as hyprpaper draws it"

                    Toggle {
                        checked: Settings.values.paper.enabled
                        onToggled: v => Settings.set("paper.enabled", v)
                    }
                }

                SettingRow {
                    title: "Pick an image"
                    subtitle: Settings.values.paper.folder

                    Chip {
                        text: "Open picker"
                        glyph: Icons.GLYPHS.image
                        onClicked: root.hand("paper", "")
                    }
                }

                SettingRow {
                    title: "Transition"

                    Segmented {
                        width: 320
                        current: Settings.values.paper.transition
                        options: ["zoom", "fade", "slide", "none"].map(k => ({
                                    key: k,
                                    label: k.charAt(0).toUpperCase() + k.slice(1)
                                }))
                        onPicked: key => Settings.set("paper.transition", key)
                    }
                }

                SettingRow {
                    title: "Transition length"
                    last: true

                    Slider {
                        width: 300
                        value: Settings.values.paper.duration / 3000
                        label: (Settings.values.paper.duration / 1000).toFixed(1) + " s"
                        onMoved: v => Settings.set("paper.duration", Math.round(v * 30) * 100)
                    }
                }
            }
        }
    }

    Component {
        id: powerPage

        Column {
            spacing: 24

            Card {
                title: "SylPower"
                note: "Put the power button on the bar (the power module), on the deck, or both. Commands can be replaced under power.commands in config.json."

                SettingRow {
                    title: "Actions"
                    subtitle: "Shown in this order"

                    Flow {
                        width: 420
                        spacing: 6
                        layoutDirection: Qt.RightToLeft

                        Repeater {
                            model: Object.keys(Pw.ACTIONS).reverse()

                            delegate: Chip {
                                required property string modelData
                                readonly property bool on: Settings.values.power.actions.indexOf(modelData) >= 0
                                text: Pw.ACTIONS[modelData].label
                                glyph: Icons.GLYPHS[Pw.ACTIONS[modelData].glyph]
                                lit: on
                                onClicked: {
                                    const list = Settings.values.power.actions;
                                    const order = Object.keys(Pw.ACTIONS);
                                    const next = on ? list.filter(a => a !== modelData) : list.concat([modelData]).sort((x, y) => order.indexOf(x) - order.indexOf(y));
                                    if (next.length > 0)
                                        Settings.set("power.actions", next);
                                }
                            }
                        }
                    }
                }

                SettingRow {
                    title: "Ask before closing everything"
                    subtitle: "Log out, restart, shut down and hibernate wait for a countdown"

                    Toggle {
                        checked: Settings.values.power.confirm
                        onToggled: v => Settings.set("power.confirm", v)
                    }
                }

                SettingRow {
                    title: "Countdown"
                    last: true

                    Stepper {
                        value: Settings.values.power.countdown
                        from: 1
                        to: 10
                        suffix: " s"
                        onStepped: v => Settings.set("power.countdown", v)
                    }
                }
            }
        }
    }

    Component {
        id: diverPage

        Column {
            id: diverColumn
            property string message: ""
            spacing: 24

            Connections {
                target: Diver
                function onPairFinished(ok, message) {
                    diverColumn.message = message;
                }
            }

            Card {
                title: "SylDiver"
                note: Diver.paired ? "Connected. Plans show up in SylClock and SylCenter, reminders pop up as notifications and alarms ring here." + (Diver.error !== "" ? " Last problem: " + Diver.error : "") : "Open diver → settings → connected devices → connect sylvaris, then paste the whole line here. Your password never leaves the browser; Sylvaris only gets a key for your list and a token you can revoke."

                SettingRow {
                    visible: !Diver.paired
                    title: "Pairing code"
                    subtitle: diverColumn.message

                    Row {
                        spacing: 8

                        TextBox {
                            id: codeBox
                            width: 300
                            placeholder: "sylvaris diver pair …"
                            onAccepted: Diver.pair(codeBox.text)
                        }

                        Chip {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Pair"
                            glyph: Icons.GLYPHS.link
                            onClicked: {
                                if (codeBox.text.trim() !== "")
                                    Diver.pair(codeBox.text);
                            }
                        }
                    }
                }

                SettingRow {
                    visible: Diver.paired
                    title: "Synced " + (Diver.lastSync > 0 ? Qt.formatTime(new Date(Diver.lastSync), "HH:mm:ss") : "not yet")
                    subtitle: Diver.agendaToday.length + " planned today" + (Diver.next !== null ? " · next: " + Diver.plain(Diver.next.task.text) + " at " + Qt.formatTime(new Date(Diver.next.start), "HH:mm") : "")

                    Row {
                        spacing: 8

                        Chip {
                            text: "Sync now"
                            glyph: Icons.GLYPHS.restart
                            onClicked: Diver.sync()
                        }

                        Chip {
                            text: "Disconnect"
                            glyph: Icons.GLYPHS.disconnect
                            onClicked: Diver.unpair()
                        }
                    }
                }

                SettingRow {
                    title: "Check for changes every"
                    last: true

                    Stepper {
                        value: Settings.values.diver.refresh
                        from: 1
                        to: 60
                        suffix: " min"
                        onStepped: v => Settings.set("diver.refresh", v)
                    }
                }
            }

            Card {
                title: "Reminders"

                Repeater {
                    model: [
                        {
                            key: "calendar",
                            title: "Show plans in the calendars",
                            sub: "Dots on busy days, and the day's list when you click one"
                        },
                        {
                            key: "notify",
                            title: "Notifications",
                            sub: "A toast when a reminder is due"
                        },
                        {
                            key: "alarms",
                            title: "Alarms",
                            sub: "Tasks marked as alarms take over the screen until you snooze or finish them"
                        },
                        {
                            key: "sound",
                            title: "Alarm sound",
                            sub: "Rings for up to two minutes"
                        }
                    ]

                    delegate: SettingRow {
                        required property var modelData
                        required property int index
                        title: modelData.title
                        subtitle: modelData.sub
                        last: index === 3

                        Toggle {
                            checked: Settings.values.diver[modelData.key]
                            onToggled: v => Settings.set("diver." + modelData.key, v)
                        }
                    }
                }
            }

            Card {
                title: "Try it"

                SettingRow {
                    title: "Ring a test alarm"
                    subtitle: "Esc dismisses, Enter marks done, Space snoozes"
                    last: true

                    Chip {
                        text: "Test"
                        glyph: Icons.GLYPHS.alarm
                        onClicked: {
                            root.close();
                            Diver.alarm = {
                                rid: "test",
                                id: "",
                                at: Date.now(),
                                start: Date.now(),
                                before: 0,
                                alarm: true,
                                title: "This is how a Diver alarm looks",
                                path: "test"
                            };
                        }
                    }
                }
            }
        }
    }

    Component {
        id: commandsPage

        Column {
            spacing: 24

            Card {
                title: "Keybinds for " + (Compositor.name === "hyprland" ? (Compositor.usingLua ? "Hyprland (Lua)" : "Hyprland") : Compositor.name)
                note: "Every part of Sylvaris is a `sylvaris` command. Copy a line into your compositor config; the keys are only suggestions."

                Repeater {
                    model: root.binds

                    delegate: SettingRow {
                        id: bindRow
                        required property var modelData
                        required property int index
                        readonly property string line: W.bindSnippet(Compositor.name, Compositor.usingLua, modelData.key, modelData.command)
                        title: modelData.label
                        subtitle: line
                        last: index === root.binds.length - 1

                        Chip {
                            text: "Copy"
                            glyph: Icons.GLYPHS.copy
                            onClicked: Quickshell.clipboardText = bindRow.line
                        }
                    }
                }
            }

            Card {
                title: "Everything else"
                note: "`sylvaris list` prints every part and action, `sylvaris get` and `sylvaris set` read and change any setting on this screen, and `sylvaris watch` streams state changes for scripts."
            }
        }
    }
}
