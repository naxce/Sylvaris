import QtQuick
import qs

Text {
    id: root

    property real size: 20

    font.family: Tokens.fontMono
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    TextMetrics {
        id: ink
        font: root.font
        text: root.text
    }

    FontMetrics {
        id: line
        font: root.font
    }

    transform: Translate {
        x: root.text === "" ? 0 : Math.round(ink.advanceWidth / 2 - ink.tightBoundingRect.x - ink.tightBoundingRect.width / 2)
        y: root.text === "" ? 0 : Math.round(line.height / 2 - line.ascent - ink.tightBoundingRect.y - ink.tightBoundingRect.height / 2)
    }
}
