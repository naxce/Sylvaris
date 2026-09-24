import QtQuick
import qs
import qs.services

Item {
    id: root

    property bool checked: false

    signal toggled(bool value)

    implicitWidth: 48
    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        antialiasing: true
        color: root.checked ? Theme.accent : Qt.alpha(Theme.text, 0.16)
        border.width: root.checked ? 0 : 1
        border.color: Qt.alpha(Theme.text, 0.12)

        Behavior on color {
            ColorAnimation {
                duration: Tokens.stateDuration
            }
        }
    }

    Rectangle {
        x: root.checked ? root.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: root.height - 6
        height: width
        radius: width / 2
        antialiasing: true
        color: root.checked ? Theme.onAccent : Theme.text

        Behavior on x {
            NumberAnimation {
                duration: Tokens.stateDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
