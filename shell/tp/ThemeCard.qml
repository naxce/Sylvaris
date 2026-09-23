import QtQuick
import qs
import qs.services
import qs.components

Item {
    id: root

    required property string modelData
    required property int index
    property real time: 0
    property point pointer: Qt.point(-1, -1)
    readonly property var entry: Theme.catalog[root.modelData] === undefined ? null : Theme.catalog[root.modelData]
    readonly property real depth: PathView.depth === undefined ? 1 : PathView.depth
    readonly property real turn: PathView.turn === undefined ? 0 : PathView.turn
    readonly property bool front: PathView.isCurrentItem === true
    readonly property bool tracking: root.front && root.pointer.x >= 0
    readonly property real bob: root.front ? 6 * Math.sin(root.time * 1.57) : 0
    property real leanX: root.tracking ? Math.max(-1, Math.min(1, (root.pointer.x - root.x - root.width / 2) / 900)) * 4 : 0
    property real leanY: root.tracking ? Math.max(-1, Math.min(1, (root.pointer.y - root.y - root.height / 2) / 700)) * -3 : 0

    signal picked(int index)

    width: Tokens.tpCardWidth
    height: Tokens.tpCardHeight
    scale: root.depth
    z: root.depth * 100
    opacity: 0.35 + 0.65 * Math.max(0, (root.depth - 0.55) / 0.45)

    Behavior on leanX {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    Behavior on leanY {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    transform: [
        Rotation {
            origin.x: root.width / 2
            origin.y: root.height / 2
            axis {
                x: 0
                y: 1
                z: 0
            }
            angle: root.turn + root.leanX
        },
        Rotation {
            origin.x: root.width / 2
            origin.y: root.height / 2
            axis {
                x: 1
                y: 0
                z: 0
            }
            angle: root.leanY
        },
        Translate {
            y: root.bob
        }
    ]

    Glass {
        anchors.fill: parent
        radius: Tokens.tpRadius
        raised: true
        offColor: Theme.node
        offBorder: Theme.lineStrong
    }

    Rectangle {
        id: fallback
        anchors.fill: parent
        anchors.margins: 14
        radius: Tokens.tpRadius - 10
        antialiasing: true
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

    RoundClip {
        anchors.fill: fallback
        radius: fallback.radius
        visible: wall.status === Image.Ready

        Image {
            id: wall
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            mipmap: true
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
                antialiasing: true
                color: modelData
                border.width: 2
                border.color: Qt.alpha("#ffffff", 0.35)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.picked(root.index)
    }
}
