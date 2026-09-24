import { test } from "node:test"
import assert from "node:assert/strict"
import { validateBar, validateDeck, deckItems, nextWindow, togglePin, magnify, DEFAULT_BAR } from "../shell/lib/bar.mjs"

test("validateBar keeps known modules once and falls back per side", () => {
    const b = validateBar({ left: ["clock", "nope", "clock", "pad"], floating: false })
    assert.deepEqual(b.left, ["clock", "pad"])
    assert.deepEqual(b.center, [])
    assert.deepEqual(b.right, DEFAULT_BAR.right)
    assert.equal(b.floating, false)
    assert.equal(b.enabled, true)
    assert.deepEqual(validateBar({}).left, DEFAULT_BAR.left)
})

test("validateDeck is off by default and cleans its values", () => {
    const d = validateDeck({ pinned: ["firefox", "", "firefox", 3, "kitty"], pad: "middle", size: 400 })
    assert.equal(d.enabled, false)
    assert.deepEqual(d.pinned, ["firefox", "kitty"])
    assert.equal(d.pad, "start")
    assert.equal(d.size, 56)
    assert.equal(validateDeck({ enabled: true }).enabled, true)
})

test("deckItems puts pinned apps first and groups running windows by app", () => {
    const windows = [{ appId: "kitty" }, { appId: "org.mozilla.firefox" }, { appId: "kitty" }, { appId: "spotify" }]
    const entryOf = a => ({ "org.mozilla.firefox": "firefox", kitty: "kitty" })[a] || ""
    assert.deepEqual(deckItems(["firefox", "nemo"], windows, entryOf), [
        { id: "firefox", pinned: true, windows: [1] },
        { id: "nemo", pinned: true, windows: [] },
        { id: "kitty", pinned: false, windows: [0, 2] },
        { id: "spotify", pinned: false, windows: [3] }
    ])
})

test("nextWindow cycles through an app's windows starting after the focused one", () => {
    const w = [{ activated: false }, { activated: true }, { activated: false }]
    assert.equal(nextWindow([0, 1, 2], w), 2)
    assert.equal(nextWindow([0, 2], w), 0)
    assert.equal(nextWindow([], w), -1)
})

test("togglePin adds and removes", () => {
    assert.deepEqual(togglePin(["a"], "b"), ["a", "b"])
    assert.deepEqual(togglePin(["a", "b"], "a"), ["b"])
})

test("magnify peaks under the pointer and fades to 1", () => {
    assert.equal(magnify(0, 150), 1.45)
    assert.equal(magnify(150, 150), 1)
    assert.ok(magnify(75, 150) > 1 && magnify(75, 150) < 1.45)
})
