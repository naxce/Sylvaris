import { test } from "node:test"
import assert from "node:assert/strict"
import { idle, begin, settle, fire, commit, cancel, wheelStep } from "../shell/lib/preview.mjs"

test("begin remembers the original theme", () => {
    assert.deepEqual(begin("warm"), { active: true, original: "warm", applied: "warm", pending: "" })
})

test("a settled id is applied once when the timer fires", () => {
    const r = fire(settle(begin("warm"), "noir"))
    assert.equal(r.apply, "noir")
    assert.equal(r.state.applied, "noir")
    assert.equal(fire(r.state).apply, "")
})

test("rapid settles apply only the last id", () => {
    const s = settle(settle(settle(begin("a"), "b"), "c"), "d")
    assert.equal(fire(s).apply, "d")
})

test("settling back on the applied theme applies nothing", () => {
    assert.equal(fire(settle(begin("a"), "a")).apply, "")
})

test("commit applies a pending front immediately", () => {
    const r = commit(settle(begin("a"), "b"), "b")
    assert.equal(r.apply, "b")
    assert.deepEqual(r.state, idle())
})

test("commit on the already applied theme applies nothing", () => {
    const s = fire(settle(begin("a"), "b")).state
    assert.equal(commit(s, "b").apply, "")
})

test("cancel reverts only when a preview changed the theme", () => {
    const changed = fire(settle(begin("a"), "b")).state
    assert.equal(cancel(changed).apply, "a")
    assert.equal(cancel(settle(begin("a"), "b")).apply, "")
    assert.equal(cancel(begin("a")).apply, "")
})

test("cancel cannot revert to an unknown original", () => {
    const s = fire(settle(begin(""), "b")).state
    assert.equal(cancel(s).apply, "")
})

test("calls while idle do nothing", () => {
    assert.deepEqual(settle(idle(), "x"), idle())
    assert.equal(fire(idle()).apply, "")
    assert.equal(commit(idle(), "x").apply, "")
    assert.equal(cancel(idle()).apply, "")
})

test("a mouse wheel notch moves one card", () => {
    assert.deepEqual(wheelStep(0, -120), { acc: 0, steps: 1 })
    assert.deepEqual(wheelStep(0, 120), { acc: 0, steps: -1 })
})

test("touchpad deltas add up to one card per 120 units", () => {
    let acc = 0
    let steps = 0
    for (let i = 0; i < 15; i++) {
        const r = wheelStep(acc, -8)
        acc = r.acc
        steps += r.steps
    }
    assert.equal(steps, 1)
    assert.equal(acc, 0)
})

test("a zero delta moves nothing", () => {
    assert.deepEqual(wheelStep(-40, 0), { acc: -40, steps: 0 })
})

test("a large delta moves several cards and keeps the remainder", () => {
    assert.deepEqual(wheelStep(0, -250), { acc: -10, steps: 2 })
})
