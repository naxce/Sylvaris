pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../lib/diver.mjs" as D
import "../lib/plan.mjs" as P

Singleton {
    id: root

    readonly property var cfg: Settings.values.diver
    readonly property string helper: Qt.resolvedUrl("../helpers/diver.py").toString().replace("file://", "")
    readonly property string tonePath: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/sylvaris/diver-alarm.wav"
    property bool paired: false
    property var data: []
    property real version: 0
    property string synced: "[]"
    property bool dirty: false
    property bool pushAgain: false
    property int retries: 0
    property string error: ""
    property real lastSync: 0
    property real lastCheck: Date.now()
    property real now: Date.now()
    property var fired: ({})
    property var alarm: null
    property string focusId: ""
    property string focusTitle: ""
    property real focusEnd: 0
    property int focusMinutes: 0
    readonly property bool active: root.cfg.enabled && (root.paired || Demo.enabled)
    readonly property string today: D.dayKey(root.now)
    readonly property var agendaToday: root.agenda(root.today)
    readonly property var next: {
        for (const x of root.agendaToday) {
            if (!x.allDay && x.start + 15 * 60000 >= root.now)
                return x;
        }
        return null;
    }

    signal pairFinished(bool ok, string message)

    function agenda(day: string): var {
        return root.active ? D.agenda(root.data, day) : [];
    }

    function busy(year: int, month: int): var {
        return root.active && root.cfg.calendar ? D.busyDays(root.data, year, month) : ({});
    }

    function find(id: string): var {
        return D.find(root.data, id);
    }

    function plain(text: string): string {
        return D.plain(text);
    }

    function sync(): void {
        if (Demo.enabled || !root.paired || pullProc.running)
            return;
        pullProc.running = true;
    }

    function pair(code: string): void {
        if (code.trim() === "")
            throw new Error("usage: diver pair <code from diver settings>");
        pairProc.command = ["python3", root.helper, "pair", code.trim()];
        pairProc.running = true;
    }

    function unpair(): void {
        Quickshell.execDetached(["python3", root.helper, "unpair"]);
        root.paired = false;
        root.data = [];
        root.synced = "[]";
        root.version = 0;
    }

    function mutate(fn: var): void {
        const next = JSON.parse(JSON.stringify(root.data));
        fn(next);
        root.data = next;
        root.dirty = true;
        root.push();
    }

    function replace(id: string, fn: var): bool {
        let ok = false;
        root.mutate(d => {
            const hit = D.find(d, id);
            if (hit === null)
                return;
            const list = d[hit.ci].groups[hit.gi].subs[hit.si].dives;
            list[hit.ti] = Object.assign({}, fn(Object.assign({}, list[hit.ti])), {
                updatedAt: Date.now()
            });
            ok = true;
        });
        return ok;
    }

    function add(text: string, day: string): var {
        const q = D.quick(text, Date.now());
        const task = {
            id: D.uid(),
            text: q.text || text.trim(),
            done: false,
            createdAt: Date.now(),
            updatedAt: Date.now()
        };
        const due = day !== "" && !q.rule ? day : q.due;
        if (due)
            task.due = due;
        if (q.rule) {
            task.rule = q.rule;
            if (D.legacy(q.rule) !== "none")
                task.repeat = D.legacy(q.rule);
        }
        if (q.time) {
            task.time = q.time;
            task.remind = [0];
        }
        root.mutate(d => {
            let c = d.find(x => x.inbox === true);
            if (!c) {
                c = {
                    id: D.uid(),
                    name: "inbox",
                    open: true,
                    inbox: true,
                    groups: []
                };
                d.unshift(c);
            }
            if (!c.groups[0])
                c.groups.push({
                    id: D.uid(),
                    name: "inbox",
                    open: true,
                    subs: []
                });
            if (!c.groups[0].subs[0])
                c.groups[0].subs.push({
                    id: D.uid(),
                    name: "inbox",
                    open: true,
                    dives: []
                });
            c.groups[0].subs[0].dives.push(task);
        });
        return task;
    }

    function done(id: string): void {
        if (!root.replace(id, t => D.complete(t, true, Date.now())))
            throw new Error("no task with id " + id);
        if (root.alarm !== null && root.alarm.id === id)
            root.alarm = null;
    }

    function snooze(id: string, minutes: int): void {
        const m = Math.max(1, Math.min(240, minutes || 10));
        if (!root.replace(id, t => Object.assign(t, {
                snoozedUntil: Date.now() + m * 60000
            })))
            throw new Error("no task with id " + id);
        if (root.alarm !== null && root.alarm.id === id)
            root.alarm = null;
    }

    function dismiss(): void {
        root.alarm = null;
    }

    function saveDraft(draft: var): var {
        let task = null;
        root.mutate(d => {
            task = P.saveTask(d, draft, Date.now()).task;
        });
        return task;
    }

    function remove(id: string): void {
        root.mutate(d => P.deleteTask(d, id));
        if (root.focusId === id)
            root.stopFocus();
    }

    function setDone(id: string, done: bool): void {
        root.mutate(d => P.setDone(d, id, done, Date.now()));
        if (done && root.alarm !== null && root.alarm.id === id)
            root.alarm = null;
    }

    function addNode(path: string, name: string): void {
        root.mutate(d => P.addNode(d, path, name));
    }

    function renameNode(path: string, name: string): void {
        root.mutate(d => P.renameNode(d, path, name));
    }

    function removeNode(path: string): void {
        root.mutate(d => P.removeNode(d, path));
    }

    function draftFor(id: string): var {
        const hit = D.find(root.data, id);
        if (hit === null)
            throw new Error("no task with id " + id);
        return P.draftOf(hit.task, hit.ci + "-" + hit.gi + "-" + hit.si);
    }

    function setField(id: string, field: string, value: string): var {
        if (field === "done") {
            root.setDone(id, ["on", "true", "yes", "1"].indexOf(value) >= 0);
            return D.find(root.data, id).task;
        }
        return root.saveDraft(P.applyField(root.draftFor(id), field, value, Date.now()));
    }

    function move(id: string, where: string): var {
        if (where !== "inbox" && !P.places(root.data).some(p => p.key === where))
            throw new Error("no list " + where + "; see sylvaris diver lists");
        return root.saveDraft(Object.assign(root.draftFor(id), {
            where: where
        }));
    }

    function lists(): var {
        return P.places(root.data);
    }

    function listOp(verb: string, where: string, name: string): void {
        const path = ["-", "root", "\"\""].indexOf(where) >= 0 ? "" : where;
        if (verb === "add")
            root.addNode(path, name);
        else if (verb === "rename")
            root.renameNode(path, name);
        else if (verb === "remove")
            root.removeNode(path);
        else
            throw new Error("usage: diver list add|rename|remove <path> [name]; paths look like 0, 0-1 or 0-1-2, and add with path - makes a category");
    }

    function startFocus(id: string, minutes: int): void {
        const hit = D.find(root.data, id);
        if (hit === null)
            throw new Error("no task with id " + id);
        root.focusMinutes = Math.max(1, Math.min(240, minutes || 25));
        root.focusId = id;
        root.focusTitle = D.plain(hit.task.text);
        root.focusEnd = Date.now() + root.focusMinutes * 60000;
    }

    function stopFocus(): void {
        root.focusId = "";
        root.focusTitle = "";
        root.focusEnd = 0;
    }

    function finishFocus(): void {
        const title = root.focusTitle;
        const minutes = root.focusMinutes;
        root.stopFocus();
        if (!Demo.enabled && root.cfg.notify)
            Quickshell.execDetached(["notify-send", "-a", "Diver", "Focus finished", minutes + " min on " + title]);
    }

    function push(): void {
        if (Demo.enabled || !root.paired)
            return;
        if (pushProc.running) {
            root.pushAgain = true;
            return;
        }
        pushProc.body = JSON.stringify({
            data: root.data,
            base: root.version
        });
        pushProc.running = true;
    }

    function ingest(text: string): void {
        let j;
        try {
            j = JSON.parse(text);
        } catch (e) {
            root.error = "The Diver helper did not answer";
            return;
        }
        if (!j.ok) {
            root.error = j.error || "Diver is unreachable";
            if (j.paired === false)
                root.paired = false;
            return;
        }
        const remote = D.migrate(j.data);
        root.data = root.dirty ? D.merge3(JSON.parse(root.synced), root.data, remote) : remote;
        root.version = j.version;
        root.synced = JSON.stringify(remote);
        root.error = "";
        root.lastSync = Date.now();
        if (root.dirty)
            root.push();
    }

    function check(): void {
        root.now = Date.now();
        if (!root.active)
            return;
        const from = Math.max(root.lastCheck, root.now - 10 * 60000);
        root.lastCheck = root.now + 1;
        const next = Object.assign({}, root.fired);
        for (const r of D.reminders(root.data, from, root.now)) {
            if (next[r.rid])
                continue;
            next[r.rid] = true;
            if (root.cfg.alarms && (r.alarm || r.before === 0)) {
                root.alarm = r;
            } else if (root.cfg.notify) {
                const when = r.before > 0 ? "in " + r.before + " min · " : "";
                Quickshell.execDetached(["notify-send", "-a", "Diver", "-u", r.alarm ? "critical" : "normal", r.title, when + Qt.formatTime(new Date(r.start), "HH:mm") + (r.path !== "" ? " · " + r.path : "")]);
            }
        }
        root.fired = next;
    }

    function state(): var {
        return {
            enabled: root.cfg.enabled,
            paired: root.paired,
            error: root.error,
            version: root.version,
            lastSync: root.lastSync,
            tasks: D.tasks(root.data).length,
            today: root.agendaToday.map(x => ({
                        id: x.task.id,
                        text: D.plain(x.task.text),
                        start: x.allDay ? null : Qt.formatTime(new Date(x.start), "HH:mm")
                    })),
            next: root.next === null ? null : {
                id: root.next.task.id,
                text: D.plain(root.next.task.text),
                start: Qt.formatTime(new Date(root.next.start), "HH:mm")
            },
            alarm: root.alarm,
            focus: root.focusEnd > 0 ? {
                id: root.focusId,
                title: root.focusTitle,
                left: Math.max(0, Math.round((root.focusEnd - Date.now()) / 1000))
            } : null
        };
    }

    function demo(): var {
        const day = D.dayKey(Date.now());
        const tomorrow = D.dayKey(Date.now() + 86400000);
        return [
            {
                id: "d1",
                name: "Life",
                open: true,
                groups: [
                    {
                        id: "d2",
                        name: "home",
                        open: true,
                        subs: [
                            {
                                id: "d3",
                                name: "chores",
                                open: true,
                                dives: [
                                    {
                                        id: "t1",
                                        text: "Take meds",
                                        done: false,
                                        due: day,
                                        time: "09:00",
                                        repeat: "daily",
                                        alarm: true,
                                        remind: [0]
                                    },
                                    {
                                        id: "t2",
                                        text: "Call the dentist",
                                        done: false,
                                        due: day,
                                        time: "17:30",
                                        remind: [10, 0]
                                    },
                                    {
                                        id: "t3",
                                        text: "Laundry",
                                        done: false,
                                        due: day
                                    },
                                    {
                                        id: "t4",
                                        text: "Gym",
                                        done: false,
                                        due: tomorrow,
                                        time: "07:30"
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }
        ];
    }

    onAlarmChanged: {
        if (root.alarm !== null && root.alarm.alarm && root.cfg.sound && !Demo.enabled) {
            sound.running = false;
            sound.running = true;
        } else {
            sound.running = false;
        }
    }

    Component.onCompleted: {
        if (Demo.enabled) {
            root.data = root.demo();
            return;
        }
        statusProc.running = true;
        toneProc.running = true;
    }

    Timer {
        interval: Math.max(0, root.focusEnd - Date.now())
        running: root.focusEnd > 0
        onTriggered: root.finishFocus()
    }

    Timer {
        interval: 20000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }

    Timer {
        interval: Math.max(1, root.cfg.refresh) * 60000
        running: root.active && !Demo.enabled
        repeat: true
        onTriggered: root.sync()
    }

    Process {
        id: statusProc
        command: ["python3", root.helper, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.paired = JSON.parse(text).paired === true;
                } catch (e) {
                    root.paired = false;
                }
                if (root.paired)
                    root.sync();
            }
        }
    }

    Process {
        id: pullProc
        command: ["python3", root.helper, "pull"]
        stdout: StdioCollector {
            onStreamFinished: root.ingest(text)
        }
    }

    Process {
        id: pushProc
        property string body: ""
        command: ["python3", root.helper, "push"]
        stdinEnabled: true
        onStarted: {
            write(pushProc.body);
            stdinEnabled = false;
        }
        onExited: stdinEnabled = true
        stdout: StdioCollector {
            onStreamFinished: {
                let j = null;
                try {
                    j = JSON.parse(text);
                } catch (e) {}
                if (j !== null && j.ok) {
                    root.version = j.version;
                    root.synced = JSON.stringify(JSON.parse(pushProc.body).data);
                    root.dirty = root.pushAgain;
                    root.retries = 0;
                    root.error = "";
                    root.lastSync = Date.now();
                } else if (j !== null && j.conflict && root.retries < 3) {
                    root.retries++;
                    root.sync();
                    return;
                } else {
                    root.error = j !== null && j.error ? j.error : "Could not save to Diver";
                }
                if (root.pushAgain) {
                    root.pushAgain = false;
                    root.push();
                }
            }
        }
    }

    Process {
        id: pairProc
        stdout: StdioCollector {
            onStreamFinished: {
                let j = null;
                try {
                    j = JSON.parse(text);
                } catch (e) {}
                const ok = j !== null && j.ok === true;
                root.paired = ok;
                root.error = ok ? "" : j !== null && j.error ? j.error : "Pairing failed";
                root.pairFinished(ok, ok ? "Paired with " + j.url + ", " + j.tasks + " tasks" : root.error);
                if (ok)
                    root.sync();
            }
        }
    }

    Process {
        id: toneProc
        command: ["sh", "-c", "[ -f \"$2\" ] || python3 \"$1\" tone \"$2\"", "sylvaris-diver", root.helper, root.tonePath]
    }

    Process {
        id: sound
        command: ["sh", "-c", "end=$(( $(date +%s) + 120 )); while [ $(date +%s) -lt $end ]; do pw-play \"$1\" || exit 0; sleep 0.3; done", "sylvaris-diver", root.tonePath]
    }
}
