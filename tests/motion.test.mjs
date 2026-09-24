import { test } from "node:test"
import assert from "node:assert/strict"
import { origin, scaledRect, rise, stagger } from "../shell/lib/motion.mjs"

test("panels grow out of the corner they are anchored to", () => {
    assert.deepEqual(origin("top-right"), { h: 1, v: 0 })
    assert.deepEqual(origin("bottom-left"), { h: 0, v: 1 })
    assert.deepEqual(origin("center"), { h: 0.5, v: 0.5 })
    assert.deepEqual(scaledRect(0, 0, 100, 200, "top-right", 0.5, 0), { x: 50, y: 0, w: 50, h: 100 })
    assert.deepEqual(scaledRect(10, 10, 100, 100, "center", 0.5, -4), { x: 35, y: 31, w: 50, h: 50 })
    assert.equal(rise("bottom-center"), 1)
    assert.equal(rise("top-left"), -1)
})

test("stagger delays later items and still ends at one", () => {
    assert.equal(stagger(0, 0, 4), 0)
    assert.equal(stagger(1, 3, 4), 1)
    assert.ok(stagger(0.3, 0, 4) > stagger(0.3, 3, 4))
    assert.equal(stagger(0.1, 3, 4, 0.35), 0)
})
