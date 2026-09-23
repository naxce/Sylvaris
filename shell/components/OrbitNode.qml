import QtQuick
import qs
import qs.services

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string sub: ""
    property bool danger: false
    property bool selected: false
    property bool bold: false

    signal clicked

    implicitWidth: row.implicitWidth + 28
    implicitHeight: Math.max(40, row.implicitHeight + 20)
    radius: Tokens.radiusNode
    color: root.selected ? Theme.accent : Theme.node
    border.width: 1
    border.color: Theme.lineStrong
    scale: hover.hovered ? 1.04 : 1

    Behavior on scale {
        NumberAnimation {
            duration: 120
        }
    }

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
        anchors.centerIn: parent
        spacing: 10

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            size: 20
            color: root.selected ? Theme.onAccent : root.danger ? Theme.danger : Theme.accent
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: Math.min(implicitWidth, Tokens.nodeLabelMax)
                text: root.label
                elide: Text.ElideRight
                color: root.selected ? Theme.onAccent : Theme.text
                font.family: Tokens.fontUi
                font.pixelSize: Tokens.nodeSize
                font.weight: root.bold ? Font.DemiBold : Font.Normal
            }

            Text {
                visible: root.sub !== ""
                width: Math.min(implicitWidth, Tokens.nodeLabelMax)
                text: root.sub
                elide: Text.ElideRight
                color: root.selected ? Theme.onAccent : Theme.textDim
                font.family: Tokens.fontUi
                font.pixelSize: Tokens.tinySize
            }
        }
    }
}
