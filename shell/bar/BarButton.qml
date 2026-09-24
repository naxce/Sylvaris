import QtQuick
import qs
import qs.services
import qs.components

Item {
    id: root

    property string glyph: ""
    property string label: ""
    property color tint: Theme.text
    property bool lit: false
    property int badge: 0
    property bool mono: false
    default property alias extra: row.data
    readonly property bool hovered: area.containsMouse

    signal clicked(var mouse)
    signal wheel(int steps)

    implicitWidth: row.implicitWidth + 20
    implicitHeight: Tokens.barItemHeight
    width: Math.max(implicitWidth, implicitHeight)
    height: implicitHeight

    Glass {
        anchors.fill: parent
        radius: height / 2
        inner: true
        lit: root.lit
        opacity: root.lit || root.hovered ? 1 : 0
        offBorder: "transparent"

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.stateDuration
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7

        Glyph {
            visible: root.glyph !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            size: Tokens.barGlyph
            color: root.lit ? Theme.onAccent : root.tint
        }

        Text {
            visible: root.label !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.lit ? Theme.onAccent : Theme.text
            font.family: root.mono ? Tokens.fontMono : Tokens.fontUi
            font.pixelSize: Tokens.barText
            font.weight: Font.Medium
        }
    }

    Rectangle {
        visible: root.badge > 0
        x: parent.width - width + 2
        y: -1
        width: Math.max(16, badgeText.implicitWidth + 8)
        height: 16
        radius: 8
        color: Theme.accent
        border.width: 2
        border.color: Qt.alpha(Theme.base, 0.6)

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: root.badge > 99 ? "99+" : root.badge
            color: Theme.onAccent
            font.family: Tokens.fontUi
            font.pixelSize: 10
            font.weight: Font.Bold
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: event => {
            const d = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
            if (d !== 0)
                root.wheel(d > 0 ? 1 : -1);
        }
    }
}
