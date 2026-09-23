import { test } from "node:test"
import assert from "node:assert/strict"
import { pickScreen } from "../shell/lib/screens.mjs"

test("pickScreen finds the named screen", () => {
    assert.equal(pickScreen(["DP-1", "DP-2"], "DP-2"), 1)
})

test("pickScreen falls back to the first screen for unknown names", () => {
    assert.equal(pickScreen(["DP-1", "DP-2"], "HDMI-A-9"), 0)
    assert.equal(pickScreen(["DP-1", "DP-2"], ""), 0)
})

test("pickScreen returns -1 when there are no screens", () => {
    assert.equal(pickScreen([], "DP-1"), -1)
    assert.equal(pickScreen(null, "DP-1"), -1)
})
