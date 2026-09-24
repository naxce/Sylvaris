import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.components

Scope {
    id: root

    property bool shown: false
    property bool wanted: false
    property string view: "compact"
    property string focusKey: ""
    property var screenInfo: null
    readonly property string corner: Settings.values.center.corner
    readonly property bool expanded: root.view !== "compact"
    signal partRequested(string name)

    readonly property var views: ["compact", "orbit-bluetooth", "orbit-wifi", "calendar", "outputs", "displays", "hotspot"]

    function applyView(name: string): void {
        const i = name.indexOf(":");
        const v = i < 0 ? name : name.slice(0, i);
        root.view = root.views.indexOf(v) >= 0 ? v : "compact";
        root.focusKey = i < 0 ? "" : name.slice(i + 1);
    }

    function show(initial: string): void {
        root.wanted = true;
        Compositor.refresh(() => {
            if (!root.wanted)
                return;
            root.screenInfo = Compositor.screenFor(Compositor.focusedName());
            root.applyView(initial);
            root.shown = true;
            Dnd.refresh();
            Toggles.refresh();
            Hotspot.refresh();
            BluetoothService.refreshProfiles();
            Displays.refresh();
        });
    }

    function open(): void {
        if (!root.wanted)
            root.show("compact");
    }

    function close(): void {
        root.wanted = false;
        root.shown = false;
        root.view = "compact";
        root.focusKey = "";
    }

    function handOff(name: string): void {
        root.close();
        root.partRequested(name);
    }

    function toggle(): void {
        if (root.wanted)
            root.close();
        else
            root.open();
    }

    function setView(name: string): void {
        if (root.wanted && root.shown)
            root.applyView(name);
        else
            root.show(name);
    }

    function back(): void {
        if (detail.item !== null && typeof detail.item.back === "function" && detail.item.back())
            return;
        if (root.expanded)
            root.applyView("compact");
        else
            root.close();
    }

    function componentFor(v: string): var {
        if (v === "orbit-bluetooth" || v === "orbit-wifi")
            return orbitView;
        if (v === "calendar")
            return calendarView;
        if (v === "outputs")
            return outputsView;
        if (v === "hotspot")
            return hotspotView;
        if (v === "displays")
            return displaysView;
        return null;
    }

    Component {
        id: orbitView

        OrbitView {
            mode: root.view === "orbit-wifi" ? "wifi" : "bluetooth"
            initialFocus: root.focusKey
            onModeRequested: m => root.applyView("orbit-" + m)
            onCloseRequested: root.applyView("compact")
        }
    }

    Component {
        id: calendarView

        CalendarView {
            onCloseRequested: root.applyView("compact")
        }
    }

    Component {
        id: outputsView

        OutputsView {
            onCloseRequested: root.applyView("compact")
        }
    }

    Component {
        id: hotspotView

        HotspotView {
            onCloseRequested: root.applyView("compact")
        }
    }

    Component {
        id: displaysView

        DisplaysView {
            onCloseRequested: root.applyView("compact")
        }
    }

    PanelWindow {
        id: catcher
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
            top: true
            left: root.corner === "top-left"
            right: root.corner === "top-right"
        }
        margins {
            top: Tokens.edgeMargin
            left: Tokens.edgeMargin
            right: Tokens.edgeMargin
        }
        implicitWidth: Tokens.centerExpandedWidth
        implicitHeight: Math.max(Tokens.centerHeight, compact.implicitHeight)
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "sylcenter"
        WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        mask: Region {
            item: panel
        }
        BackgroundEffect.blurRegion: Resin.enabled ? blur : null

        Region {
            id: blur
            item: panel
            radius: Tokens.radiusPanel
        }

        onVisibleChanged: {
            if (!visible)
                return;
            panel.enter = 0;
            enterAnim.restart();
            panel.forceActiveFocus();
            if (Quickshell.env("SYLVARIS_TRACE") === "1")
                console.log("SYLVARIS_SHOWN " + Date.now());
        }

        Item {
            id: panel

            property real enter: 1

            width: root.expanded ? Tokens.centerExpandedWidth : Tokens.centerCompactWidth
            height: root.expanded ? Tokens.centerHeight : compact.implicitHeight
            x: root.corner === "top-left" ? 0 : root.corner === "top-right" ? win.width - width : (win.width - width) / 2
            opacity: panel.enter
            focus: true
            clip: true
            Keys.onEscapePressed: root.back()

            transform: Translate {
                y: (1 - panel.enter) * -8
            }

            Behavior on width {
                NumberAnimation {
                    duration: Tokens.morphDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Tokens.morphCurve
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: Tokens.morphDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Tokens.morphCurve
                }
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
                radius: Tokens.radiusPanel
                offColor: Theme.surface
                offBorder: Theme.line
            }

            CompactView {
                id: compact
                width: Tokens.centerCompactWidth
                x: root.corner === "top-left" ? 0 : root.corner === "top-right" ? panel.width - width : (panel.width - width) / 2
                opacity: root.expanded ? 0 : 1
                visible: opacity > 0
                enabled: !root.expanded
                onOpenView: name => name === "theme" ? root.handOff(name) : root.applyView(name)

                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.fadeDuration
                    }
                }
            }

            Loader {
                id: detail
                anchors.fill: parent
                active: root.expanded
                opacity: root.expanded ? 1 : 0
                sourceComponent: root.componentFor(root.view)

                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.fadeDuration
                    }
                }
            }
        }
    }
}
