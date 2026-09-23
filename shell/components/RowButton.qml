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
    color: hover.hovered ? Theme.tintMid : Theme.tintSoft

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }

    Row {
        id: row
        x: 16
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
