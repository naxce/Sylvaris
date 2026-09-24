import QtQuick
import qs
import qs.services
import qs.components

Item {
    id: root

    property string title: ""
    property string glyph: ""
    default property alias body: column.data

    MouseArea {
        anchors.fill: parent
    }

    Glass {
        anchors.fill: parent
        radius: Tokens.radiusPanel
        raised: true
        offColor: Theme.surface
        offBorder: Theme.line
    }

    Row {
        id: head
        x: 24
        y: 22
        spacing: 12

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            size: 22
            color: Theme.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: Theme.text
            font.family: Tokens.fontUi
            font.pixelSize: 22
            font.weight: Font.DemiBold
        }
    }

    Flickable {
        x: 24
        y: head.y + head.height + 20
        width: parent.width - 48
        height: parent.height - y - 20
        clip: true
        contentHeight: column.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            width: parent.width
            spacing: 18
        }
    }
}
