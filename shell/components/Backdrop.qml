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
    readonly property bool gpu: root.GraphicsInfo.api !== GraphicsInfo.Software && root.GraphicsInfo.api !== GraphicsInfo.Unknown

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
