import { test } from "node:test"
import assert from "node:assert/strict"
import { idle, begin, settle, fire, commit, cancel } from "../shell/lib/preview.mjs"

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
