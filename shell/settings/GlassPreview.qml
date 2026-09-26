import QtQuick
import qs
import qs.services
import qs.components

MiniScreen {
    id: root

    dim: false

    Glass {
        anchors.centerIn: parent
        width: parent.width * 0.46
        height: parent.height * 0.56
        radius: Tokens.radiusCard

        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Resin Glass"
                color: Theme.text
                font.family: Tokens.fontUi
                font.pixelSize: Tokens.bodySize
                font.weight: Font.DemiBold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Resin.enabled ? "What every panel is made of" : "Solid panels"
                color: Theme.textDim
                font.family: Tokens.fontUi
                font.pixelSize: Tokens.tinySize
            }
        }
    }
}
