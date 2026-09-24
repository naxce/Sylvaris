import { test } from "node:test"
import assert from "node:assert/strict"
import { presetOf, ruleText, dayLabel, places, draftOf, saveTask, deleteTask, setDone, addNode, renameNode, removeNode, findNode } from "../shell/lib/plan.mjs"

const NOW = new Date(2026, 8, 24, 12).getTime()

function sample() {
    return [
        { id: "c1", name: "home", open: true, groups: [{ id: "g1", name: "general", open: true, subs: [{ id: "s1", name: "chores", open: true, dives: [{ id: "t1", text: "water plants\n- the big one", done: false, extra: 7 }] }, { id: "s2", name: "shop", open: true, dives: [] }] }] },
        { id: "c2", name: "work", open: true, groups: [] }
    ]
}

test("presetOf and ruleText describe rules", () => {
    assert.equal(presetOf(null), "none")
    assert.equal(presetOf({ every: 1, unit: "day" }), "daily")
    assert.equal(presetOf({ every: 1, unit: "week", days: [1, 2, 3, 4, 5], until: "2026-12-01" }), "weekdays")
    assert.equal(presetOf({ every: 1, unit: "year" }), "yearly")
    assert.equal(presetOf({ every: 2, unit: "week" }), "custom")
    assert.equal(ruleText({ every: 1, unit: "day" }), "every day")
    assert.equal(ruleText({ every: 2, unit: "week", days: [1, 4], until: "2026-11-30" }), "every 2 weeks · Mon, Thu · until Mon 30 Nov")
    assert.equal(ruleText({ every: 1, unit: "month" }), "every month")
    assert.equal(dayLabel("2026-09-24"), "Thu 24 Sep")
})

test("places lists every list with a readable path", () => {
    assert.deepEqual(places(sample()), [
        { key: "0-0-0", label: "home › general › chores" },
        { key: "0-0-1", label: "home › general › shop" }
    ])
})

test("draftOf splits text and reads legacy repeats", () => {
    const d = draftOf({ id: "t", text: "a\nb", due: "2026-09-24", repeat: "weekly", remind: [10] }, "0-0-0")
    assert.equal(d.title, "a")
    assert.equal(d.notes, "b")
    assert.deepEqual(d.rule, { every: 1, unit: "week" })
    assert.equal(d.ends, "never")
    assert.deepEqual(d.remind, [10])
    const n = draftOf(null, "inbox")
    assert.ok(n.id)
    assert.deepEqual(n.remind, [0])
    assert.equal(n.where, "inbox")
    assert.equal(draftOf({ id: "x", text: "y", rule: { every: 1, unit: "day", until: "2026-10-01" } }, "0-0-0").ends, "on")
})

test("saveTask creates, edits in place, moves and keeps unknown fields", () => {
    const data = sample()
    const edit = draftOf(data[0].groups[0].subs[0].dives[0], "0-0-0")
    edit.title = "water all plants"
    edit.time = "18:00"
    const r = saveTask(data, edit, NOW)
    assert.equal(r.task.text, "water all plants\n- the big one")
    assert.equal(r.task.extra, 7)
    assert.deepEqual(r.task.remind, [0])
    assert.equal(data[0].groups[0].subs[0].dives[0].text, "water all plants\n- the big one")

    const moved = Object.assign(draftOf(r.task, "0-0-0"), { where: "0-0-1" })
    saveTask(data, moved, NOW)
    assert.equal(data[0].groups[0].subs[0].dives.length, 0)
    assert.equal(data[0].groups[0].subs[1].dives[0].id, "t1")

    const fresh = Object.assign(draftOf(null, "inbox"), { title: "call mom", rule: { every: 2, unit: "week", days: [1, 4] }, ends: "after", count: 4 })
    const c = saveTask(data, fresh, NOW)
    assert.equal(data[0].inbox, true)
    assert.equal(data[0].groups[0].subs[0].dives[0].id, c.task.id)
    assert.equal(c.task.due, "2026-09-24")
    assert.equal(c.task.rule.until, "2026-10-19")
    assert.equal(c.task.repeat, undefined)
    assert.equal(c.task.remind, undefined)
    assert.equal(c.task.createdAt, NOW)

    const daily = Object.assign(draftOf(c.task, "0-0-0"), { rule: { every: 1, unit: "day" }, ends: "never" })
    assert.equal(saveTask(data, daily, NOW).task.repeat, "daily")
    assert.throws(() => saveTask(data, draftOf(null, "inbox"), NOW), /name/)
})

