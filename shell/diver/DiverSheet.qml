import QtQuick
import qs
import qs.services
import qs.components
import qs.settings
import "../lib/diver.mjs" as D
import "../lib/plan.mjs" as P
import "../lib/icons.mjs" as Icons

Item {
    id: root

    property var draft: null
    property string initial: ""
    property bool asking: false
    property bool armedDelete: false
    property bool picking: false
    property bool notesOpen: false
    property string error: ""
    readonly property bool open: root.draft !== null
    readonly property string preset: root.draft ? P.presetOf(root.draft.rule) : "none"
    readonly property bool custom: root.draft !== null && root.draft.rule !== null && (root.preset === "custom" || root.draft.rule.custom === true)
    readonly property var parsed: root.draft ? D.quick(root.draft.title, Diver.now) : null
    readonly property string parsedText: {
        const q = root.parsed;
        if (!q || !q.text || q.text === root.draft.title.trim())
            return "";
        return [q.due ? P.dayLabel(q.due) : "", q.time || "", q.rule ? "↻ " + P.ruleText(q.rule) : ""].filter(Boolean).join(" · ");
    }
    readonly property var places: P.places(Diver.data)
    readonly property string placeLabel: {
        const hit = root.places.find(p => root.draft && p.key === root.draft.where);
        return hit ? hit.label : "inbox";
    }

    signal closed

    function snapshot(): string {
        return JSON.stringify(root.draft);
    }

    function show(task: var, where: string, text: string, day: string): void {
        const d = P.draftOf(task, where || "inbox");
        if (!task && text && text.trim() !== "") {
            const q = D.quick(text, Date.now());
            d.title = q.text || text.trim();
            if (q.due)
                d.due = q.due;
            if (q.time)
                d.time = q.time;
            if (q.rule) {
                d.rule = q.rule;
                d.ends = q.rule.until ? "on" : "never";
            }
        }
        if (!task && day && !d.rule)
            d.due = day;
        root.draft = d;
        root.initial = root.snapshot();
        root.asking = false;
        root.armedDelete = false;
        root.picking = false;
        root.notesOpen = d.notes !== "";
        root.error = "";
        titleBox.text = d.title;
        notesEdit.text = d.notes;
        startBox.text = d.time;
        endBox.text = d.end;
        untilBox.text = d.rule && d.rule.until ? d.rule.until : "";
        titleBox.focusInput();
    }

    function patch(obj: var): void {
        root.draft = Object.assign({}, root.draft, obj);
    }

    function patchRule(obj: var): void {
        root.patch({
            rule: Object.assign({}, root.draft.rule, obj)
        });
    }

    function tryClose(): bool {
        if (!root.open)
            return true;
        if (root.snapshot() === root.initial) {
            root.finish();
            return true;
        }
        root.asking = true;
        return false;
    }

    function finish(): void {
        root.draft = null;
        root.asking = false;
        root.closed();
    }

    function save(): void {
        try {
            const d = Object.assign({}, root.draft);
            if (d.rule)
                d.rule = Object.assign({}, d.rule);
            Diver.saveDraft(d);
            root.finish();
        } catch (e) {
            root.error = e.message;
            titleBox.focusInput();
        }
    }

    function setPreset(key: string): void {
        const until = root.draft.rule && root.draft.rule.until;
        if (key === "none")
            root.patch({
                rule: null
            });
        else if (key === "custom")
            root.patch({
                rule: Object.assign({
                    every: 1,
                    unit: "week"
                }, root.draft.rule || {}, {
                    custom: true
                })
            });
        else
            root.patch({
                rule: Object.assign({}, P.PRESETS[key], until ? {
                    until: until
                } : {})
            });
    }

    function toggleDay(d: int): void {
        const days = (root.draft.rule.days || []).filter(x => x !== d);
        if (days.length === (root.draft.rule.days || []).length)
            days.push(d);
        const next = Object.assign({}, root.draft.rule);
        if (days.length)
            next.days = days.sort((a, b) => a - b);
        else
            delete next.days;
        root.patch({
            rule: next
        });
    }

    function toggleRemind(n: int): void {
        const list = root.draft.remind.filter(x => x !== n);
        if (list.length === root.draft.remind.length)
            list.push(n);
        root.patch({
            remind: list
        });
    }

    function applyParsed(): void {
        const q = root.parsed;
        const next = {
            title: q.text
        };
        if (q.due)
            next.due = q.due;
        if (q.time)
            next.time = q.time;
        if (q.rule) {
            next.rule = q.rule;
            next.ends = q.rule.until ? "on" : "never";
        }
        root.patch(next);
        titleBox.text = q.text;
        startBox.text = root.draft.time;
        untilBox.text = root.draft.rule && root.draft.rule.until ? root.draft.rule.until : "";
    }

    visible: root.open
    focus: root.open

    Keys.onEscapePressed: event => {
        root.tryClose();
        event.accepted = true;
    }
    Keys.onPressed: event => {
        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ControlModifier)) {
            root.save();
            event.accepted = true;
        }
    }

    component Label: Text {
        color: Theme.textDim
        font.family: Tokens.fontUi
        font.pixelSize: Tokens.tinySize
        font.weight: Font.DemiBold
        font.letterSpacing: 1
    }

    component Flow2: Flow {
        width: parent ? parent.width : 0
        spacing: 6
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.base, 0.6)

        MouseArea {
            anchors.fill: parent
            onClicked: root.tryClose()
        }
    }

    Item {
        id: card
        anchors.right: parent.right
        width: Math.min(560, parent.width)
        height: parent.height

        Glass {
            anchors.fill: parent
            radius: Tokens.radiusCard
            raised: true
        }

        MouseArea {
            anchors.fill: parent
        }

        Flickable {
            id: scroll
            anchors.fill: parent
            anchors.margins: 22
            anchors.bottomMargin: foot.height + 30
            contentHeight: form.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: form
                width: scroll.width
                spacing: 12

                Label {
                    text: root.draft && root.draft.isNew ? "NEW TASK" : "TASK"
                }

                TextBox {
                    id: titleBox
                    width: parent.width
                    placeholder: "What needs doing?"
                    border.width: root.error !== "" ? 1 : 0
                    border.color: Theme.danger
                    onTextChanged: {
                        if (root.open && root.draft.title !== text) {
                            root.patch({
                                title: text
                            });
                            root.error = "";
                        }
                    }
                    onAccepted: root.save()
                }

                Text {
                    visible: root.error !== ""
                    text: root.error
                    color: Theme.danger
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.tinySize
                }

                Chip {
                    visible: root.parsedText !== ""
                    text: "Use: " + root.parsedText
                    glyph: Icons.GLYPHS.check
                    onClicked: root.applyParsed()
                }

                Chip {
                    visible: !root.notesOpen
                    text: "Add notes"
                    glyph: Icons.GLYPHS.plus
                    onClicked: {
                        root.notesOpen = true;
                        notesEdit.forceActiveFocus();
                    }
                }

                Rectangle {
                    visible: root.notesOpen
                    width: parent.width
                    height: Math.max(80, notesEdit.contentHeight + 24)
                    radius: Tokens.radiusRow
                    color: "transparent"
                    border.width: notesEdit.activeFocus ? 1 : 0
                    border.color: Theme.accent

                    Glass {
                        anchors.fill: parent
                        z: -1
                        radius: parent.radius
                        inner: true
                        offColor: Theme.tintMid
                    }

                    TextEdit {
                        id: notesEdit
                        anchors.fill: parent
                        anchors.margins: 12
                        wrapMode: TextEdit.Wrap
                        color: Theme.text
                        selectionColor: Theme.fill
                        font.family: Tokens.fontUi
                        font.pixelSize: Tokens.smallSize
                        onTextChanged: {
                            if (root.open && root.draft.notes !== text)
                                root.patch({
                                    notes: text
                                });
                        }
                    }

                    Text {
                        anchors.fill: notesEdit
                        visible: notesEdit.text === ""
                        text: "Notes, links, markdown works"
                        color: Theme.textDim
                        font: notesEdit.font
                    }
                }

                Label {
                    text: "WHEN" + (root.draft && root.draft.due ? "  ·  " + P.dayLabel(root.draft.due) : "")
                }

                Flow2 {
                    Repeater {
                        model: [["Today", 0], ["Tomorrow", 1], ["Next week", 7], ["No date", -1]]

                        delegate: Chip {
                            required property var modelData
                            readonly property string key: modelData[1] < 0 ? "" : D.dayKey(Diver.now + modelData[1] * D.DAY)
                            text: modelData[0]
                            lit: root.draft !== null && root.draft.due === key
                            onClicked: root.patch({
                                due: key
                            })
                        }
                    }

                    TextBox {
                        id: dateBox
                        width: 170
                        height: 32
                        placeholder: "date, e.g. 12.10 or friday"
                        onAccepted: {
                            const t = dateBox.text.trim();
                            const q = D.quick(t + " 12:00", Diver.now);
                            const iso = D.parseDay(t) ? t : q.due;
                            if (iso) {
                                root.patch({
                                    due: iso
                                });
                                dateBox.text = "";
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 12

                    Column {
                        width: (parent.width - 12) / 2
                        spacing: 6

                        Label {
                            text: "STARTS"
                        }

                        TextBox {
                            id: startBox
                            width: parent.width
                            placeholder: "HH:MM"
                            onTextChanged: {
                                if (!root.open)
                                    return;
                                const v = text.trim();
                                if (v === "" || D.isTime(v))
                                    root.patch({
                                        time: v
                                    });
                            }
                        }
                    }

                    Column {
                        width: (parent.width - 12) / 2
                        spacing: 6

                        Label {
                            text: "ENDS AT"
                        }

                        TextBox {
                            id: endBox
                            width: parent.width
                            placeholder: "HH:MM"
                            onTextChanged: {
                                if (!root.open)
                                    return;
                                const v = text.trim();
                                if (v === "" || D.isTime(v))
                                    root.patch({
                                        end: v
                                    });
                            }
                        }
                    }
                }

                Label {
                    text: "REPEAT" + (root.draft && root.draft.rule ? "  ·  " + P.ruleText(root.draft.rule) : "")
                }

                Flow2 {
                    Repeater {
                        model: [["none", "Once"], ["daily", "Daily"], ["weekdays", "Weekdays"], ["weekly", "Weekly"], ["monthly", "Monthly"], ["yearly", "Yearly"], ["custom", "Custom"]]

                        delegate: Chip {
                            required property var modelData
                            text: modelData[1]
                            lit: modelData[0] === "custom" ? root.custom : !root.custom && root.preset === modelData[0]
                            onClicked: root.setPreset(modelData[0])
                        }
                    }
                }

                Row {
                    visible: root.custom
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "every"
                        color: Theme.textDim
                        font.family: Tokens.fontUi
                        font.pixelSize: Tokens.smallSize
                    }

                    Stepper {
                        anchors.verticalCenter: parent.verticalCenter
                        value: root.draft && root.draft.rule ? root.draft.rule.every : 1
                        from: 1
                        to: 99
                        onStepped: v => root.patchRule({
                            every: v
                        })
                    }

                    Segmented {
                        width: 300
                        anchors.verticalCenter: parent.verticalCenter
                        options: [
                            {
                                key: "day",
                                label: "days"
                            },
                            {
                                key: "week",
                                label: "weeks"
                            },
                            {
                                key: "month",
                                label: "months"
                            },
                            {
                                key: "year",
                                label: "years"
                            }
                        ]
                        current: root.draft && root.draft.rule ? root.draft.rule.unit : "week"
                        onPicked: key => {
                            const next = Object.assign({}, root.draft.rule, {
                                unit: key
                            });
                            if (key !== "week")
                                delete next.days;
                            root.patch({
                                rule: next
                            });
                        }
                    }
                }

                Flow2 {
                    visible: root.custom && root.draft.rule.unit === "week"

                    Repeater {
                        model: [[1, "Mon"], [2, "Tue"], [3, "Wed"], [4, "Thu"], [5, "Fri"], [6, "Sat"], [0, "Sun"]]

                        delegate: Chip {
                            required property var modelData
                            text: modelData[1]
                            lit: root.draft !== null && root.draft.rule !== null && (root.draft.rule.days || []).indexOf(modelData[0]) >= 0
                            onClicked: root.toggleDay(modelData[0])
                        }
                    }
                }

                Row {
                    visible: root.draft !== null && root.draft.rule !== null
                    width: parent.width
                    spacing: 10

                    Segmented {
                        width: 260
                        anchors.verticalCenter: parent.verticalCenter
                        options: [
                            {
                                key: "never",
                                label: "No end"
                            },
                            {
                                key: "on",
                                label: "Until"
                            },
                            {
                                key: "after",
                                label: "After"
                            }
                        ]
                        current: root.draft ? root.draft.ends : "never"
                        onPicked: key => root.patch({
                            ends: key
                        })
                    }

                    TextBox {
                        visible: root.draft !== null && root.draft.ends === "on"
                        width: 150
                        anchors.verticalCenter: parent.verticalCenter
                        id: untilBox
                        placeholder: "YYYY-MM-DD"
                        onTextChanged: {
                            if (root.open && root.draft.rule && D.parseDay(text.trim()))
                                root.patchRule({
                                    until: text.trim()
                                });
                        }
                    }

                    Stepper {
                        visible: root.draft !== null && root.draft.ends === "after"
                        anchors.verticalCenter: parent.verticalCenter
                        value: root.draft ? root.draft.count : 10
                        from: 1
                        to: 99
                        suffix: " times"
                        onStepped: v => root.patch({
                            count: v
                        })
                    }
                }

                Label {
                    text: "REMIND ME"
                }

                Text {
                    visible: root.draft !== null && !root.draft.time
                    text: "Set a start time to get reminders."
                    color: Theme.textDim
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.smallSize
                }

                Flow2 {
                    visible: root.draft !== null && root.draft.time !== ""

                    Repeater {
                        model: root.draft ? [0, 5, 10, 15, 30, 60, 1440].concat(root.draft.remind.filter(x => [0, 5, 10, 15, 30, 60, 1440].indexOf(x) < 0)) : []

                        delegate: Chip {
                            required property int modelData
                            text: modelData === 0 ? "At start" : modelData === 1440 ? "1 day before" : modelData + " min before"
                            lit: root.draft !== null && root.draft.remind.indexOf(modelData) >= 0
                            onClicked: root.toggleRemind(modelData)
                        }
                    }

                    TextBox {
                        id: minutesBox
                        width: 130
                        height: 32
                        placeholder: "other, min"
                        onAccepted: {
                            const n = Math.round(Number(minutesBox.text));
                            if (n >= 1 && n <= 10080 && root.draft.remind.indexOf(n) < 0)
                                root.patch({
                                    remind: root.draft.remind.concat([n])
                                });
                            minutesBox.text = "";
                        }
                    }
                }

                Row {
                    visible: root.draft !== null && root.draft.time !== ""
                    spacing: 10

                    Toggle {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: root.draft !== null && root.draft.alarm
                        onToggled: v => root.patch({
                            alarm: v
                        })
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Alarm · rings until you stop it"
                        color: Theme.text
                        font.family: Tokens.fontUi
                        font.pixelSize: Tokens.smallSize
                    }
                }

                Label {
                    text: "LIST"
                }

                Chip {
                    text: root.placeLabel
                    glyph: Icons.GLYPHS.listBulleted
                    lit: root.picking
                    onClicked: root.picking = !root.picking
                }

                Flow2 {
                    visible: root.picking

                    Repeater {
                        model: root.places

                        delegate: Chip {
                            required property var modelData
                            text: modelData.label
                            lit: root.draft !== null && root.draft.where === modelData.key
                            onClicked: {
                                root.patch({
                                    where: modelData.key
                                });
                                root.picking = false;
                            }
                        }
                    }
                }

                Label {
                    text: "PRIORITY"
                }

                Segmented {
                    width: Math.min(parent.width, 360)
                    options: [
                        {
                            key: "0",
                            label: "None"
                        },
                        {
                            key: "1",
                            label: "Low"
                        },
                        {
                            key: "2",
                            label: "Medium"
                        },
                        {
                            key: "3",
                            label: "High"
                        }
                    ]
                    current: root.draft ? String(root.draft.priority) : "0"
                    onPicked: key => root.patch({
                        priority: Number(key)
                    })
                }

                Label {
                    text: "ENERGY IT NEEDS"
                }

                Segmented {
                    width: Math.min(parent.width, 360)
                    options: [
                        {
                            key: "",
                            label: "Any"
                        },
                        {
                            key: "low",
                            label: "Low"
                        },
                        {
                            key: "med",
                            label: "Medium"
                        },
                        {
                            key: "high",
                            label: "High"
                        }
                    ]
                    current: root.draft ? root.draft.energy : ""
                    onPicked: key => root.patch({
                        energy: key
                    })
                }

                Label {
                    text: "TAKES ABOUT"
                }

                Flow2 {
                    Repeater {
                        model: [[0, "—"], [5, "5 min"], [15, "15 min"], [25, "25 min"], [45, "45 min"], [60, "1 h"], [90, "1.5 h"]]

                        delegate: Chip {
                            required property var modelData
                            text: modelData[1]
                            lit: root.draft !== null && root.draft.estimate === modelData[0]
                            onClicked: root.patch({
                                estimate: modelData[0]
                            })
                        }
                    }
                }

                Label {
                    text: "STEPS"
                }

                Repeater {
                    model: root.draft ? root.draft.subtasks : []

                    delegate: Row {
                        id: stepRow
                        required property var modelData
                        required property int index
                        spacing: 10

                        Glyph {
                            text: stepRow.modelData.done ? Icons.GLYPHS.boxChecked : Icons.GLYPHS.boxEmpty
                            size: 18
                            color: Theme.accent

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const list = JSON.parse(JSON.stringify(root.draft.subtasks));
                                    list[stepRow.index].done = !list[stepRow.index].done;
                                    root.patch({
                                        subtasks: list
                                    });
                                }
                            }
                        }

                        Text {
                            width: form.width - 70
                            text: stepRow.modelData.text
                            elide: Text.ElideRight
                            color: Theme.text
                            font.family: Tokens.fontUi
                            font.pixelSize: Tokens.smallSize
                        }

                        Glyph {
                            text: Icons.GLYPHS.close
                            size: 14
                            color: Theme.textDim

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.patch({
                                    subtasks: root.draft.subtasks.filter((s, i) => i !== stepRow.index)
                                })
                            }
                        }
                    }
                }

                TextBox {
                    id: stepBox
                    width: parent.width
                    placeholder: "Add a small step…"
                    onAccepted: {
                        if (stepBox.text.trim() === "")
                            return;
                        root.patch({
                            subtasks: root.draft.subtasks.concat([
                                {
                                    id: D.uid(),
                                    text: stepBox.text.trim(),
                                    done: false
                                }
                            ])
                        });
                        stepBox.text = "";
                    }
                }
            }
        }

        Column {
            id: foot
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 22
            spacing: 10

            Row {
                visible: root.asking
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Discard your changes?"
                    color: Theme.danger
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.smallSize
                }

                Chip {
                    text: "Keep editing"
                    onClicked: {
                        root.asking = false;
                        titleBox.focusInput();
                    }
                }

                Chip {
                    text: "Discard"
                    glyph: Icons.GLYPHS.close
                    onClicked: root.finish()
                }
            }

            Item {
                width: parent.width
                height: 36

                Row {
                    spacing: 8

                    Chip {
                        visible: root.draft !== null && !root.draft.isNew
                        text: root.armedDelete ? "Really delete?" : "Delete"
                        glyph: Icons.GLYPHS.trash
                        lit: root.armedDelete
                        onClicked: {
                            if (!root.armedDelete) {
                                root.armedDelete = true;
                                return;
                            }
                            Diver.remove(root.draft.id);
                            root.finish();
                        }
                    }

                    Chip {
                        visible: root.draft !== null && !root.draft.isNew
                        text: "Focus 25 min"
                        glyph: Icons.GLYPHS.target
                        onClicked: {
                            const id = root.draft.id;
                            if (root.snapshot() !== root.initial) {
                                root.save();
                                if (root.open)
                                    return;
                            } else {
                                root.finish();
                            }
                            Diver.startFocus(id, 25);
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: 8

                    Chip {
                        text: "Cancel"
                        onClicked: root.tryClose()
                    }

                    Chip {
                        text: "Save"
                        glyph: Icons.GLYPHS.check
                        lit: true
                        onClicked: root.save()
                    }
                }
            }
        }
    }
}
