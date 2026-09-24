import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

Scope {
    id: root

    property string namespace: "sylpopup"
    property string corner: "top-center"
    property int panelWidth: Tokens.centerCompactWidth
    property int panelHeight: Tokens.centerHeight
    property real radius: Tokens.radiusPanel
    property bool keyboard: true
    property bool shown: false
    property bool wanted: false
    property var screenInfo: null
    default property alias content: body.data
    readonly property Item panel: panel

    signal opened
    signal closed

    function open(): void {
        if (root.wanted)
            return;
        root.wanted = true;
        Compositor.refresh(() => {
            if (!root.wanted)
                return;
            root.screenInfo = Compositor.screenFor(Compositor.focusedName());
            root.shown = true;
            root.opened();
        });
    }

    function close(): void {
        const was = root.wanted;
        root.wanted = false;
        root.shown = false;
        if (was)
            root.closed();
    }

    function toggle(): void {
        if (root.wanted)
            root.close();
        else
            root.open();
    }

    PanelWindow {
        visible: root.shown
        screen: root.screenInfo
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "sylcatcher"

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    PanelWindow {
        id: win
        visible: root.shown
        screen: root.screenInfo
        anchors {
            top: root.corner.indexOf("top") === 0
            bottom: root.corner.indexOf("bottom") === 0
            left: root.corner.indexOf("left") > 0
            right: root.corner.indexOf("right") > 0
        }
        margins {
            top: Tokens.edgeMargin
            bottom: Tokens.edgeMargin
            left: Tokens.edgeMargin
            right: Tokens.edgeMargin
        }
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: root.namespace
        WlrLayershell.keyboardFocus: root.shown && root.keyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        mask: Region {
            item: panel
        }
        BackgroundEffect.blurRegion: Resin.enabled ? blur : null

        Region {
            id: blur
            item: panel
            radius: root.radius
        }

        onVisibleChanged: {
            if (!visible)
                return;
            panel.enter = 0;
            enterAnim.restart();
            panel.forceActiveFocus();
        }

        Item {
            id: panel

            property real enter: 1

            anchors.fill: parent
            opacity: panel.enter
            focus: true
            Keys.onEscapePressed: root.close()

            transform: Translate {
                y: (1 - panel.enter) * (root.corner.indexOf("bottom") === 0 ? 8 : -8)
            }

            NumberAnimation {
                id: enterAnim
                target: panel
                property: "enter"
                from: 0
                to: 1
                duration: Tokens.openDuration
                easing.type: Easing.OutCubic
            }

            Glass {
                anchors.fill: parent
                radius: root.radius
                offColor: Theme.surface
                offBorder: Theme.line
            }

            Item {
                id: body
                anchors.fill: parent
            }
        }
    }
}
