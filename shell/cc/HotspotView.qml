import QtQuick
import qs
import qs.services
import qs.components
import "../lib/icons.mjs" as Icons

Item {
    id: root

    signal closeRequested

    property string band: Settings.values.hotspot.band

    function submit(): void {
        if (Hotspot.active)
            Hotspot.stop();
        else if (pass.text === "" && Hotspot.profileExists)
            Hotspot.resume();
        else
            Hotspot.start(ssid.text, pass.text, root.band);
    }

    ViewHeader {
        title: "Hotspot"
        onBack: root.closeRequested()
    }

    Column {
        x: 40
        y: 96
        width: parent.width - 80
        spacing: 12

        Text {
            text: "NETWORK NAME"
            color: Theme.textDim
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.tinySize
            font.letterSpacing: 1
        }

        TextBox {
            id: ssid
            width: parent.width
            text: Settings.values.hotspot.ssid
            placeholder: "Network name"
        }

        Text {
            text: "PASSWORD"
            color: Theme.textDim
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.tinySize
            font.letterSpacing: 1
        }

        TextBox {
            id: pass
            width: parent.width
            password: true
            placeholder: Hotspot.profileExists ? "Saved by NetworkManager" : "At least 8 characters"
            onAccepted: root.submit()
        }

        Text {
            text: "BAND"
            color: Theme.textDim
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.tinySize
            font.letterSpacing: 1
        }

        Segmented {
            width: parent.width
            options: [
                {
                    key: "bg",
                    label: "2.4 GHz"
                },
                {
                    key: "a",
                    label: "5 GHz"
                }
            ]
            current: root.band
            onPicked: key => root.band = key
        }

        Text {
            width: parent.width
            visible: Hotspot.error !== ""
            text: Hotspot.error
            wrapMode: Text.WordWrap
            color: Theme.danger
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.smallSize
        }

        Text {
            text: Hotspot.active ? "Sharing as " + Settings.values.hotspot.ssid : "Hotspot is off"
            color: Theme.textSoft
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.smallSize
        }
    }

    RowButton {
        x: (parent.width - width) / 2
        y: parent.height - height - 28
        icon: Icons.GLYPHS.hotspot
        label: Hotspot.active ? "Stop hotspot" : "Start hotspot"
        onClicked: root.submit()
    }
}
