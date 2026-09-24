import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.components
import "../lib/bar.mjs" as B
import "../lib/icons.mjs" as Icons

Scope {
    id: root

    readonly property var cfg: Settings.values.deck
    readonly property int size: root.cfg.size
    readonly property real reach: root.size * 2.6
    readonly property var windows: Compositor.windows
    readonly property var items: B.deckItems(root.cfg.pinned, root.windows, appId => root.entryId(appId))
    property bool padOpen: false

    signal request(string part, string arg, var screen)

    function entry(id: string): var {
        if (Demo.enabled)
            return Apps.byId(id);
        return DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id);
    }

    function entryId(appId: string): string {
        if (Demo.enabled)
            return appId;
        const e = DesktopEntries.heuristicLookup(appId);
        return e ? e.id : appId;
    }

    function nameOf(id: string): string {
        const e = root.entry(id);
        return e ? e.name : id;
    }

    function pin(id: string): void {
        Settings.set("deck.pinned", B.togglePin(root.cfg.pinned, id));
    }

    function click(item: var): void {
        const next = B.nextWindow(item.windows, root.windows);
        if (next >= 0)
            Compositor.activate(root.windows[next]);
        else
            Apps.launch(root.entry(item.id));
    }

    function slots(): var {
        const out = [];
        if (root.cfg.pad === "start")
            out.push({
                kind: "pad"
            });
        let pinnedDone = false;
        for (const it of root.items) {
            if (!it.pinned && !pinnedDone) {
                pinnedDone = true;
                if (out.length > 0)
                    out.push({
                        kind: "gap"
                    });
            }
            out.push({
                kind: "app",
                item: it
            });
        }
        if (root.cfg.pad === "end") {
            if (out.length > 0)
                out.push({
                    kind: "gap"
                });
            out.push({
                kind: "pad"
            });
        }
        return out;
    }

    Variants {
        model: root.cfg.enabled ? Quickshell.screens : []

        delegate: PanelWindow {
            id: deck

            required property var modelData
            readonly property var list: root.slots()
            readonly property bool hovering: dockHover.hovered || stripHover.hovered
            readonly property bool hidden: root.cfg.autohide && !deck.hovering && !menu.visible && !hideDelay.running
            property real pointer: -1
            property real reveal: deck.hidden ? 0 : 1

            screen: modelData
            anchors {
                bottom: true
                left: true
                right: true
            }
            implicitHeight: root.size * 1.5 + Tokens.deckPadding * 2 + Tokens.deckMargin + 40
            color: "transparent"
            exclusionMode: root.cfg.autohide ? ExclusionMode.Ignore : ExclusionMode.Normal
            exclusiveZone: root.cfg.autohide ? 0 : root.size + Tokens.deckPadding * 2 + Tokens.deckMargin
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "syldeck"
            mask: Region {
                item: deck.reveal > 0.01 ? dock : strip
            }
            BackgroundEffect.blurRegion: Resin.enabled && deck.reveal > 0.01 ? blur : null

            Behavior on reveal {
                NumberAnimation {
                    duration: Tokens.stateDuration + 120
                    easing.type: Easing.OutCubic
                }
            }

            onHoveringChanged: {
                if (!deck.hovering)
                    hideDelay.restart();
            }

            Timer {
                id: hideDelay
                interval: 600
            }

            Region {
                id: blur
                item: dock
                radius: Tokens.deckRadius
            }

            Item {
                id: strip
                anchors.bottom: parent.bottom
                width: parent.width
                height: 4

                HoverHandler {
                    id: stripHover
                }
            }

            Item {
                id: dock
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height - height - Tokens.deckMargin + (1 - deck.reveal) * (height + Tokens.deckMargin + 4)
                width: row.width + Tokens.deckPadding * 2
                height: root.size + Tokens.deckPadding * 2

                HoverHandler {
                    id: dockHover
                    onPointChanged: deck.pointer = dockHover.hovered && root.cfg.magnify ? dockHover.point.position.x - Tokens.deckPadding : -1
                    onHoveredChanged: {
                        if (!hovered)
                            deck.pointer = -1;
                    }
                }

                Glass {
                    anchors.fill: parent
                    radius: Tokens.deckRadius
                    offColor: Theme.surface
                    offBorder: Theme.line
                }

                Row {
                    id: row
                    x: Tokens.deckPadding
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Tokens.deckPadding
                    spacing: 6

                    Repeater {
                        model: deck.list

                        delegate: Item {
                            id: slot
                            required property var modelData
                            required property int index
                            readonly property real rest: slot.index * (root.size + row.spacing) + root.size / 2
                            readonly property real scaleNow: deck.pointer < 0 || slot.modelData.kind === "gap" ? 1 : B.magnify(slot.rest - deck.pointer, root.reach)
                            readonly property var appItem: slot.modelData.kind === "app" ? slot.modelData.item : null
                            readonly property var appEntry: slot.appItem === null ? null : root.entry(slot.appItem.id)
                            readonly property bool focused: slot.appItem !== null && slot.appItem.windows.some(i => root.windows[i].activated)

                            width: slot.modelData.kind === "gap" ? 14 : root.size * slot.scaleNow
                            height: root.size * slot.scaleNow
                            anchors.bottom: parent.bottom

                            Behavior on width {
                                enabled: deck.pointer < 0
                                NumberAnimation {
                                    duration: Tokens.stateDuration
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                visible: slot.modelData.kind === "gap"
                                anchors.centerIn: parent
                                width: 1
                                height: root.size * 0.7
                                color: Qt.alpha(Theme.text, 0.2)
                            }

                            Item {
                                id: tile
                                visible: slot.modelData.kind !== "gap"
                                anchors.fill: parent
                                scale: tileArea.pressed ? 0.9 : 1

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 120
                                    }
                                }

                                Item {
                                    anchors.fill: parent
                                    visible: slot.modelData.kind === "pad"

                                    Glass {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        radius: Tokens.radiusCard
                                        inner: true
                                        lit: root.padOpen
                                        offBorder: Theme.cardLine
                                    }

                                    Glyph {
                                        anchors.centerIn: parent
                                        text: Icons.GLYPHS.apps
                                        size: parent.height * 0.42
                                        color: root.padOpen ? Theme.onAccent : Theme.text
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    visible: slot.appItem !== null && icon.status !== Image.Ready
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
                                        text: slot.appItem === null ? "" : root.nameOf(slot.appItem.id).charAt(0).toUpperCase()
                                        color: Theme.onAccent
                                        font.family: Tokens.fontUi
                                        font.pixelSize: parent.height * 0.45
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Image {
                                    id: icon
                                    anchors.fill: parent
                                    visible: slot.appItem !== null
                                    source: Apps.icon(slot.appEntry)
                                    sourceSize.width: root.size * 3
                                    sourceSize.height: root.size * 3
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    smooth: true
                                    mipmap: true
                                }

                                MouseArea {
                                    id: tileArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                    onClicked: mouse => {
                                        if (slot.modelData.kind === "pad") {
                                            root.request("pad", "", deck.modelData);
                                        } else if (mouse.button === Qt.RightButton) {
                                            menu.popupFor(slot);
                                        } else if (mouse.button === Qt.MiddleButton) {
                                            Apps.launch(slot.appEntry);
                                        } else {
                                            root.click(slot.appItem);
                                        }
                                    }
                                }
                            }

                            Row {
                                visible: slot.appItem !== null && slot.appItem.windows.length > 0
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.bottom
                                anchors.topMargin: 2
                                spacing: 3

                                Repeater {
                                    model: slot.appItem === null ? 0 : Math.min(3, slot.appItem.windows.length)

                                    delegate: Rectangle {
                                        width: 4
                                        height: 4
                                        radius: 2
                                        color: slot.focused ? Theme.accent : Qt.alpha(Theme.text, 0.6)
                                    }
                                }
                            }

                            Item {
                                visible: tileArea.containsMouse && !menu.visible && slot.modelData.kind !== "gap"
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.top
                                anchors.bottomMargin: 10
                                width: tipText.implicitWidth + 22
                                height: 28

                                Glass {
                                    anchors.fill: parent
                                    radius: height / 2
                                    raised: true
                                    offColor: Theme.surface
                                    offBorder: Theme.line
                                }

                                Text {
                                    id: tipText
                                    anchors.centerIn: parent
                                    text: slot.modelData.kind === "pad" ? "Apps" : slot.appItem === null ? "" : root.nameOf(slot.appItem.id)
                                    color: Theme.text
                                    font.family: Tokens.fontUi
                                    font.pixelSize: Tokens.smallSize
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }
                }
            }

            PopupWindow {
                id: menu

                property var slot: null
                readonly property var appItem: menu.slot === null ? null : menu.slot.appItem
                readonly property var rows: menu.appItem === null ? [] : root.menuRows(menu.appItem)

                function popupFor(s: var): void {
                    menu.slot = s;
                    const p = s.mapToItem(null, s.width / 2, 0);
                    menu.anchor.rect.x = p.x - menu.implicitWidth / 2;
                    menu.anchor.rect.y = p.y - menu.implicitHeight - 12;
                    menu.visible = true;
                }

                anchor.window: deck
                implicitWidth: Tokens.deckMenuWidth
                implicitHeight: menuColumn.implicitHeight + 16
                color: "transparent"
                grabFocus: true

                Glass {
                    anchors.fill: parent
                    radius: Tokens.radiusCard
                    raised: true
                    offColor: Theme.surface
                    offBorder: Theme.line
                }

                Column {
                    id: menuColumn
                    x: 8
                    y: 8
                    width: parent.width - 16

                    Repeater {
                        model: menu.rows

                        delegate: Item {
                            required property var modelData
                            width: menuColumn.width
                            height: modelData.kind === "line" ? 9 : modelData.kind === "title" ? 30 : 34

                            Rectangle {
                                visible: modelData.kind === "line"
                                anchors.centerIn: parent
                                width: parent.width - 16
                                height: 1
                                color: Qt.alpha(Theme.text, 0.12)
                            }

                            Glass {
                                visible: modelData.kind === "action"
                                anchors.fill: parent
                                radius: Tokens.radiusRow - 4
                                inner: true
                                opacity: rowArea.containsMouse ? 1 : 0
                                offBorder: "transparent"
                            }

                            Glyph {
                                id: rowGlyph
                                visible: modelData.kind === "action" && modelData.glyph !== ""
                                x: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.glyph || ""
                                size: 15
                                color: Theme.accent
                            }

                            Text {
                                x: modelData.kind === "action" && modelData.glyph !== "" ? 38 : 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - x - 12
                                visible: modelData.kind !== "line"
                                text: modelData.text || ""
                                elide: Text.ElideRight
                                color: modelData.kind === "title" ? Theme.textDim : Theme.text
                                font.family: Tokens.fontUi
                                font.pixelSize: modelData.kind === "title" ? Tokens.tinySize : Tokens.smallSize
                                font.weight: modelData.kind === "title" ? Font.DemiBold : Font.Normal
                            }

                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                enabled: modelData.kind === "action"
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    menu.visible = false;
                                    modelData.run();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function menuRows(it: var): var {
        const rows = [
            {
                kind: "title",
                text: root.nameOf(it.id).toUpperCase()
            }
        ];
        for (const i of it.windows) {
            const w = root.windows[i];
            rows.push({
                kind: "action",
                glyph: "",
                text: w.title || w.appId,
                run: () => Compositor.activate(w)
            });
        }
        if (it.windows.length > 0)
            rows.push({
                kind: "line"
            });
        const e = root.entry(it.id);
        if (e)
            rows.push({
                kind: "action",
                glyph: Icons.GLYPHS.newWindow,
                text: it.windows.length > 0 ? "New window" : "Open",
                run: () => Apps.launch(e)
            });
        rows.push({
            kind: "action",
            glyph: it.pinned ? Icons.GLYPHS.pinOff : Icons.GLYPHS.pin,
            text: it.pinned ? "Remove from Deck" : "Keep in Deck",
            run: () => root.pin(it.id)
        });
        if (it.windows.length > 0)
            rows.push({
                kind: "action",
                glyph: Icons.GLYPHS.close,
                text: it.windows.length > 1 ? "Close " + it.windows.length + " windows" : "Close",
                run: () => it.windows.map(i => root.windows[i]).forEach(w => Compositor.closeWindow(w))
            });
        return rows;
    }
}
