import QtQuick
import qs
import qs.services
import qs.components
import "../lib/icons.mjs" as Icons

Column {
    id: root

    readonly property var cons: Settings.values.constellation

    spacing: 18

    Text {
        width: parent.width
        text: "The constellation is how Sylvaris draws connections: these settings, SylCenter's Wi-Fi and Bluetooth orbits, and SylPower."
        wrapMode: Text.Wrap
        color: Theme.textDim
        font.family: Tokens.fontUi
        font.pixelSize: Tokens.smallSize
    }

    Slider {
        width: parent.width
        icon: Icons.GLYPHS.timer
        label: root.cons.speed === 0 ? "Still" : "Drift ×" + root.cons.speed.toFixed(1)
        value: root.cons.speed / 3
        onMoved: v => Settings.set("constellation.speed", Math.round(v * 30) / 10)
    }

    Repeater {
        model: [
            {
                key: "ring",
                label: "Orbit ring",
                about: "The dashed ellipse the stars travel along"
            },
            {
                key: "links",
                label: "Silk links",
                about: "Threads between the core and every star"
            },
            {
                key: "labels",
                label: "Labels",
                about: "Names under the stars, or only on hover"
            },
            {
                key: "stars",
                label: "Starfield",
                about: "Faint twinkling stars behind the settings"
            }
        ]

        delegate: Item {
            required property var modelData
            width: root.width
            height: Math.max(44, texts.implicitHeight)

            Column {
                id: texts
                anchors.left: parent.left
                anchors.right: toggle.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: modelData.label
                    color: Theme.text
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.bodySize
                }

                Text {
                    width: parent.width
                    text: modelData.about
                    wrapMode: Text.Wrap
                    color: Theme.textDim
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.tinySize
                }
            }

            Toggle {
                id: toggle
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: root.cons[modelData.key]
                onToggled: v => Settings.set("constellation." + modelData.key, v)
            }
        }
    }
}
