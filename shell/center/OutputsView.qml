import QtQuick
import qs
import qs.services
import qs.components
import "../lib/icons.mjs" as Icons

Item {
    id: root

    signal closeRequested

    ViewHeader {
        title: "Sound output"
        onBack: root.closeRequested()
    }

    Column {
        x: 28
        y: 84
        width: parent.width - 56
        spacing: 8

        Repeater {
            model: Audio.sinks
            delegate: Rectangle {
                required property var modelData
                width: parent.width
                height: 56
                radius: Tokens.radiusRow
                color: "transparent"

                Glass {
                    anchors.fill: parent
                    z: -1
                    radius: parent.radius
                    inner: true
                    hot: rowHover.hovered
                    offColor: modelData.current ? Theme.tintStrong : rowHover.hovered ? Theme.tintMid : Theme.tintSoft
                }

                border.width: modelData.current ? 1 : 0
                border.color: Theme.accent

                HoverHandler {
                    id: rowHover
                    cursorShape: Qt.PointingHandCursor
                }

                Glyph {
                    id: speaker
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: Icons.GLYPHS.speaker
                    size: 20
                    color: Theme.accent
                }

                Text {
                    anchors.left: speaker.right
                    anchors.leftMargin: 14
                    anchors.right: check.left
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.bodySize
                }

                Glyph {
                    id: check
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    visible: modelData.current
                    text: Icons.GLYPHS.check
                    size: 20
                    color: Theme.accent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Audio.setDefault(modelData.key)
                }
            }
        }
    }

    Slider {
        x: 28
        y: parent.height - height - 28
        width: parent.width - 56
        value: Audio.muted ? 0 : Audio.volume
        icon: Audio.muted ? Icons.GLYPHS.volumeMute : Icons.GLYPHS.volume
        label: Math.round(Audio.volume * 100) + "%"
        onMoved: v => Audio.setVolume(v)
        onIconClicked: Audio.toggleMute()
    }
}
