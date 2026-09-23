import QtQuick
import qs
import qs.services

Rectangle {
    id: root

    property alias text: input.text
    property bool password: false
    property string placeholder: ""

    signal accepted

    function focusInput(): void {
        input.forceActiveFocus();
    }

    implicitHeight: 44
    radius: Tokens.radiusRow
    color: Theme.tintMid
    border.width: 1
    border.color: input.activeFocus ? Theme.accent : Theme.cardLine

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        selectionColor: Theme.fill
        font.family: Tokens.fontUi
        font.pixelSize: Tokens.bodySize
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        clip: true
        onAccepted: root.accepted()
    }

    Text {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text === ""
        text: root.placeholder
        color: Theme.textDim
        font.family: Tokens.fontUi
        font.pixelSize: Tokens.bodySize
    }
}
