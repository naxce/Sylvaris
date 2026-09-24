import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.components
import "../lib/pad.mjs" as P
import "../lib/preview.mjs" as W
import "../lib/icons.mjs" as Icons
import "../lib/bar.mjs" as B

Scope {
    id: root

    property bool shown: false
    property bool wanted: false
    property var screenInfo: null
    property real reveal: 0
    property string query: ""
    property int selected: -1
    property real wheelAcc: 0
    readonly property int columns: Settings.values.pad.columns
    readonly property int rows: Settings.values.pad.rows
    readonly property int perPage: root.columns * root.rows
    readonly property var results: P.search(Apps.list, root.query)
    readonly property var pageList: P.pages(root.results, root.perPage)
    readonly property int page: pagesView.currentIndex

    signal opened

    function open(): void {
        if (root.wanted)
            return;
        root.wanted = true;
        Compositor.refresh(() => {
            if (!root.wanted)
                return;
            root.screenInfo = Compositor.screenFor(Compositor.focusedName());
            root.query = "";
            root.selected = -1;
            root.shown = true;
            pagesView.currentIndex = 0;
            hideAnim.stop();
            showAnim.restart();
            root.opened();
        });
    }

    function close(): void {
        root.wanted = false;
        if (!root.shown)
            return;
        showAnim.stop();
        hideAnim.restart();
    }

    function toggleOn(screen: var): void {
        if (root.wanted) {
            root.close();
            return;
        }
        root.wanted = true;
        root.screenInfo = screen;
        root.query = "";
        root.selected = -1;
        root.shown = true;
        pagesView.currentIndex = 0;
        hideAnim.stop();
        showAnim.restart();
        root.opened();
    }

    function toggle(): void {
        if (root.wanted)
            root.close();
        else
            root.open();
    }

    function launch(app: var): void {
        Apps.launch(app);
        root.close();
    }

    function select(index: int): void {
        root.selected = index;
        if (index >= 0)
            pagesView.currentIndex = Math.floor(index / root.perPage);
    }

    function turn(delta: int): void {
        pagesView.currentIndex = Math.max(0, Math.min(root.pageList.length - 1, pagesView.currentIndex + delta));
        if (root.selected >= 0)
            root.selected = Math.min(root.results.length - 1, pagesView.currentIndex * root.perPage);
    }

    onQueryChanged: root.select(root.query === "" || root.results.length === 0 ? -1 : 0)

    NumberAnimation {
        id: showAnim
        target: root
        property: "reveal"
        to: 1
        duration: 320
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: hideAnim
        target: root
        property: "reveal"
        to: 0
        duration: 200
        easing.type: Easing.InCubic
        onFinished: root.shown = false
    }

    PanelWindow {
        id: win
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
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "sylpad"
        WlrLayershell.keyboardFocus: root.wanted ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: {
            if (visible)
                search.forceActiveFocus();
        }

        Item {
            id: backdrop
            anchors.fill: parent
            opacity: root.reveal
            readonly property bool gpu: backdrop.GraphicsInfo.api !== GraphicsInfo.Software && backdrop.GraphicsInfo.api !== GraphicsInfo.Unknown

            Rectangle {
                anchors.fill: parent
                color: Theme.base
            }

            Image {
                id: wall
                anchors.fill: parent
                anchors.margins: -64
                visible: false
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 1280
                source: !backdrop.gpu || Theme.wallpaper === "" ? "" : "file://" + Theme.wallpaper
            }

            MultiEffect {
                anchors.fill: wall
                visible: backdrop.gpu && wall.status === Image.Ready
                source: wall
                blurEnabled: true
                blur: 1
                blurMax: 48
                saturation: 0.2
                brightness: -0.3
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.alpha(Theme.base, 0.35)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.alpha(Qt.darker(Theme.accentDeep, 2.4), 0.55)
                    }
                }
            }

            Image {
                visible: Resin.enabled && Resin.grain > 0
                opacity: Resin.grain
                anchors.fill: parent
                source: Qt.resolvedUrl("../assets/grain.png")
                fillMode: Image.Tile
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Item {
            id: stage
            anchors.fill: parent
            opacity: root.reveal
            scale: 1.08 - 0.08 * root.reveal

            Item {
                id: searchBox
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round(parent.height * 0.07)
                width: Tokens.padSearchWidth
                height: Tokens.padSearchHeight

                Glass {
                    anchors.fill: parent
                    radius: height / 2
                    inner: true
                    offBorder: Theme.cardLine
                }

                Glyph {
                    id: searchGlyph
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: Icons.GLYPHS.search
                    size: 18
                    color: Theme.textDim
                }

                Text {
                    anchors.left: searchGlyph.right
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: "Search"
                    color: Theme.textDim
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.bodySize
                }

                TextInput {
                    id: search
                    anchors.left: searchGlyph.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.onAccent
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.bodySize
                    clip: true
                    text: root.query
                    onTextEdited: root.query = text

                    Keys.onPressed: event => {
                        const keys = {
                            [Qt.Key_Left]: "left",
                            [Qt.Key_Right]: "right",
                            [Qt.Key_Up]: "up",
                            [Qt.Key_Down]: "down",
                            [Qt.Key_PageUp]: "pageUp",
                            [Qt.Key_PageDown]: "pageDown"
                        };
                        if (event.key === Qt.Key_Escape) {
                            if (root.query !== "")
                                root.query = "";
                            else
                                root.close();
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (root.selected >= 0)
                                root.launch(root.results[root.selected]);
                        } else if (keys[event.key] !== undefined) {
                            const from = root.selected < 0 ? root.page * root.perPage - (keys[event.key] === "right" ? 1 : 0) : root.selected;
                            root.select(P.move(Math.max(0, from), keys[event.key], root.results.length, root.columns, root.perPage));
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }
                }
            }

            ListView {
                id: pagesView
                anchors.top: searchBox.bottom
                anchors.topMargin: Math.round(parent.height * 0.05)
                anchors.bottom: dots.top
                anchors.bottomMargin: 24
                width: parent.width
                orientation: ListView.Horizontal
                snapMode: ListView.SnapOneItem
                highlightRangeMode: ListView.StrictlyEnforceRange
                highlightMoveDuration: 380
                boundsBehavior: Flickable.StopAtBounds
                clip: false
                model: root.pageList

                delegate: Item {
                    id: pageItem
                    required property var modelData
                    required property int index
                    width: pagesView.width
                    height: pagesView.height

                    Grid {
                        anchors.horizontalCenter: parent.horizontalCenter
                        columns: root.columns
                        readonly property real cellW: Math.min(pagesView.width * 0.8 / root.columns, Tokens.padCellWidth)
                        readonly property real cellH: Math.min(Tokens.padCellHeight, pagesView.height / root.rows)

                        Repeater {
                            model: pageItem.modelData
                            delegate: Item {
                                id: cell
                                required property var modelData
                                required property int index
                                readonly property int flat: pageItem.index * root.perPage + index
                                readonly property bool current: root.selected === cell.flat
                                width: parent.cellW
                                height: parent.cellH

                                Item {
                                    anchors.centerIn: parent
                                    width: Tokens.padIcon + 44
                                    height: Tokens.padIcon + 62

                                    Glass {
                                        anchors.fill: parent
                                        radius: Tokens.radiusCard
                                        inner: true
                                        lit: false
                                        opacity: cell.current || area.containsMouse ? 1 : 0
                                        offBorder: Theme.cardLine

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Tokens.stateDuration
                                            }
                                        }
                                    }

                                    Item {
                                        id: iconBox
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 12
                                        width: Tokens.padIcon
                                        height: Tokens.padIcon
                                        scale: area.pressed ? 0.92 : area.containsMouse || cell.current ? 1.06 : 1

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: Tokens.stateDuration
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            visible: appIcon.status !== Image.Ready
                                            radius: Tokens.radiusCard
                                            gradient: Gradient {
                                                GradientStop {
                                                    position: 0
                                                    color: Theme.accentHi
                                                }
                                                GradientStop {
                                                    position: 1
                                                    color: Theme.accentDeep
                                                }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: cell.modelData.name.charAt(0).toUpperCase()
                                                color: Theme.onAccent
                                                font.family: Tokens.fontUi
                                                font.pixelSize: Tokens.padIcon * 0.42
                                                font.weight: Font.DemiBold
                                            }
                                        }

                                        Image {
                                            id: appIcon
                                            anchors.fill: parent
                                            source: Apps.icon(cell.modelData)
                                            sourceSize.width: Tokens.padIcon * 2
                                            sourceSize.height: Tokens.padIcon * 2
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            smooth: true
                                            mipmap: true
                                        }
                                    }

                                    Text {
                                        anchors.top: iconBox.bottom
                                        anchors.topMargin: 8
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: parent.width - 8
                                        horizontalAlignment: Text.AlignHCenter
                                        text: cell.modelData.name
                                        elide: Text.ElideRight
                                        maximumLineCount: 2
                                        wrapMode: Text.Wrap
                                        color: Theme.text
                                        style: Text.Raised
                                        styleColor: Qt.alpha("#000000", 0.35)
                                        font.family: Tokens.fontUi
                                        font.pixelSize: Tokens.smallSize
                                        font.weight: Font.Medium
                                    }

                                    Glyph {
                                        visible: Settings.values.deck.pinned.indexOf(cell.modelData.id) >= 0
                                        anchors.right: iconBox.right
                                        anchors.top: iconBox.top
                                        anchors.margins: -4
                                        text: Icons.GLYPHS.pin
                                        size: 16
                                        color: Theme.accent
                                    }

                                    MouseArea {
                                        id: area
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.RightButton)
                                                Settings.set("deck.pinned", B.togglePin(Settings.values.deck.pinned, cell.modelData.id));
                                            else
                                                root.launch(cell.modelData);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                WheelHandler {
                    onWheel: event => {
                        const r = W.wheelStep(root.wheelAcc, event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x);
                        root.wheelAcc = r.acc;
                        if (r.steps !== 0)
                            root.turn(r.steps > 0 ? 1 : -1);
                    }
                }
            }

            Column {
                anchors.centerIn: pagesView
                visible: root.results.length === 0
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.query === "" ? "No applications found" : "Nothing matches “" + root.query + "”"
                    color: Theme.text
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.titleSize
                    font.weight: Font.DemiBold
                }
            }

            Row {
                id: dots
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Math.round(parent.height * 0.06)
                spacing: 10
                visible: root.pageList.length > 1

                Repeater {
                    model: root.pageList.length
                    delegate: Rectangle {
                        required property int index
                        width: index === root.page ? 26 : 9
                        height: 9
                        radius: 4.5
                        color: index === root.page ? Theme.accent : Qt.alpha(Theme.text, 0.35)

                        Behavior on width {
                            NumberAnimation {
                                duration: Tokens.stateDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: pagesView.currentIndex = index
                        }
                    }
                }
            }
        }
    }
}
