import QtQuick
import qs
import qs.services
import qs.components

Item {
    id: root

    property string text: ""
    property string glyph: ""
    property bool lit: false

    signal clicked

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 32

    Glass {
        anchors.fill: parent
        radius: height / 2
        inner: true
        lit: root.lit
        hot: area.containsMouse
        offBorder: Theme.cardLine
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Glyph {
            visible: root.glyph !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            size: 14
            color: root.lit ? Theme.onAccent : Theme.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.lit ? Theme.onAccent : Theme.text
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.smallSize
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
