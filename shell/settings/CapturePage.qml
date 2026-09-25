import QtQuick
import qs
import qs.services
import qs.components
import "../lib/icons.mjs" as Icons

Column {
    id: root

    readonly property var cfg: Settings.values.capture

    spacing: 24

    Card {
        title: "Screenshots"
        note: "Open the capture panel with “sylvaris capture toggle”, or bind keys straight to “sylvaris capture shot area”, “… shot window”, “… shot screen”."

        Item {
            width: parent.width
            height: 110

            Glass {
                anchors.fill: parent
                radius: Tokens.radiusCard
                inner: true
            }

            Row {
                anchors.centerIn: parent
                spacing: 12

                Repeater {
                    model: [
                        {
                            glyph: Icons.GLYPHS.region,
                            label: "Area"
                        },
                        {
                            glyph: Icons.GLYPHS.windowPick,
                            label: "Window"
                        },
                        {
                            glyph: Icons.GLYPHS.displays,
                            label: "Screen"
                        }
                    ]

                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: 86
                        height: 78

                        Glass {
                            anchors.fill: parent
                            radius: Tokens.radiusRow
                            inner: true
                            lit: index === 0
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Glyph {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.glyph
                                size: 22
                                color: index === 0 ? Theme.onAccent : Theme.accent
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label + (index === 0 && root.cfg.delay > 0 ? " · " + root.cfg.delay + " s" : "")
                                color: index === 0 ? Theme.onAccent : Theme.text
                                font.family: Tokens.fontUi
                                font.pixelSize: Tokens.tinySize
                            }
                        }
                    }
                }
            }
        }

        SettingRow {
            title: "Copy to the clipboard"

            Toggle {
                checked: root.cfg.copy
                onToggled: v => Settings.set("capture.copy", v)
            }
        }

        SettingRow {
            title: "Save to a file"
            subtitle: root.cfg.folder

            Toggle {
                checked: root.cfg.save
                onToggled: v => Settings.set("capture.save", v)
            }
        }

        SettingRow {
            title: "Delay"
            last: true

            Segmented {
                width: 260
                options: [0, 3, 5, 10].map(d => ({
                            key: String(d),
                            label: d === 0 ? "None" : d + " s"
                        }))
                current: String(root.cfg.delay)
                onPicked: key => Settings.set("capture.delay", Number(key))
            }
        }
    }

    Card {
        title: "Screen recording"
        note: "Start with “sylvaris capture record area” or “… record screen” and stop with “sylvaris capture stop” or the red button that shows while recording. Videos go to " + root.cfg.videos + "."

        SettingRow {
            title: "Record desktop sound"
            subtitle: "What you hear through your speakers or headphones"
            last: true

            Toggle {
                checked: root.cfg.audio
                onToggled: v => Settings.set("capture.audio", v)
            }
        }
    }
}
