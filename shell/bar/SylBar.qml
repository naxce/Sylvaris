import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import qs
import qs.services
import qs.components
import "../lib/icons.mjs" as Icons
import "../lib/bar.mjs" as B

Scope {
    id: root

    readonly property var cfg: Settings.values.bar
    readonly property string position: root.cfg.position
    readonly property bool vertical: B.vertical(root.position)
    readonly property bool islands: root.cfg.style === "islands"
    readonly property bool hasBattery: UPower.displayDevice !== null && UPower.displayDevice.isLaptopBattery
    property var open: ({})
    property date now: new Date()

    signal request(string part, string arg, var screen)

    function moduleFor(name: string): var {
        return ({
                pad: padModule,
                workspaces: workspacesModule,
                window: windowModule,
                clock: clockModule,
                media: mediaModule,
                tray: trayModule,
                audio: audioModule,
                network: networkModule,
                bluetooth: bluetoothModule,
                battery: batteryModule,
                notifications: notificationsModule,
                center: centerModule,
                power: powerModule
            })[name] || null;
    }

    function isOpen(part: string, screen: var): bool {
        const s = root.open[part];
        return s !== undefined && s !== null && screen !== null && s === screen.name;
    }

    Timer {
        interval: 1000
        running: root.cfg.enabled
        repeat: true
        onTriggered: root.now = new Date()
    }

    Variants {
        model: root.cfg.enabled ? Quickshell.screens : []

        delegate: PanelWindow {
            id: bar

            required property var modelData
            readonly property bool floating: root.cfg.floating
            readonly property int gap: bar.floating ? Tokens.barMargin : 0
            readonly property var groups: [startGroup, middleGroup, endGroup]

            screen: modelData
            anchors {
                top: root.position !== "bottom"
                bottom: root.position !== "top"
                left: root.position !== "right"
                right: root.position !== "left"
            }
            margins {
                top: root.position === "bottom" ? 0 : bar.gap
                bottom: root.position === "top" ? 0 : bar.gap
                left: root.position === "right" ? 0 : bar.gap
                right: root.position === "left" ? 0 : bar.gap
            }
            implicitHeight: Tokens.barHeight
            implicitWidth: Tokens.barHeight
            color: "transparent"
            exclusionMode: ExclusionMode.Auto
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "sylbar"
            BackgroundEffect.blurRegion: Resin.enabled ? blur : null

            Region {
                id: blur
                regions: root.islands ? bar.groups.filter(g => g.visible).map(g => g.blur) : [slabBlur]
            }

            Region {
                id: slabBlur
                item: slab
                radius: bar.floating ? Tokens.barRadius : 0
            }

            Glass {
                id: slab
                anchors.fill: parent
                visible: !root.islands
                flowing: false
                radius: bar.floating ? Tokens.barRadius : 0
                offColor: Theme.surface
                offBorder: Theme.line
            }

            BarGroup {
                id: startGroup
                list: root.cfg.left
                side: "left"
                islands: root.islands
                vertical: root.vertical
                barWindow: bar
                x: root.vertical ? (parent.width - width) / 2 : root.islands ? 0 : Tokens.barPadding
                y: root.vertical ? (root.islands ? 0 : Tokens.barPadding) : (parent.height - height) / 2
                moduleFor: root.moduleFor
            }

            BarGroup {
                id: middleGroup
                list: root.cfg.center
                side: "center"
                islands: root.islands
                vertical: root.vertical
                barWindow: bar
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                moduleFor: root.moduleFor
            }

            BarGroup {
                id: endGroup
                list: root.cfg.right
                side: "right"
                islands: root.islands
                vertical: root.vertical
                barWindow: bar
                x: root.vertical ? (parent.width - width) / 2 : parent.width - width - (root.islands ? 0 : Tokens.barPadding)
                y: root.vertical ? parent.height - height - (root.islands ? 0 : Tokens.barPadding) : (parent.height - height) / 2
                moduleFor: root.moduleFor
            }
        }
    }

    Component {
        id: padModule

        BarButton {
            property var screenRef: null
            property var win: null
            glyph: Icons.GLYPHS.apps
            lit: root.isOpen("pad", screenRef)
            onClicked: root.request("pad", "", screenRef)
        }
    }

    Component {
        id: workspacesModule

        Item {
            id: ws
            property var screenRef: null
            property var win: null
            readonly property var list: Compositor.workspaces.filter(w => ws.screenRef !== null && w.output === ws.screenRef.name)
            implicitWidth: root.vertical ? Tokens.barItemHeight : pills.implicitWidth + 12
            implicitHeight: root.vertical ? pills.implicitHeight + 12 : Tokens.barItemHeight
            property bool wanted: ws.list.length > 0

            MouseArea {
                anchors.fill: parent
                onWheel: event => {
                    const d = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                    if (d !== 0)
                        Compositor.run("workspace", [d > 0 ? "prev" : "next"]);
                }
            }

            Grid {
                id: pills
                anchors.centerIn: parent
                columns: root.vertical ? 1 : 64
                spacing: 5
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter

                Repeater {
                    model: ws.list

                    delegate: Rectangle {
                        required property var modelData
                        width: root.vertical ? 26 : modelData.focused ? 38 : 26
                        height: root.vertical ? (modelData.focused ? 38 : 26) : 26
                        radius: 13
                        antialiasing: true
                        color: modelData.urgent ? Theme.danger : modelData.focused ? Theme.accent : modelData.active ? Qt.alpha(Theme.accent, 0.35) : modelData.windows !== 0 ? Qt.alpha(Theme.text, 0.14) : "transparent"
                        border.width: modelData.focused || modelData.windows !== 0 || modelData.active ? 0 : 1
                        border.color: Qt.alpha(Theme.text, 0.18)

                        Behavior on width {
                            NumberAnimation {
                                duration: Tokens.moveDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Tokens.springCurve
                            }
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: Tokens.moveDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Tokens.springCurve
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Tokens.stateDuration
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name.length <= 3 ? modelData.name : modelData.index
                            color: modelData.focused || modelData.urgent ? Theme.onAccent : Theme.text
                            opacity: modelData.focused || modelData.windows !== 0 || modelData.active ? 1 : 0.55
                            font.family: Tokens.fontUi
                            font.pixelSize: Tokens.tinySize
                            font.weight: modelData.focused ? Font.Bold : Font.Medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Compositor.focusWorkspace(modelData)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: windowModule

        Item {
            id: wm
            property var screenRef: null
            property var win: null
            readonly property var active: Compositor.activeWindow
            readonly property var entry: wm.active === null ? null : DesktopEntries.heuristicLookup(wm.active.appId)
            implicitWidth: wm.active === null ? 0 : Math.min(titleRow.implicitWidth, Tokens.barTitleMax) + 12
            implicitHeight: Tokens.barItemHeight
            property bool wanted: !root.vertical && wm.active !== null && wm.active.title !== ""

            Row {
                id: titleRow
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 18
                    source: wm.entry !== null && wm.entry.icon ? Quickshell.iconPath(wm.entry.icon, true) : ""
                    visible: source !== ""
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, Tokens.barTitleMax - 26)
                    text: wm.active === null ? "" : wm.active.title
                    elide: Text.ElideRight
                    color: Theme.textSoft
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.barText
                }
            }
        }
    }

    Component {
        id: clockModule

        BarButton {
            property var screenRef: null
            property var win: null
            label: root.vertical ? "" : Qt.formatDate(root.now, "ddd d MMM") + "   " + Qt.formatTime(root.now, "HH:mm")
            implicitHeight: root.vertical ? stack.implicitHeight + 16 : Tokens.barItemHeight

            Column {
                id: stack
                visible: root.vertical
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: [Qt.formatTime(root.now, "HH"), Qt.formatTime(root.now, "mm")]

                    delegate: Text {
                        required property string modelData
                        text: modelData
                        color: Theme.text
                        font.family: Tokens.fontUi
                        font.pixelSize: Tokens.barText + 1
                        font.weight: Font.DemiBold
                    }
                }
            }
            lit: root.isOpen("clock", screenRef)
            onClicked: root.request("clock", "", screenRef)
        }
    }

    Component {
        id: mediaModule

        BarButton {
            property var screenRef: null
            property var win: null
            property bool wanted: Media.available && Media.title !== ""
            compact: root.vertical
            glyph: Media.playing ? Icons.GLYPHS.pause : Icons.GLYPHS.play
            tint: Theme.accent

            Text {
                visible: !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, Tokens.barMediaMax)
                text: Media.title + (Media.artist !== "" ? "  ·  " + Media.artist : "")
                elide: Text.ElideRight
                color: Theme.text
                font.family: Tokens.fontUi
                font.pixelSize: Tokens.barText
            }

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.request("media", "", screenRef);
                else if (mouse.button === Qt.MiddleButton)
                    Media.next();
                else
                    Media.toggle();
            }
            onWheel: steps => steps > 0 ? Media.previous() : Media.next()
        }
    }

    Component {
        id: trayModule

        BarButton {
            id: trayButton
            property var screenRef: null
            property var win: null
            readonly property int count: SystemTray.items.values.length
            property bool wanted: trayButton.count > 0
            glyph: Icons.GLYPHS[{
                    down: "chevronDown",
                    up: "chevronUp",
                    left: "chevronLeft",
                    right: "chevronRight"
                }[B.drawerArrow(root.position)]]
            lit: drawer.visible
            onClicked: drawer.visible = !drawer.visible

            PopupWindow {
                id: drawer

                property real phase: 0
                readonly property int columns: Math.min(5, Math.max(1, trayButton.count))

                anchor.item: trayButton
                anchor.rect.x: root.position === "left" ? trayButton.width + 12 : root.position === "right" ? -12 : 0
                anchor.rect.y: root.position === "top" ? trayButton.height + 12 : root.position === "bottom" ? -12 : 0
                anchor.rect.width: root.vertical ? 1 : trayButton.width
                anchor.rect.height: root.vertical ? trayButton.height : 1
                anchor.edges: root.position === "top" ? Edges.Top : root.position === "bottom" ? Edges.Bottom : root.position === "left" ? Edges.Left : Edges.Right
                anchor.gravity: root.position === "top" ? Edges.Bottom : root.position === "bottom" ? Edges.Top : root.position === "left" ? Edges.Right : Edges.Left
                implicitWidth: trayGrid.implicitWidth + 20
                implicitHeight: trayGrid.implicitHeight + 20
                color: "transparent"
                grabFocus: true
                onVisibleChanged: {
                    if (visible) {
                        drawer.phase = 0;
                        drawerIn.restart();
                    }
                }

                NumberAnimation {
                    id: drawerIn
                    target: drawer
                    property: "phase"
                    to: 1
                    duration: Tokens.enterDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Tokens.enterCurve
                }

                Item {
                    anchors.fill: parent
                    opacity: drawer.phase
                    scale: 0.9 + 0.1 * drawer.phase
                    transformOrigin: root.position === "top" ? Item.Top : root.position === "bottom" ? Item.Bottom : root.position === "left" ? Item.Left : Item.Right

                    Glass {
                        anchors.fill: parent
                        radius: Tokens.radiusCard
                        raised: true
                        offColor: Theme.surface
                        offBorder: Theme.line
                    }

                    Grid {
                        id: trayGrid
                        anchors.centerIn: parent
                        columns: drawer.columns
                        spacing: 4

                        Repeater {
                            model: SystemTray.items

                            delegate: Item {
                                id: trayItem
                                required property var modelData
                                required property int index
                                width: Tokens.barItemHeight + 4
                                height: Tokens.barItemHeight + 4
                                opacity: Math.max(0, Math.min(1, drawer.phase * 3 - trayItem.index * 0.25))

                                Glass {
                                    anchors.fill: parent
                                    radius: Tokens.radiusRow - 2
                                    inner: true
                                    opacity: trayArea.containsMouse ? 1 : 0
                                    offBorder: "transparent"

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Tokens.stateDuration
                                        }
                                    }
                                }

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: 20
                                    source: trayItem.modelData.icon
                                    scale: trayArea.pressed ? 0.85 : trayArea.containsMouse ? 1.1 : 1

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: Tokens.stateDuration
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Tokens.springCurve
                                        }
                                    }
                                }

                                MouseArea {
                                    id: trayArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        const item = trayItem.modelData;
                                        if (mouse.button === Qt.MiddleButton) {
                                            item.secondaryActivate();
                                        } else if (mouse.button === Qt.RightButton || item.onlyMenu) {
                                            if (item.hasMenu) {
                                                const p = trayItem.mapToItem(null, 0, trayItem.height + 4);
                                                item.display(drawer, p.x, p.y);
                                            }
                                        } else {
                                            item.activate();
                                            drawer.visible = false;
                                        }
                                    }
                                    onWheel: event => trayItem.modelData.scroll(event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x, event.angleDelta.y === 0)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: audioModule

        BarButton {
            property var screenRef: null
            property var win: null
            property bool wanted: Audio.available
            compact: root.vertical
            glyph: Audio.muted ? Icons.GLYPHS.volumeMute : Icons.GLYPHS.volume
            label: Math.round(Audio.volume * 100) + "%"
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton)
                    root.request("center", "outputs", screenRef);
                else
                    Audio.toggleMute();
            }
            onWheel: steps => Audio.setVolume(Audio.volume + steps * 0.05)
        }
    }

    Component {
        id: networkModule

        BarButton {
            property var screenRef: null
            property var win: null
            readonly property var connected: NetworkService.items.filter(i => i.connected)[0] || null
            property bool wanted: NetworkService.available || NetworkService.wiredConnected
            glyph: NetworkService.wiredConnected && connected === null ? Icons.GLYPHS.ethernet : !NetworkService.enabled ? Icons.GLYPHS.wifiOff : connected !== null ? connected.icon : Icons.wifiIcon(0)
            onClicked: root.request("center", "orbit-wifi", screenRef)
        }
    }

    Component {
        id: bluetoothModule

        BarButton {
            property var screenRef: null
            property var win: null
            property bool wanted: BluetoothService.available
            glyph: BluetoothService.enabled ? Icons.GLYPHS.bluetooth : Icons.GLYPHS.bluetoothOff
            tint: BluetoothService.enabled ? Theme.text : Theme.textDim
            onClicked: root.request("center", "orbit-bluetooth", screenRef)
        }
    }

    Component {
        id: batteryModule

        BarButton {
            property var screenRef: null
            property var win: null
            readonly property var device: UPower.displayDevice
            readonly property real percent: device === null ? 0 : device.percentage > 1 ? device.percentage : device.percentage * 100
            property bool wanted: device !== null && device.ready && device.isLaptopBattery
            compact: root.vertical
            glyph: Icons.batteryIcon(percent)
            tint: percent < 15 ? Theme.danger : Theme.text
            label: Math.round(percent) + "%"
        }
    }

    Component {
        id: notificationsModule

        BarButton {
            property var screenRef: null
            property var win: null
            glyph: Dnd.enabled ? Icons.GLYPHS.dnd : Icons.GLYPHS.bell
            badge: Notifications.count
            lit: root.isOpen("notify", screenRef)
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton)
                    Dnd.setEnabled(!Dnd.enabled);
                else
                    root.request("notify", "", screenRef);
            }
        }
    }

    Component {
        id: centerModule

        BarButton {
            property var screenRef: null
            property var win: null
            glyph: Icons.GLYPHS.tune
            lit: root.isOpen("center", screenRef)
            onClicked: root.request("center", "", screenRef)
        }
    }

    Component {
        id: powerModule

        BarButton {
            property var screenRef: null
            property var win: null
            glyph: Icons.GLYPHS.power
            lit: root.isOpen("power", screenRef)
            onClicked: root.request("power", "", screenRef)
        }
    }
}
