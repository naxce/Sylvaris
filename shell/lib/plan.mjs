import * as D from "./diver.mjs"

const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

export const PRESETS = {
    daily: { every: 1, unit: "day" },
    weekdays: { every: 1, unit: "week", days: [1, 2, 3, 4, 5] },
    weekly: { every: 1, unit: "week" },
    monthly: { every: 1, unit: "month" },
    yearly: { every: 1, unit: "year" }
}

export function presetOf(rule) {
    if (!rule)
        return "none"
    const bare = JSON.stringify({ every: rule.every, unit: rule.unit, days: rule.days })
    return Object.keys(PRESETS).find(k => JSON.stringify({ every: PRESETS[k].every, unit: PRESETS[k].unit, days: PRESETS[k].days }) === bare) || "custom"
}

export function dayLabel(key) {
    const d = D.parseDay(key)
    return d ? WEEKDAYS[d.getDay()] + " " + d.getDate() + " " + MONTHS[d.getMonth()] : ""
}

export function ruleText(rule) {
    let out = rule.every === 1 ? "every " + rule.unit : "every " + rule.every + " " + rule.unit + "s"
    if (rule.days)
        out += " · " + rule.days.map(d => WEEKDAYS[d]).join(", ")
    if (rule.until)
        out += " · until " + dayLabel(rule.until)
    return out
}

export function places(data) {
    const out = []
    data.forEach((c, ci) => (c.groups || []).forEach((g, gi) => (g.subs || []).forEach((s, si) => out.push({
        key: ci + "-" + gi + "-" + si,
        label: [c.name, g.name, s.name].filter(Boolean).join(" › ")
    }))))
    return out
}

export function draftOf(task, where) {
    const t = task || { id: D.uid(), text: "", remind: [0] }
    const parts = D.splitText(t.text)
    const rule = D.ruleOf(t)
    return {
        id: t.id,
        isNew: !task,
        where: where,
        title: parts.title,
        notes: parts.notes,
        due: t.due || "",
        time: t.time || "",
        end: t.end || "",
        rule: rule,
        ends: rule && rule.until ? "on" : "never",
        count: 10,
        remind: (t.remind || [0]).slice(),
        alarm: t.alarm === true,
        priority: t.priority || 0,
        energy: t.energy || "",
        estimate: t.estimate || 0,
        subtasks: JSON.parse(JSON.stringify(t.subtasks || []))
    }
}

function inbox(data) {
    let c = data.find(x => x.inbox === true)
    if (!c) {
        c = { id: D.uid(), name: "inbox", open: true, inbox: true, groups: [] }
        data.unshift(c)
    }
    if (!c.groups[0])
        c.groups.push({ id: D.uid(), name: "inbox", open: true, subs: [] })
    if (!c.groups[0].subs[0])
        c.groups[0].subs.push({ id: D.uid(), name: "inbox", open: true, dives: [] })
    return c.groups[0].subs[0].dives
}

export function findNode(data, path) {
    const p = String(path).split("-").map(Number)
    let node = data[p[0]]
    if (node && p.length > 1)
        node = (node.groups || [])[p[1]]
    if (node && p.length > 2)
        node = (node.subs || [])[p[2]]
    if (!node || p.length > 3 || p.some(n => !Number.isInteger(n)))
        throw new Error("no list at " + path)
    return node
}

export function saveTask(data, draft, now) {
    const title = String(draft.title || "").trim()
    if (!title)
        throw new Error("give it a name first")
    const hit = D.find(data, draft.id)
    const base = hit ? Object.assign({}, hit.task) : { id: draft.id, done: false, createdAt: now }
    const out = Object.assign(base, { text: D.joinText(title, draft.notes), updatedAt: now })
    for (const k of ["due", "time", "end", "energy"])
        if (draft[k]) out[k] = draft[k]
        else delete out[k]
    for (const k of ["priority", "estimate"])
        if (draft[k]) out[k] = Number(draft[k])
        else delete out[k]
    if (draft.alarm) out.alarm = true
    else delete out.alarm
    delete out.rule
    delete out.repeat
    delete out.snoozedUntil
    if (draft.rule) {
        if (!out.due)
            out.due = D.dayKey(now)
        const rule = { every: draft.rule.every, unit: draft.rule.unit }
        if (draft.rule.unit === "week" && draft.rule.days && draft.rule.days.length)
            rule.days = draft.rule.days.slice()
        if (draft.ends === "on" && draft.rule.until)
            rule.until = draft.rule.until
        if (draft.ends === "after")
            rule.until = D.untilAfter(out.due, rule, Math.max(1, Math.round(draft.count || 1))) || undefined
        if (!rule.until)
            delete rule.until
        out.rule = rule
        if (D.legacy(rule) !== "none")
            out.repeat = D.legacy(rule)
    }
    if (out.time)
        out.remind = draft.remind.slice().sort((a, b) => b - a)
    else
        delete out.remind
    if (draft.subtasks.length)
        out.subtasks = draft.subtasks
    else
        delete out.subtasks
    const same = hit && draft.where === hit.ci + "-" + hit.gi + "-" + hit.si
    if (hit)
        data[hit.ci].groups[hit.gi].subs[hit.si].dives.splice(hit.ti, 1)
    const target = draft.where === "inbox" ? inbox(data) : findNode(data, draft.where).dives
    if (!target)
        throw new Error("no list at " + draft.where)
    if (same)
        target.splice(hit.ti, 0, out)
    else
        target.push(out)
    return { data: data, task: out }
}

