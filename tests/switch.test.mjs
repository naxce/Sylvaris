import { test } from "node:test"
import assert from "node:assert/strict"
import { touch, ordered, wrap, keyOf } from "../shell/lib/switch.mjs"

test("touch moves a key to the front once and forgets keys that are gone", () => {
    assert.deepEqual(touch(["a", "b", "c"], "c", ["a", "b", "c"]), ["c", "a", "b"])
    assert.deepEqual(touch(["a", "b"], "a", ["a", "b"]), ["a", "b"])
    assert.deepEqual(touch(["a", "b", "c"], "d", ["a", "c", "d"]), ["d", "a", "c"])
    assert.deepEqual(touch(["a"], null, ["a"]), ["a"])
})

test("ordered lists windows most recent first and keeps new ones in their original order", () => {
    const w = [{ k: "a" }, { k: "b" }, { k: "c" }, { k: "d" }]
    assert.deepEqual(ordered(w, ["c", "a"], x => x.k).map(x => x.k), ["c", "a", "b", "d"])
    assert.deepEqual(ordered(w, [], x => x.k).map(x => x.k), ["a", "b", "c", "d"])
})

test("wrap steps around both ends", () => {
    assert.equal(wrap(0, 1, 3), 1)
    assert.equal(wrap(2, 1, 3), 0)
    assert.equal(wrap(0, -1, 3), 2)
    assert.equal(wrap(0, 1, 0), -1)
})

test("keyOf uses the window handle when there is one and app plus title otherwise", () => {
    const h = {}
    assert.equal(keyOf({ handle: h }), h)
    assert.equal(keyOf({ handle: null, appId: "kitty", title: "htop" }), "kitty\u0001htop")
})
