import QtQuick
import QtQuick.Shapes
import qs
import qs.services
import qs.components
import "../lib/icons.mjs" as Icons

Rectangle {
    id: root

    implicitHeight: Tokens.artSize + Tokens.cardPadding * 2
    radius: Tokens.radiusCard
    color: "transparent"

    Glass {
        anchors.fill: parent
        z: -1
        radius: root.radius
        inner: true
        offBorder: Theme.cardLine
    }

    Rectangle {
        id: artBox
        width: root.height
        height: root.height
        topLeftRadius: root.radius
        bottomLeftRadius: root.radius
        antialiasing: true
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
    }

    Image {
        id: art
        anchors.fill: artBox
        visible: false
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        sourceSize.height: root.height * 2
        source: Media.art
    }

    ShaderEffectSource {
        id: artTexture
        anchors.fill: artBox
        visible: false
        sourceItem: art
        hideSource: true
        mipmap: true
        smooth: true
    }

    Shape {
        anchors.fill: artBox
        visible: art.status === Image.Ready
        layer.enabled: true
        layer.samples: 8
        layer.smooth: true

        ShapePath {
            strokeWidth: -1
            fillItem: artTexture

            PathRectangle {
                x: 0
                y: 0
                width: artBox.width
                height: artBox.height
                topLeftRadius: root.radius
                bottomLeftRadius: root.radius
            }
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