export function deleteTask(data, id) {
    const hit = D.find(data, id)
    if (!hit)
        throw new Error("no task with id " + id)
    data[hit.ci].groups[hit.gi].subs[hit.si].dives.splice(hit.ti, 1)
    return data
}

export function setDone(data, id, done, now) {
    const hit = D.find(data, id)
    if (!hit)
        throw new Error("no task with id " + id)
    data[hit.ci].groups[hit.gi].subs[hit.si].dives[hit.ti] = D.complete(hit.task, done, now)
    return data
}

function cleanName(name) {
    const n = String(name || "").trim()
    if (!n)
        throw new Error("give it a name first")
    return n
}

export function addNode(data, path, name) {
    const n = cleanName(name)
    const node = { id: D.uid(), name: n, open: true }
    if (path === "")
        data.push(Object.assign(node, { groups: [] }))
    else {
        const parent = findNode(data, path)
        const depth = String(path).split("-").length
        if (depth === 1)
            parent.groups.push(Object.assign(node, { subs: [] }))
        else if (depth === 2)
            parent.subs.push(Object.assign(node, { dives: [] }))
        else
            throw new Error("no list can hold lists at " + path)
    }
    return data
}

export function renameNode(data, path, name) {
    findNode(data, path).name = cleanName(name)
    return data
}

export function removeNode(data, path) {
    findNode(data, path)
    const p = String(path).split("-").map(Number)
    if (p.length === 1)
        data.splice(p[0], 1)
    else if (p.length === 2)
        data[p[0]].groups.splice(p[1], 1)
    else
        data[p[0]].groups[p[1]].subs.splice(p[2], 1)
    return data
}

const FIELDS = "title, notes, due, time, end, repeat, until, remind, alarm, priority, energy, estimate, done"
const NONE = ["", "none", "off", "clear"]

function timeOf(value, field) {
    const m = value.match(/^(\d{1,2}):(\d{2})$/)
    const t = m ? m[1].padStart(2, "0") + ":" + m[2] : ""
    if (!D.isTime(t))
        throw new Error(field + " must look like 18:30 or be none")
    return t
}

export function applyField(draft, field, raw, now) {
    const value = String(raw === undefined ? "" : raw).trim()
    const none = NONE.indexOf(value.toLowerCase()) >= 0
    switch (field) {
    case "title":
        if (!value)
            throw new Error("give it a name first")
        draft.title = value
        break
    case "notes":
        draft.notes = value
        break
    case "due": {
        if (none) {
            draft.due = ""
            break
        }
        const parsed = D.quick("x " + value, now)
        const due = D.parseDay(value) ? value : parsed.text === "x" ? parsed.due : null
        if (!due)
            throw new Error("due must be a date like 2026-10-02, a word like tomorrow or friday, or none")
        draft.due = due
        break
    }
    case "time":
    case "end":
        draft[field] = none ? "" : timeOf(value, field)
        break
    case "repeat": {
        if (none || value === "once") {
            draft.rule = null
            break
        }
        const rule = PRESETS[value] ? Object.assign({}, PRESETS[value]) : D.quick("x " + value, now).rule
        if (!rule)
            throw new Error("repeat must be daily, weekdays, weekly, monthly, yearly, none or a phrase like every 2 weeks on mon")
        draft.rule = rule
        draft.ends = rule.until ? "on" : "never"
        break
    }
    case "until":
        if (!draft.rule)
            throw new Error("set a repeat before its end date")
        if (none) {
            delete draft.rule.until
            draft.ends = "never"
        } else if (D.parseDay(value)) {
            draft.rule = Object.assign({}, draft.rule, { until: value })
            draft.ends = "on"
        } else
            throw new Error("until must be a date like 2026-12-24 or none")
        break
    case "remind": {
        if (none) {
            draft.remind = []
            break
        }
        const list = value.split(/[\s,]+/).map(Number)
        if (list.some(n => !Number.isInteger(n) || n < 0 || n > 10080))
            throw new Error("remind takes minutes before the start, like 30,0 or none")
        draft.remind = list.filter((n, i) => list.indexOf(n) === i)
        break
    }
    case "alarm":
        if (["on", "true", "yes", "1"].indexOf(value) >= 0)
            draft.alarm = true
        else if (["off", "false", "no", "0"].indexOf(value) >= 0)
            draft.alarm = false
        else
            throw new Error("alarm must be on or off")
        break
    case "priority": {
        const map = { none: 0, low: 1, medium: 2, med: 2, high: 3, "0": 0, "1": 1, "2": 2, "3": 3 }
        if (map[value.toLowerCase()] === undefined)
            throw new Error("priority must be none, low, medium or high")
        draft.priority = map[value.toLowerCase()]
        break
    }
    case "energy":
        if (none || value === "any")
            draft.energy = ""
        else if (["low", "med", "high"].indexOf(value) >= 0)
            draft.energy = value
        else if (value === "medium")
            draft.energy = "med"
        else
            throw new Error("energy must be low, medium, high or none")
        break
    case "estimate": {
        const n = none ? 0 : Number(value)
        if (!Number.isInteger(n) || n < 0 || n > 1440)
            throw new Error("estimate takes minutes, like 25, or none")
        draft.estimate = n
        break
    }
    default:
        throw new Error("unknown field " + field + "; use one of " + FIELDS)
    }
    return draft
}

export function reminderItems(data, now) {
    return D.reminders(data, now, now + 14 * D.DAY).map(r => ({ rid: r.rid, at: r.at, title: r.title, alarm: r.alarm }))
}
