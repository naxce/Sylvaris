import QtQuick
import QtQuick.Effects
import qs
import qs.services

Item {
    id: root

    property string source: Theme.wallpaper
    property real blur: 1
    property real dim: 0.3
    property color tint: Theme.accentDeep
    property real reveal: 1
    readonly property bool gpu: root.GraphicsInfo.api !== GraphicsInfo.Software && root.GraphicsInfo.api !== GraphicsInfo.Unknown
    readonly property string style: !root.gpu || Tokens.lite || Settings.values.motion.reduced ? "fade" : Settings.values.motion.reveal
    readonly property bool masked: root.style !== "fade" && root.reveal < 1
    readonly property real grow: 1.42 / 0.72 * (root.style === "edges" ? 1 - root.reveal : root.reveal)

    opacity: root.style === "fade" ? Math.min(1, root.reveal * 3) : root.reveal > 0 ? 1 : 0

    Item {
        id: content
        anchors.fill: parent
        layer.enabled: root.masked
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
            maskInverted: root.style === "edges"
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.base
        }

        Item {
            anchors.fill: parent
            visible: root.gpu && wall.status === Image.Ready && !Tokens.lite
            layer.enabled: visible
            layer.smooth: true

            Image {
                id: wall
                anchors.fill: parent
                anchors.margins: -64
                visible: false
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize.width: 1280
                source: !root.gpu || Tokens.lite || root.source === "" ? "" : "file://" + root.source
            }

            MultiEffect {
                anchors.fill: wall
                source: wall
                blurEnabled: root.blur > 0
                blur: root.blur
                blurMax: 48
                saturation: 0.2
                brightness: -root.dim
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.alpha(Theme.base, 0.35)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(Qt.darker(root.tint, 2.4), 0.55)
                }
            }
        }

        Image {
            visible: Resin.enabled && Resin.grain > 0 && !Tokens.lite
            opacity: Resin.grain
            anchors.fill: parent
            source: Qt.resolvedUrl("../assets/grain.png")
            fillMode: Image.Tile
        }

    }

    Item {
        id: mask
        anchors.fill: parent
        visible: false
        layer.enabled: root.masked

        Image {
            anchors.centerIn: parent
            width: Math.max(2, root.width * root.grow)
            height: Math.max(2, root.height * root.grow)
            source: root.masked ? Qt.resolvedUrl("../assets/reveal.png") : ""
            smooth: true
        }
    }
}
