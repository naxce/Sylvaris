import QtQuick
import QtQuick.Effects

Item {
    id: root

    property real radius: 0
    default property alias content: holder.data

    Item {
        id: holder
        anchors.fill: parent
        visible: false
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
        layer.smooth: true
    }

    MultiEffect {
        anchors.fill: parent
        source: holder
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }
}
