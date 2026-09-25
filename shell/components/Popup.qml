import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import "../lib/motion.mjs" as M
import "../lib/bar.mjs" as B

Scope {
    id: root

    property string namespace: "sylpopup"
    property string corner: "top-center"
    readonly property string placed: B.placeCorner(root.corner, Settings.values.parts.bar ? Settings.values.bar.position : "top")
    property int panelWidth: Tokens.centerCompactWidth
    property int panelHeight: Tokens.centerHeight
    property real radius: Tokens.radiusPanel
    property bool keyboard: true
    property real dim: 0
    property bool shown: false
    property bool wanted: false
    property var screenInfo: null
    property real phase: 0
    default property alias content: body.data
    readonly property Item panel: panel
    readonly property bool live: root.shown || root.phase > 0
    readonly property real grow: 0.94 + 0.06 * root.phase
    readonly property var visual: M.scaledRect(0, 0, win.width, win.height, root.placed, root.grow, (1 - root.phase) * 10 * M.rise(root.placed))

    signal opened
    signal closed

    function originItem(): int {
        const o = M.origin(root.placed);
        const table = [[Item.TopLeft, Item.Top, Item.TopRight], [Item.Left, Item.Center, Item.Right], [Item.BottomLeft, Item.Bottom, Item.BottomRight]];
        return table[o.v * 2][o.h * 2];
    }

    function reveal(): void {
        root.shown = true;
        exitAnim.stop();
        enterAnim.restart();
        root.opened();
    }

    function open(): void {
        if (root.wanted)
            return;
        root.wanted = true;
        Compositor.refresh(() => {
            if (!root.wanted)
                return;
            root.screenInfo = Compositor.screenFor(Compositor.focusedName());
            root.reveal();
        });
    }

    function close(): void {
        const was = root.wanted;
        root.wanted = false;
        if (root.shown) {
            root.shown = false;
            enterAnim.stop();
            exitAnim.restart();
        }
        if (was)
            root.closed();
    }

    function toggleOn(screen: var): void {
        if (root.wanted) {
            root.close();
            return;
        }
        root.wanted = true;
        if (root.phase > 0 && root.screenInfo !== screen)
            root.phase = 0;
        root.screenInfo = screen;
        root.reveal();
    }

    function toggle(): void {
        if (root.wanted)
            root.close();
        else
            root.open();
    }

    NumberAnimation {
        id: enterAnim
        target: root
        property: "phase"
        to: 1
        duration: Tokens.enterDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.enterCurve
    }

    NumberAnimation {
        id: exitAnim
        target: root
        property: "phase"
        to: 0
        duration: Tokens.exitDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.exitCurve
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
        color: Qt.alpha("#000000", root.dim * root.phase)
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "sylcatcher"

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    PanelWindow {
        id: win
        visible: root.live
        screen: root.screenInfo
        anchors {
            top: root.placed.indexOf("top") === 0
            bottom: root.placed.indexOf("bottom") === 0
            left: root.placed.indexOf("left") > 0
            right: root.placed.indexOf("right") > 0
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
            item: root.shown ? panel : null
        }
        BackgroundEffect.blurRegion: Resin.enabled && root.phase > 0.02 ? blur : null

        Region {
            id: blur
            x: Math.round(root.visual.x) + 1
            y: Math.round(root.visual.y) + 1
            width: Math.round(root.visual.w) - 2
            height: Math.round(root.visual.h) - 2
            radius: root.radius * root.grow - 1
        }

        onVisibleChanged: {
            if (visible)
                panel.forceActiveFocus();
        }

        Item {
            id: panel

            anchors.fill: parent
            opacity: Math.min(1, root.phase * 1.6)
            scale: root.grow
            transformOrigin: root.originItem()
            focus: true
            Keys.onEscapePressed: root.close()

            transform: Translate {
                y: (1 - root.phase) * 10 * M.rise(root.placed)
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
