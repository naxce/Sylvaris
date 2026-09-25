import QtQuick
import qs
import qs.services
import qs.components
import qs.settings
import "../lib/icons.mjs" as Icons

Popup {
    id: root

    property string view: "today"
    property string problem: ""
    property real tick: Date.now()
    readonly property bool editing: sheet.open

    namespace: "syldiver-panel"
    corner: "center"
    panelWidth: Tokens.diverWidth
    panelHeight: Tokens.diverHeight
    dim: 0.3

    function setView(v: string): void {
        if (["today", "calendar", "lists"].indexOf(v) < 0)
            throw new Error("usage: diver view <today|calendar|lists>");
        root.view = v;
    }

    function edit(id: string, where: string): void {
        const hit = Diver.find(id);
        if (hit === null)
            throw new Error("no task with id " + id);
        sheet.show(hit.task, where || hit.ci + "-" + hit.gi + "-" + hit.si, "", "");
    }

    function showDay(day: string): void {
        root.view = "calendar";
        if (day === "")
            return;
        const d = new Date(day + "T12:00:00");
        calendar.year = d.getFullYear();
        calendar.month = d.getMonth();
        calendar.day = day;
    }

    function create(text: string, where: string, day: string): void {
        sheet.show(null, where || "inbox", text || "", day || "");
    }

    function fail(message: string): void {
        root.problem = message;
        problemTimer.restart();
    }

    function focusTask(id: string): void {
        try {
            Diver.startFocus(id, 25);
        } catch (e) {
            root.fail(e.message);
        }
    }

    onOpened: body.forceActiveFocus()

    Timer {
        id: problemTimer
        interval: 4000
        onTriggered: root.problem = ""
    }

    Timer {
        interval: 1000
        running: root.shown && Diver.focusEnd > 0
        repeat: true
        onTriggered: root.tick = Date.now()
    }

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: 26
        focus: true

        Keys.onEscapePressed: event => {
            if (sheet.open)
                sheet.tryClose();
            else
                root.close();
            event.accepted = true;
        }
        Keys.onPressed: event => {
            if (!(event.modifiers & Qt.ControlModifier) || sheet.open)
                return;
            if (event.key === Qt.Key_1)
                root.view = "today";
            else if (event.key === Qt.Key_2)
                root.view = "calendar";
            else if (event.key === Qt.Key_3)
                root.view = "lists";
            else if (event.key === Qt.Key_N)
                root.create("", "", "");
            else
                return;
            event.accepted = true;
        }

        Row {
            id: head
            width: parent.width
            height: 40
            spacing: 16

            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.GLYPHS.planner
                size: 22
                color: Theme.accent
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Diver"
                color: Theme.text
                font.family: Tokens.fontUi
                font.pixelSize: Tokens.titleSize + 3
                font.weight: Font.DemiBold
            }

            Segmented {
                width: 330
                anchors.verticalCenter: parent.verticalCenter
                options: [
                    {
                        key: "today",
                        label: "Today"
                    },
                    {
                        key: "calendar",
                        label: "Calendar"
                    },
                    {
                        key: "lists",
                        label: "Lists"
                    }
                ]
                current: root.view
                onPicked: key => root.view = key
            }

            Chip {
                anchors.verticalCenter: parent.verticalCenter
                text: "Details"
                glyph: Icons.GLYPHS.pencil
                onClicked: root.create("", "", "")
            }
        }

        Text {
            anchors.right: closeGlyph.left
            anchors.rightMargin: 14
            anchors.verticalCenter: head.verticalCenter
            text: Demo.enabled ? "demo" : !Diver.paired ? "not paired · SylSettings › Diver" : Diver.error !== "" ? "sync problem · " + Diver.error : Diver.dirty ? "saving…" : "synced"
            color: Diver.error !== "" || !Diver.paired && !Demo.enabled ? Theme.danger : Theme.textDim
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.tinySize
        }

        Glyph {
            id: closeGlyph
            anchors.right: parent.right
            anchors.verticalCenter: head.verticalCenter
            text: Icons.GLYPHS.close
            size: 20
            color: closeArea.containsMouse ? Theme.text : Theme.textDim

            MouseArea {
                id: closeArea
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
            }
        }

        Item {
            id: focusBar
            anchors.top: head.bottom
            anchors.topMargin: Diver.focusEnd > 0 ? 18 : 0
            width: parent.width
            height: Diver.focusEnd > 0 ? 44 : 0
            visible: Diver.focusEnd > 0
            readonly property int secondsLeft: Math.max(0, Math.round((Diver.focusEnd - root.tick) / 1000))

            Glass {
                anchors.fill: parent
                radius: Tokens.radiusRow
                inner: true
                lit: true
            }

            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                height: 3
                radius: 1.5
                width: parent.width * (1 - focusBar.secondsLeft / Math.max(1, Diver.focusMinutes * 60))
                color: Theme.onAccent
                opacity: 0.6
            }

            Glyph {
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.GLYPHS.target
                size: 18
                color: Theme.onAccent
            }

            Text {
                x: 44
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 200
                text: "Focusing on " + Diver.focusTitle
                elide: Text.ElideRight
                color: Theme.onAccent
                font.family: Tokens.fontUi
                font.pixelSize: Tokens.smallSize
                font.weight: Font.Medium
            }

            Text {
                anchors.right: stopGlyph.left
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: Math.floor(focusBar.secondsLeft / 60) + ":" + String(focusBar.secondsLeft % 60).padStart(2, "0")
                color: Theme.onAccent
                font.family: Tokens.fontMono
                font.pixelSize: Tokens.bodySize
            }

            Glyph {
                id: stopGlyph
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.GLYPHS.close
                size: 16
                color: Theme.onAccent

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Diver.stopFocus()
                }
            }
        }

        Item {
            id: stage
            anchors.top: focusBar.bottom
            anchors.topMargin: 18
            anchors.bottom: problemText.top
            anchors.bottomMargin: 6
            width: parent.width

            DiverToday {
                anchors.fill: parent
                visible: root.view === "today"
                onEdit: (id, where) => root.edit(id, where)
                onFocusTask: id => root.focusTask(id)
            }

            DiverCalendar {
                id: calendar
                anchors.fill: parent
                visible: root.view === "calendar"
                onEdit: (id, where) => root.edit(id, where)
                onCreate: (text, day) => root.create(text, "", day)
                onFocusTask: id => root.focusTask(id)
            }

            DiverLists {
                anchors.fill: parent
                visible: root.view === "lists"
                onEdit: (id, where) => root.edit(id, where)
                onCreate: (text, where) => root.create(text, where, "")
                onFocusTask: id => root.focusTask(id)
                onFailed: message => root.fail(message)
            }
        }

        Text {
            id: problemText
            anchors.bottom: parent.bottom
            width: parent.width
            height: root.problem === "" ? 0 : implicitHeight
            text: root.problem
            color: Theme.danger
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.smallSize
        }

        DiverSheet {
            id: sheet
            anchors.fill: parent
            anchors.margins: -14
            onClosed: body.forceActiveFocus()
        }
    }
}
