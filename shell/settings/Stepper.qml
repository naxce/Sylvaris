import QtQuick
import qs
import qs.services
import qs.components

Row {
    id: root

    property int value: 0
    property int from: 0
    property int to: 10
    property string suffix: ""
    property int step: 1

    signal stepped(int value)

    spacing: 6

    Repeater {
        model: [-1, 0, 1]

        delegate: Item {
            required property int modelData
            width: modelData === 0 ? 80 : 34
            height: 34

            Glass {
                visible: modelData !== 0
                anchors.fill: parent
                radius: height / 2
                inner: true
                hot: stepArea.containsMouse
                offBorder: Theme.cardLine
                opacity: (modelData < 0 && root.value <= root.from) || (modelData > 0 && root.value >= root.to) ? 0.4 : 1
            }

            Text {
                anchors.centerIn: parent
                text: modelData === 0 ? root.value + root.suffix : modelData < 0 ? "−" : "+"
                color: Theme.text
                font.family: modelData === 0 ? Tokens.fontMono : Tokens.fontUi
                font.pixelSize: modelData === 0 ? Tokens.bodySize : Tokens.titleSize
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: stepArea
                anchors.fill: parent
                enabled: modelData !== 0
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.stepped(Math.max(root.from, Math.min(root.to, root.value + modelData * root.step)))
            }
        }
    }
}
