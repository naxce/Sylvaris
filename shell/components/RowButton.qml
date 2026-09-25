import QtQuick
import qs
import qs.services

Rectangle {
    id: root

    property string icon: ""
    property string label: ""

    signal clicked

    implicitHeight: Tokens.rowHeight
    implicitWidth: row.implicitWidth + 32
    radius: Tokens.radiusRow
    scale: area.pressed ? 0.96 : 1

    Behavior on scale {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }
    color: "transparent"

    Glass {
        anchors.fill: parent
        z: -1
        radius: root.radius
        inner: true
        hot: hover.hovered
        offColor: hover.hovered ? Theme.tintMid : Theme.tintSoft
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        id: area
        anchors.fill: parent
        onClicked: root.clicked()
    }

    Row {
        id: row
        x: root.label === "" ? Math.round((root.width - row.width) / 2) : 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Glyph {
            text: root.icon
            size: 20
            color: Theme.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            color: Theme.text
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.bodySize
        }
    }
}
