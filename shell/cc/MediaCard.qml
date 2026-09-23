import QtQuick
import qs
import qs.services
import qs.components
import "../lib/icons.mjs" as Icons

Rectangle {
    id: root

    implicitHeight: Tokens.artSize + Tokens.cardPadding * 2
    radius: Tokens.radiusCard
    color: Theme.tint
    border.width: 1
    border.color: Theme.cardLine

    Rectangle {
        id: artBox
        x: Tokens.cardPadding
        anchors.verticalCenter: parent.verticalCenter
        width: Tokens.artSize
        height: Tokens.artSize
        radius: Tokens.radiusRow
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0
                color: Theme.accentDeep
            }
            GradientStop {
                position: 1
                color: Theme.surface
            }
        }

        RoundImage {
            anchors.fill: parent
            radius: Tokens.radiusRow
            source: Media.art
        }
    }

    Column {
        anchors.left: artBox.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: Tokens.cardPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: Media.title === "" ? "Nothing playing" : Media.title
            elide: Text.ElideRight
            color: Theme.text
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.bodySize
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            visible: Media.artist !== ""
            text: Media.artist
            elide: Text.ElideRight
            color: Theme.textDim
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.smallSize
        }

        Row {
            topPadding: 6
            spacing: 18

            Repeater {
                model: [
                    { glyph: Icons.GLYPHS.previous, act: "previous" },
                    { glyph: Media.playing ? Icons.GLYPHS.pause : Icons.GLYPHS.play, act: "toggle" },
                    { glyph: Icons.GLYPHS.next, act: "next" }
                ]
                delegate: Glyph {
                    required property var modelData
                    text: modelData.glyph
                    size: 24
                    color: Theme.textSoft

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.act === "previous")
                                Media.previous();
                            else if (modelData.act === "next")
                                Media.next();
                            else
                                Media.toggle();
                        }
                    }
                }
            }
        }
    }
}
