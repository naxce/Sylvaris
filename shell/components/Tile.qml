import QtQuick
import qs
import qs.services

Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false

    signal iconClicked
    signal bodyClicked

    implicitHeight: Tokens.tileHeight

    Rectangle {
        anchors.fill: parent
        radius: Tokens.radiusTile
        color: hover.hovered ? Theme.tintMid : Theme.tint
        border.width: 1
        border.color: Theme.cardLine

        HoverHandler {
            id: hover
            cursorShape: Qt.PointingHandCursor
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.bodyClicked()
        }

        Rectangle {
            id: iconBox
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.tileIcon
            height: Tokens.tileIcon
            radius: Tokens.tileIconRadius
            color: root.active ? Theme.accent : Theme.tintStrong

            Glyph {
                anchors.centerIn: parent
                text: root.icon
                size: Tokens.tileIconFont
                color: root.active ? Theme.onAccent : Theme.text
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
            }
        }

        Column {
            anchors.left: iconBox.right
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: Theme.text
                font.family: Tokens.fontUi
                font.pixelSize: Tokens.bodySize
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: root.subtitle
                elide: Text.ElideRight
                color: Theme.textDim
                font.family: Tokens.fontUi
                font.pixelSize: Tokens.smallSize
            }
        }
    }
}
