import { test } from "node:test"
import assert from "node:assert/strict"
import { SEP, dispatch, format, describe, parseRequest, topics, changed, parseValue } from "../shell/lib/ipc.mjs"

const calls = []
const commands = {
    center: { toggle: () => calls.push("toggle"), view: name => "view " + name },
    theme: { default: "open", open: () => "opened", fail: () => { throw new Error("boom") } }
}

test("dispatch runs the named action with its arguments", () => {
    assert.deepEqual(dispatch(commands, ["center", "view", "calendar"]), { ok: true, result: "view calendar" })
})

test("dispatch falls back to the part's default action, then toggle", () => {
    assert.deepEqual(dispatch(commands, ["theme"]), { ok: true, result: "opened" })
    calls.length = 0
    assert.deepEqual(dispatch(commands, ["center"]), { ok: true, result: 1 })
    assert.deepEqual(calls, ["toggle"])
})

test("dispatch reports unknown parts, unknown actions and thrown errors", () => {
    assert.equal(dispatch(commands, ["nope"]).error, "unknown part: nope")
    assert.equal(dispatch(commands, ["center", "fly"]).error, "unknown center action: fly")
    assert.equal(dispatch(commands, ["theme", "default"]).error, "unknown theme action: default")
    assert.equal(dispatch(commands, ["theme", "fail"]).error, "boom")
    assert.equal(dispatch(commands, []).ok, false)
})

test("format prints ok, strings as is, objects as JSON and errors with a prefix", () => {
    assert.equal(format({ ok: true, result: null }), "ok")
    assert.equal(format({ ok: true, result: "x" }), "x")
    assert.equal(format({ ok: true, result: { a: 1 } }), "{\"a\":1}")
    assert.equal(format({ ok: false, error: "bad" }), "error: bad")
})

test("describe lists each part's actions without the default marker", () => {
    assert.deepEqual(describe(commands), { center: ["toggle", "view"], theme: ["open", "fail"] })
})

test("parseRequest accepts JSON arrays and plain words", () => {
    assert.deepEqual(parseRequest("[\"center\",\"view\",\"a b\"]"), { ok: true, words: ["center", "view", "a b"] })
    assert.deepEqual(parseRequest("  center   toggle "), { ok: true, words: ["center", "toggle"] })
    assert.deepEqual(parseRequest("center" + SEP + "view" + SEP + "orbit-wifi:My Net" + SEP), { ok: true, words: ["center", "view", "orbit-wifi:My Net"] })
    assert.deepEqual(parseRequest("list" + SEP), { ok: true, words: ["list"] })
    assert.equal(parseRequest("[1]").ok, false)
    assert.equal(parseRequest("[").ok, false)
    assert.equal(parseRequest("").ok, false)
})

test("changed finds the topics whose JSON differs", () => {
    const a = topics({ audio: { v: 1 }, media: null })
    const b = topics({ audio: { v: 2 }, media: null, extra: 1 })
    assert.deepEqual(changed(a, b), ["audio", "extra"])
    assert.deepEqual(changed(b, b), [])
})

test("parseValue reads JSON and keeps anything else as text", () => {
    assert.equal(parseValue("true"), true)
    assert.equal(parseValue("0.5"), 0.5)
    assert.equal(parseValue("top-left"), "top-left")
})
