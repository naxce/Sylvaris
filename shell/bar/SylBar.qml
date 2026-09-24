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

Scope {
    id: root

    readonly property var cfg: Settings.values.bar
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
                center: centerModule
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

            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            margins {
                top: bar.floating ? Tokens.barMargin : 0
                left: bar.floating ? Tokens.barMargin : 0
                right: bar.floating ? Tokens.barMargin : 0
            }
            implicitHeight: Tokens.barHeight
            color: "transparent"
            exclusionMode: ExclusionMode.Auto
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "sylbar"
            BackgroundEffect.blurRegion: Resin.enabled ? blur : null

            Region {
                id: blur
                item: surface
                radius: bar.floating ? Tokens.barRadius : 0
            }

            Item {
                id: surface
                anchors.fill: parent

                Glass {
                    anchors.fill: parent
                    radius: bar.floating ? Tokens.barRadius : 0
                    offColor: Theme.surface
                    offBorder: Theme.line
                }

                Repeater {
                    model: [
                        {
                            list: root.cfg.left,
                            side: "left"
                        },
                        {
                            list: root.cfg.center,
                            side: "center"
                        },
                        {
                            list: root.cfg.right,
                            side: "right"
                        }
                    ]

                    delegate: Row {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        x: modelData.side === "left" ? Tokens.barPadding : modelData.side === "right" ? surface.width - width - Tokens.barPadding : (surface.width - width) / 2
                        spacing: Tokens.barGap

                        Repeater {
                            model: modelData.list

                            delegate: Loader {
                                required property string modelData
                                anchors.verticalCenter: parent.verticalCenter
                                sourceComponent: root.moduleFor(modelData)
                                onLoaded: {
                                    item.screenRef = bar.modelData;
                                    item.win = bar;
                                }
                            }
                        }
                    }
                }
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
            implicitWidth: pills.implicitWidth + 12
            implicitHeight: Tokens.barItemHeight
            visible: ws.list.length > 0

            MouseArea {
                anchors.fill: parent
                onWheel: event => {
                    const d = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                    if (d !== 0)
                        Compositor.run("workspace", [d > 0 ? "prev" : "next"]);
                }
            }

            Row {
                id: pills
                anchors.centerIn: parent
                spacing: 5

                Repeater {
                    model: ws.list

                    delegate: Rectangle {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: modelData.focused ? 38 : 26
                        height: 26
                        radius: 13
                        antialiasing: true
                        color: modelData.urgent ? Theme.danger : modelData.focused ? Theme.accent : modelData.active ? Qt.alpha(Theme.accent, 0.35) : modelData.windows !== 0 ? Qt.alpha(Theme.text, 0.14) : "transparent"
                        border.width: modelData.focused || modelData.windows !== 0 || modelData.active ? 0 : 1
                        border.color: Qt.alpha(Theme.text, 0.18)

                        Behavior on width {
                            NumberAnimation {
                                duration: Tokens.stateDuration + 80
                                easing.type: Easing.OutCubic
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
            visible: wm.active !== null && wm.active.title !== ""

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
            label: Qt.formatDate(root.now, "ddd d MMM") + "   " + Qt.formatTime(root.now, "HH:mm")
            lit: root.isOpen("clock", screenRef)
            onClicked: root.request("clock", "", screenRef)
        }
    }

    Component {
        id: mediaModule

        BarButton {
            property var screenRef: null
            property var win: null
            visible: Media.available && Media.title !== ""
            glyph: Media.playing ? Icons.GLYPHS.pause : Icons.GLYPHS.play
            tint: Theme.accent

            Text {
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

        Row {
            id: tray
            property var screenRef: null
            property var win: null
            spacing: 2
            visible: SystemTray.items.values.length > 0

            Repeater {
                model: SystemTray.items

                delegate: Item {
                    id: trayItem
                    required property var modelData
                    width: Tokens.barItemHeight
                    height: Tokens.barItemHeight

                    Glass {
                        anchors.fill: parent
                        radius: height / 2
                        inner: true
                        opacity: trayArea.containsMouse ? 1 : 0
                        offBorder: "transparent"
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 18
                        source: trayItem.modelData.icon
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
                            } else if (mouse.button === Qt.RightButton) {
                                if (item.hasMenu) {
                                    const p = trayItem.mapToItem(null, 0, trayItem.height + 6);
                                    item.display(tray.win, p.x, p.y);
                                }
                            } else {
                                item.activate();
                            }
                        }
                        onWheel: event => trayItem.modelData.scroll(event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x, event.angleDelta.y === 0)
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
            visible: Audio.available
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
            visible: NetworkService.available || NetworkService.wiredConnected
            glyph: NetworkService.wiredConnected && connected === null ? Icons.GLYPHS.ethernet : !NetworkService.enabled ? Icons.GLYPHS.wifiOff : connected !== null ? connected.icon : Icons.wifiIcon(0)
            onClicked: root.request("center", "orbit-wifi", screenRef)
        }
    }

    Component {
        id: bluetoothModule

        BarButton {
            property var screenRef: null
            property var win: null
            visible: BluetoothService.available
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
            visible: device !== null && device.ready && device.isLaptopBattery
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
}
