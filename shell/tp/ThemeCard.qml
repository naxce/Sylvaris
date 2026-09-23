import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.components

Item {
    id: root

    required property string modelData
    required property int index
    readonly property var entry: Theme.catalog[root.modelData] === undefined ? null : Theme.catalog[root.modelData]
    readonly property real depth: PathView.depth === undefined ? 1 : PathView.depth
    readonly property real turn: PathView.turn === undefined ? 0 : PathView.turn

    signal picked(int index)

    width: Tokens.tpCardWidth
    height: Tokens.tpCardHeight
    scale: root.depth
    z: root.depth * 100
    opacity: 0.35 + 0.65 * Math.max(0, (root.depth - 0.55) / 0.45)

    transform: Rotation {
        origin.x: root.width / 2
        origin.y: root.height / 2
        axis {
            x: 0
            y: 1
            z: 0
        }
        angle: root.turn
    }

    Glass {
        anchors.fill: parent
        radius: Tokens.tpRadius
        inner: true
    }

    Rectangle {
        id: fallback
        anchors.fill: parent
        anchors.margins: 14
        radius: Tokens.tpRadius - 10
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.entry === null ? Theme.base : root.entry.colors.base
            }
            GradientStop {
                position: 1
                color: root.entry === null ? Theme.accent : root.entry.colors.accent
            }
        }
    }

    ClippingRectangle {
        anchors.fill: fallback
        radius: fallback.radius
        color: "transparent"
        visible: wall.status === Image.Ready

        Image {
            id: wall
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: Tokens.tpCardWidth * 2
            source: root.entry === null || root.entry.wallpaper === "" ? "" : "file://" + root.entry.wallpaper
        }
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 34
        spacing: 10

        Repeater {
            model: root.entry === null ? [] : [root.entry.colors.accent, root.entry.colors.surface, root.entry.colors.text]
            delegate: Rectangle {
                required property string modelData
                width: 34
                height: 34
                radius: 17
                color: modelData
                border.width: 2
                border.color: Qt.alpha("#ffffff", 0.35)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked(root.index)
    }
}
