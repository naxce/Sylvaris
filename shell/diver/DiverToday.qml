import QtQuick
import qs
import qs.services
import "../lib/diver.mjs" as D
import "../lib/plan.mjs" as P

Flickable {
    id: root

    readonly property var overdue: D.overdue(Diver.data, Diver.now)
    readonly property var upcoming: {
        const out = [];
        const seen = {};
        for (let i = 1; i <= 7; i++)
            for (const x of Diver.agenda(D.dayKey(Diver.now + i * D.DAY))) {
                if (seen[x.task.id] || Diver.agendaToday.some(y => y.task.id === x.task.id))
                    continue;
                seen[x.task.id] = true;
                out.push(x);
            }
        return out;
    }
    readonly property var sections: [
        {
            title: "Overdue",
            items: root.overdue,
            day: true
        },
        {
            title: "Today",
            items: Diver.agendaToday,
            day: false
        },
        {
            title: "Next 7 days",
            items: root.upcoming,
            day: true
        }
    ]

    signal edit(string id, string where)
    signal focusTask(string id)

    function whenOf(x: var, day: bool): string {
        const time = x.allDay || !x.task.time ? "" : Qt.formatTime(new Date(x.start || D.at(x.task.due, x.task.time)), "HH:mm");
        const date = day ? P.dayLabel(x.start ? D.dayKey(x.start) : x.task.due) : "";
        return [date, time].filter(Boolean).join(" ");
    }

    contentHeight: col.implicitHeight + 20
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: col
        width: root.width
        spacing: 8

        Text {
            visible: root.overdue.length === 0 && Diver.agendaToday.length === 0 && root.upcoming.length === 0
            width: parent.width
            topPadding: 40
            horizontalAlignment: Text.AlignHCenter
            text: "Nothing planned for the next week.\nType above to add something, like “call Ana tomorrow 18:00”."
            color: Theme.textDim
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.bodySize
            lineHeight: 1.3
        }

        Repeater {
            model: root.sections

            delegate: Column {
                id: sec
                required property var modelData
                width: col.width
                spacing: 6
                visible: sec.modelData.items.length > 0

                Text {
                    topPadding: 8
                    text: sec.modelData.title + "  " + sec.modelData.items.length
                    color: sec.modelData.title === "Overdue" ? Theme.danger : Theme.textDim
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.tinySize
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }

                Repeater {
                    model: sec.modelData.items

                    delegate: DiverTaskRow {
                        required property var modelData
                        width: sec.width
                        task: modelData.task
                        when: root.whenOf(modelData, sec.modelData.day)
                        path: modelData.path.filter(Boolean).join(" › ")
                        showPath: true
                        onOpen: root.edit(modelData.task.id, modelData.ci + "-" + modelData.gi + "-" + modelData.si)
                        onFocusRequested: root.focusTask(modelData.task.id)
                    }
                }
            }
        }
    }
}
