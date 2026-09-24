import QtQuick
import qs
import qs.services

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool last: false
    default property alias control: slot.data

    width: parent ? parent.width : 0
    implicitHeight: Math.max(Tokens.settingsRow, labels.implicitHeight + 24, slot.childrenRect.height + 20)

    Column {
        id: labels
        anchors.left: parent.left
        anchors.right: slot.left
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            color: Theme.text
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.bodySize
        }

        Text {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            wrapMode: Text.Wrap
            color: Theme.textDim
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.smallSize
        }
    }

    Item {
        id: slot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }

    Rectangle {
        visible: !root.last
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Qt.alpha(Theme.text, 0.08)
    }
}