test("deleteTask and setDone", () => {
    const data = sample()
    setDone(data, "t1", true, NOW)
    assert.equal(data[0].groups[0].subs[0].dives[0].done, true)
    deleteTask(data, "t1")
    assert.equal(data[0].groups[0].subs[0].dives.length, 0)
    assert.throws(() => deleteTask(data, "nope"), /no task/)
})

test("list nodes can be added, renamed, found and removed", () => {
    const data = sample()
    addNode(data, "", "study")
    assert.equal(data[2].name, "study")
    assert.ok(data[2].id)
    addNode(data, "2", "maths")
    addNode(data, "2-0", "homework")
    assert.equal(data[2].groups[0].subs[0].name, "homework")
    assert.deepEqual(data[2].groups[0].subs[0].dives, [])
    renameNode(data, "2-0-0", "  exams ")
    assert.equal(data[2].groups[0].subs[0].name, "exams")
    assert.equal(findNode(data, "2-0").name, "maths")
    removeNode(data, "2-0")
    assert.deepEqual(data[2].groups, [])
    assert.throws(() => addNode(data, "", "  "), /name/)
    assert.throws(() => renameNode(data, "9", "x"), /no list/)
    assert.throws(() => addNode(data, "0-0-0", "x"), /no list/)
})

test("applyField sets any task field from text and rejects bad input", async () => {
    const { applyField } = await import("../shell/lib/plan.mjs")
    const d = draftOf({ id: "t", text: "x" }, "0-0-0")
    applyField(d, "title", "  buy milk ", NOW)
    assert.equal(d.title, "buy milk")
    applyField(d, "due", "2026-10-02", NOW)
    assert.equal(d.due, "2026-10-02")
    applyField(d, "due", "tomorrow", NOW)
    assert.equal(d.due, "2026-09-25")
    applyField(d, "due", "none", NOW)
    assert.equal(d.due, "")
    applyField(d, "time", "7:05", NOW)
    assert.equal(d.time, "07:05")
    applyField(d, "repeat", "weekly", NOW)
    assert.deepEqual(d.rule, { every: 1, unit: "week" })
    applyField(d, "repeat", "every 2 weeks on mon and thu", NOW)
    assert.deepEqual(d.rule, { every: 2, unit: "week", days: [1, 4] })
    applyField(d, "until", "2026-12-24", NOW)
    assert.equal(d.rule.until, "2026-12-24")
    assert.equal(d.ends, "on")
    applyField(d, "remind", "30, 0,10", NOW)
    assert.deepEqual(d.remind, [30, 0, 10])
    applyField(d, "alarm", "on", NOW)
    assert.equal(d.alarm, true)
    applyField(d, "priority", "high", NOW)
    assert.equal(d.priority, 3)
    applyField(d, "energy", "low", NOW)
    assert.equal(d.energy, "low")
    applyField(d, "estimate", "45", NOW)
    assert.equal(d.estimate, 45)
    applyField(d, "repeat", "none", NOW)
    assert.equal(d.rule, null)
    applyField(d, "notes", "line one", NOW)
    assert.equal(d.notes, "line one")
    for (const [f, v] of [["time", "25:00"], ["due", "someday"], ["repeat", "sometimes"], ["remind", "soon"], ["priority", "9"], ["energy", "huge"], ["estimate", "-4"], ["alarm", "maybe"], ["colour", "red"], ["title", " "], ["until", "2026-12-24"]])
        assert.throws(() => applyField(d, f, v, NOW), Error, f)
})
