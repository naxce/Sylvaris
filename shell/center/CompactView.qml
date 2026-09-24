import QtQuick
import Quickshell
import qs
import qs.services
import qs.components
import "../lib/icons.mjs" as Icons
import "../lib/settings.mjs" as S

Item {
    id: root

    signal openView(string name)

    property date now: new Date()
    readonly property var toggles: Toggles.items
    readonly property var tiles: root.buildTiles()

    implicitWidth: Tokens.centerCompactWidth
    implicitHeight: column.implicitHeight + Tokens.panelPaddingY * 2

    function toggleTile(t: var): var {
        return {
            key: "toggle:" + t.id,
            icon: t.icon,
            title: t.label,
            subtitle: t.on ? "On" : "Off",
            active: t.on,
            detail: ""
        };
    }

    function buildTiles(): var {
        const out = [];
        if (NetworkService.available)
            out.push({
                key: "wifi",
                icon: NetworkService.enabled ? Icons.GLYPHS.wifi : Icons.GLYPHS.wifiOff,
                title: "Wi-Fi",
                subtitle: NetworkService.summary,
                active: NetworkService.enabled && NetworkService.hasWifi,
                detail: "orbit-wifi"
            });
        if (BluetoothService.available)
            out.push({
                key: "bluetooth",
                icon: BluetoothService.enabled ? Icons.GLYPHS.bluetooth : Icons.GLYPHS.bluetoothOff,
                title: "Bluetooth",
                subtitle: BluetoothService.summary,
                active: BluetoothService.enabled,
                detail: "orbit-bluetooth"
            });
        if (NightLight.available)
            out.push({
                key: "night",
                icon: Icons.GLYPHS.nightLight,
                title: "Night light",
                subtitle: NightLight.enabled ? NightLight.temperature + "K" : "Off",
                active: NightLight.enabled,
                detail: ""
            });
        if (Dnd.available)
            out.push({
                key: "dnd",
                icon: Icons.GLYPHS.dnd,
                title: "DND",
                subtitle: Dnd.enabled ? "On" : "Off",
                active: Dnd.enabled,
                detail: ""
            });
        if (root.toggles.length > 0)
            out.push(root.toggleTile(root.toggles[0]));
        if (Hotspot.available)
            out.push({
                key: "hotspot",
                icon: Icons.GLYPHS.hotspot,
                title: "Hotspot",
                subtitle: Hotspot.active ? Settings.values.hotspot.ssid : "Off",
                active: Hotspot.active,
                detail: "hotspot"
            });
        for (let i = 1; i < root.toggles.length; i++)
            out.push(root.toggleTile(root.toggles[i]));
        return out;
    }

    function iconAction(key: string): void {
        if (key === "wifi")
            NetworkService.setEnabled(!NetworkService.enabled);
        else if (key === "bluetooth")
            BluetoothService.setEnabled(!BluetoothService.enabled);
        else if (key === "night")
            NightLight.setEnabled(!NightLight.enabled);
        else if (key === "dnd")
            Dnd.setEnabled(!Dnd.enabled);
        else if (key === "hotspot") {
            if (Hotspot.active)
                Hotspot.stop();
            else if (!Hotspot.resume())
                root.openView("hotspot");
        } else if (key.indexOf("toggle:") === 0) {
            const id = key.slice(7);
            for (const t of root.toggles) {
                if (t.id === id)
                    Toggles.set(id, !t.on);
            }
        }
    }

    function bodyAction(tile: var): void {
        if (tile.detail !== "")
            root.openView(tile.detail);
        else
            root.iconAction(tile.key);
    }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Column {
        id: column
        x: Tokens.panelPaddingX
        y: Tokens.panelPaddingY
        width: parent.width - Tokens.panelPaddingX * 2
        spacing: Tokens.gap

        Item {
            width: parent.width
            height: clockColumn.implicitHeight

            Column {
                id: clockColumn

                Text {
                    text: Qt.formatTime(root.now, "HH:mm")
                    color: Theme.text
                    font.family: Tokens.fontMono
                    font.pixelSize: Tokens.clockSize
                    font.weight: Font.DemiBold
                    font.letterSpacing: -1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openView("calendar")
                    }
                }

                Text {
                    text: Qt.formatDate(root.now, "ddd, d MMM")
                    color: Theme.textDim
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.dateSize
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: Tokens.avatarSize
                height: Tokens.avatarSize
                radius: width / 2
                color: Theme.accent

                Text {
                    anchors.centerIn: parent
                    visible: !avatar.ready
                    text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                    color: Theme.onAccent
                    font.family: Tokens.fontUi
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                }

                RoundImage {
                    id: avatar
                    anchors.fill: parent
                    source: "file://" + S.expandHome(Config.values.avatar, Quickshell.env("HOME"))
                }
            }
        }

        Item {
            width: 1
            height: Tokens.headerGap - Tokens.gap
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: Config.notice !== "" ? Config.notice : Settings.notice !== "" ? Settings.notice : Resin.notice !== "" ? Resin.notice : (Theme.errors.length > 0 ? Theme.errors[0] : "")
            wrapMode: Text.WordWrap
            color: Theme.danger
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.smallSize
        }

        Grid {
            width: parent.width
            columns: 2
            spacing: Tokens.gap

            Repeater {
                model: root.tiles
                delegate: Tile {
                    required property var modelData
                    width: (column.width - Tokens.gap) / 2
                    icon: modelData.icon
                    title: modelData.title
                    subtitle: modelData.subtitle
                    active: modelData.active
                    onIconClicked: root.iconAction(modelData.key)
                    onBodyClicked: root.bodyAction(modelData)
                }
            }
        }

        Slider {
            width: parent.width
            visible: Audio.available
            value: Audio.muted ? 0 : Audio.volume
            icon: Audio.muted ? Icons.GLYPHS.volumeMute : Icons.GLYPHS.volume
            label: Math.round(Audio.volume * 100) + "%"
            trailing: Audio.outputName + " ›"
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
            onTrailingClicked: root.openView("outputs")
        }

        MediaCard {
            width: parent.width
            visible: Media.available
            onOpened: root.openView("media")
        }

        Row {
            id: bottomRow

            readonly property real spare: (gear.visible ? gear.width + 10 : 0) + (Displays.available ? 10 : 0)

            width: parent.width
            spacing: 10

            RowButton {
                visible: Displays.available
                width: (bottomRow.width - bottomRow.spare) / 2
                icon: Icons.GLYPHS.displays
                label: "Displays"
                onClicked: root.openView("displays")
            }

            RowButton {
                width: (bottomRow.width - bottomRow.spare) / (Displays.available ? 2 : 1)
                icon: Icons.GLYPHS.theme
                label: "Theme"
                onClicked: root.openView("theme")
            }

            RowButton {
                id: gear
                visible: false
                icon: Icons.GLYPHS.settings
            }
        }
    }
}
