import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.components
import "../lib/preview.mjs" as P

Scope {
    id: root

    property bool shown: false
    property bool wanted: false
    property var screenInfo: null
    property real wheelAcc: 0
    property real reveal: 0
    property real time: 0
    property bool cursorIdle: false
    property point pointer: Qt.point(-1, -1)
    property string shownName: ""
    property string shownDescription: ""
    readonly property var ids: Theme.ids
    readonly property string front: carousel.count > 0 && carousel.currentIndex >= 0 && carousel.currentIndex < root.ids.length ? root.ids[carousel.currentIndex] : ""
    readonly property var frontEntry: root.front !== "" && Theme.catalog[root.front] !== undefined ? Theme.catalog[root.front] : null
    readonly property string frontName: root.frontEntry === null ? "" : root.frontEntry.name

    signal opened

    function stagger(k: int): real {
        return Math.max(0, Math.min(1, (root.reveal - k * 0.14) / 0.72));
    }

    function open(): void {
        if (root.wanted)
            return;
        root.wanted = true;
        Compositor.refresh(() => {
            if (!root.wanted)
                return;
            root.screenInfo = Compositor.screenFor(Compositor.focusedName());
            const i = root.ids.indexOf(Theme.currentId);
            carousel.positionViewAtIndex(Math.max(0, i), PathView.Beginning);
            carousel.currentIndex = Math.max(0, i);
            ThemePreview.begin(Theme.currentId);
            root.wheelAcc = 0;
            root.cursorIdle = false;
            idleTimer.restart();
            root.pointer = Qt.point(-1, -1);
            root.shownName = root.frontName;
            root.shownDescription = root.frontEntry === null ? "" : root.frontEntry.description;
            root.shown = true;
            revealOut.stop();
            revealIn.restart();
            root.opened();
        });
    }

    function finish(): void {
        root.wanted = false;
        if (!root.shown)
            return;
        root.shown = false;
        revealIn.stop();
        revealOut.restart();
    }

    function commit(): void {
        if (!root.shown)
            return;
        ThemePreview.commit(root.front);
        root.finish();
    }

    function cancel(): void {
        if (root.shown)
            ThemePreview.cancel();
        root.finish();
    }

    function close(): void {
        root.cancel();
    }

    function toggle(): void {
        if (root.wanted)
            root.cancel();
        else
            root.open();
    }

    function step(delta: int): void {
        if (!root.shown || carousel.count < 2)
            return;
        if (delta > 0)
            carousel.incrementCurrentIndex();
        else
            carousel.decrementCurrentIndex();
    }

    onFrontNameChanged: {
        if (root.shown)
            nameSwap.restart();
        else
            root.shownName = root.frontName;
    }

    NumberAnimation {
        id: revealIn
        target: root
        property: "reveal"
        to: 1
        duration: 420
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: revealOut
        target: root
        property: "reveal"
        to: 0
        duration: 280
        easing.type: Easing.InCubic
    }

    Timer {
        id: idleTimer
        interval: 1200
        onTriggered: root.cursorIdle = true
    }

    PanelWindow {
        id: win
        visible: root.shown || root.reveal > 0
        screen: root.screenInfo
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "sylvaris-tp"
        WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: {
            if (visible)
                stage.forceActiveFocus();
        }

        FrameAnimation {
            running: win.visible
            onTriggered: root.time += frameTime
        }

        SequentialAnimation {
            id: nameSwap

            ParallelAnimation {
                NumberAnimation {
                    target: nameColumn
                    property: "slide"
                    to: 40
                    duration: 140
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: nameColumn
                    property: "opacity"
                    to: 0
                    duration: 140
                }
            }
            ScriptAction {
                script: {
                    root.shownName = root.frontName;
                    root.shownDescription = root.frontEntry === null ? "" : root.frontEntry.description;
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: nameColumn
                    property: "slide"
                    from: 40
                    to: 0
                    duration: 300
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: nameColumn
                    property: "opacity"
                    to: 1
                    duration: 300
                }
            }
        }

        Item {
            id: backdrop
            anchors.fill: parent
            opacity: Math.min(1, root.reveal * 1.6)
            readonly property bool gpu: backdrop.GraphicsInfo.api !== GraphicsInfo.Software && backdrop.GraphicsInfo.api !== GraphicsInfo.Unknown

            Rectangle {
                anchors.fill: parent
                color: root.frontEntry === null ? Theme.base : root.frontEntry.colors.base
            }

            Repeater {
                model: root.ids
                delegate: Item {
                    id: layerItem
                    required property string modelData
                    readonly property var e: Theme.catalog[modelData] === undefined ? null : Theme.catalog[modelData]
                    anchors.fill: parent
                    opacity: modelData === root.front ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 400
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: backdrop.gpu && layerItem.e !== null
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: layerItem.e === null ? Theme.base : layerItem.e.colors.base
                            }
                            GradientStop {
                                position: 1
                                color: layerItem.e === null ? Theme.base : Qt.darker(layerItem.e.colors.accentDeep, 2.2)
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        scale: 1.06 + 0.02 * Math.sin(root.time * 0.11)

                        transform: Translate {
                            x: 22 * Math.sin(root.time * 0.07)
                            y: 14 * Math.cos(root.time * 0.05)
                        }

                        Image {
                            id: wall
                            anchors.fill: parent
                            anchors.margins: -64
                            visible: false
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 1280
                            source: !backdrop.gpu || layerItem.e === null || layerItem.e.wallpaper === "" ? "" : "file://" + layerItem.e.wallpaper
                        }

                        MultiEffect {
                            anchors.fill: wall
                            visible: backdrop.gpu && wall.status === Image.Ready
                            source: wall
                            blurEnabled: true
                            blur: 1
                            blurMax: 32
                            saturation: 0.1
                            brightness: -0.35
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: backdrop.gpu && wall.status === Image.Ready
                        color: Qt.alpha(layerItem.e === null ? "#000000" : layerItem.e.colors.base, 0.35)
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: Resin.enabled && Resin.tint > 0 && layerItem.e !== null
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: Qt.alpha(layerItem.e === null ? "#000000" : layerItem.e.colors.accent, Resin.tint * 0.6)
                            }
                            GradientStop {
                                position: 0.55
                                color: "transparent"
                            }
                        }
                    }
                }
            }

            Image {
                visible: Resin.enabled && Resin.grain > 0
                anchors.fill: parent
                source: Qt.resolvedUrl("../assets/grain.png")
                fillMode: Image.Tile
                opacity: Resin.grain
                smooth: false
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.shown
                onClicked: root.cancel()
            }
        }

        Item {
            id: stage
            readonly property real k: win.height > 0 ? Math.min(win.width / 2560, win.height / 1440) : 1
            width: 2560
            height: 1440
            scale: stage.k
            transformOrigin: Item.TopLeft
            x: (win.width - 2560 * stage.k) / 2
            y: (win.height - 1440 * stage.k) / 2
            focus: true
            enabled: root.shown

            HoverHandler {
                cursorShape: root.cursorIdle ? Qt.BlankCursor : Qt.ArrowCursor
                onPointChanged: {
                    root.cursorIdle = false;
                    idleTimer.restart();
                    root.pointer = point.position;
                }
                onHoveredChanged: {
                    if (!hovered)
                        root.pointer = Qt.point(-1, -1);
                }
            }

            Keys.onLeftPressed: root.step(-1)
            Keys.onRightPressed: root.step(1)
            Keys.onReturnPressed: root.commit()
            Keys.onEnterPressed: root.commit()
            Keys.onEscapePressed: root.cancel()

            PathView {
                id: carousel
                anchors.fill: parent
                opacity: root.stagger(0)
                model: root.ids
                pathItemCount: Math.min(count, 7)
                preferredHighlightBegin: 0
                preferredHighlightEnd: 0
                highlightRangeMode: PathView.StrictlyEnforceRange
                highlightMoveDuration: 450
                snapMode: PathView.SnapOneItem
                interactive: count > 1
                onCurrentIndexChanged: {
                    if (root.shown && currentIndex >= 0 && currentIndex < root.ids.length)
                        ThemePreview.settle(root.ids[currentIndex]);
                }

                transform: Translate {
                    y: (1 - root.stagger(0)) * 160
                }

                path: Path {
                    startX: 1280
                    startY: Tokens.tpRingCenterY + Tokens.tpRingY

                    PathAttribute {
                        name: "depth"
                        value: 1
                    }
                    PathAttribute {
                        name: "turn"
                        value: 0
                    }
                    PathArc {
                        x: 1280 + Tokens.tpRingX
                        y: Tokens.tpRingCenterY
                        radiusX: Tokens.tpRingX
                        radiusY: Tokens.tpRingY
                        direction: PathArc.Counterclockwise
                    }
                    PathAttribute {
                        name: "depth"
                        value: 0.775
                    }
                    PathAttribute {
                        name: "turn"
                        value: -28
                    }
                    PathArc {
                        x: 1280
                        y: Tokens.tpRingCenterY - Tokens.tpRingY
                        radiusX: Tokens.tpRingX
                        radiusY: Tokens.tpRingY
                        direction: PathArc.Counterclockwise
                    }
                    PathAttribute {
                        name: "depth"
                        value: 0.55
                    }
                    PathAttribute {
                        name: "turn"
                        value: 0
                    }
                    PathArc {
                        x: 1280 - Tokens.tpRingX
                        y: Tokens.tpRingCenterY
                        radiusX: Tokens.tpRingX
                        radiusY: Tokens.tpRingY
                        direction: PathArc.Counterclockwise
                    }
                    PathAttribute {
                        name: "depth"
                        value: 0.775
                    }
                    PathAttribute {
                        name: "turn"
                        value: 28
                    }
                    PathArc {
                        x: 1280
                        y: Tokens.tpRingCenterY + Tokens.tpRingY
                        radiusX: Tokens.tpRingX
                        radiusY: Tokens.tpRingY
                        direction: PathArc.Counterclockwise
                    }
                }

                delegate: ThemeCard {
                    time: root.time
                    pointer: root.pointer
                    onPicked: i => {
                        if (i === carousel.currentIndex)
                            root.commit();
                        else
                            carousel.currentIndex = i;
                    }
                }

                TapHandler {
                    onTapped: root.cancel()
                }

                WheelHandler {
                    onWheel: event => {
                        const r = P.wheelStep(root.wheelAcc, event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x);
                        root.wheelAcc = r.acc;
                        for (let i = 0; i < Math.abs(r.steps); i++)
                            root.step(r.steps > 0 ? 1 : -1);
                    }
                }
            }

            Text {
                visible: carousel.count === 0
                anchors.centerIn: parent
                opacity: root.stagger(0)
                text: "No themes found"
                color: Theme.textDim
                font.family: Tokens.fontUi
                font.pixelSize: 48
            }

            Item {
                x: 140
                y: 1440 - 170 - nameText.height
                width: nameColumn.width
                height: nameColumn.height
                opacity: root.stagger(1)

                transform: Translate {
                    y: (1 - root.stagger(1)) * 160
                }

                Column {
                    id: nameColumn
                    property real slide: 0
                    spacing: 6

                    transform: Translate {
                        y: nameColumn.slide
                    }

                    Text {
                        id: nameText
                        text: root.shownName
                        color: Qt.alpha(root.frontEntry === null ? Theme.text : root.frontEntry.colors.text, 0.92)
                        font.family: Tokens.fontUi
                        font.pixelSize: Tokens.tpNameSize
                        font.weight: Font.ExtraBold
                        font.letterSpacing: -6
                        layer.enabled: backdrop.gpu
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowBlur: 0.6
                            shadowOpacity: 0.45
                        }
                    }

                    Text {
                        text: root.shownDescription
                        color: root.frontEntry === null ? Theme.textDim : root.frontEntry.colors.textDim
                        font.family: Tokens.fontUi
                        font.pixelSize: 28
                    }
                }
            }

            Item {
                id: applyButton
                visible: carousel.count > 0
                x: 2560 - 140 - width
                y: 1440 - 140 - height
                width: applyLabel.implicitWidth + 68
                height: applyLabel.implicitHeight + 40
                opacity: root.stagger(2)
                scale: applyArea.pressed ? 0.96 : applyArea.containsMouse ? 1.03 : 1

                transform: Translate {
                    y: (1 - root.stagger(2)) * 160
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                }

                Glass {
                    anchors.fill: parent
                    radius: height / 2
                    lit: true
                    hot: applyArea.containsMouse
                }

                Text {
                    id: applyLabel
                    anchors.centerIn: parent
                    text: "Apply theme"
                    color: Theme.onAccent
                    font.family: Tokens.fontUi
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: applyArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.commit()
                }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 1440 - 50 - height
                width: hint.implicitWidth + 40
                height: hint.implicitHeight + 16
                opacity: root.stagger(2)

                transform: Translate {
                    y: (1 - root.stagger(2)) * 160
                }

                Glass {
                    anchors.fill: parent
                    radius: height / 2
                }

                Text {
                    id: hint
                    anchors.centerIn: parent
                    text: Theme.hookError !== "" ? Theme.hookError : "◀ ▶ switch · Enter apply · Esc cancel"
                    color: Theme.hookError !== "" ? Theme.danger : Theme.textSoft
                    font.family: Tokens.fontUi
                    font.pixelSize: 20
                }
            }
        }

    }
}
