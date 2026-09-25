import { test } from "node:test"
import assert from "node:assert/strict"
import { unused, shift, validateBar, validateDeck, deckItems, nextWindow, togglePin, magnify, DEFAULT_BAR, vertical, drawerArrow, placeCorner } from "../shell/lib/bar.mjs"

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

test("unused lists modules on no side, shift moves within bounds", () => {
    assert.deepEqual(unused({ left: ["pad", "clock"], center: [], right: ["workspaces", "window", "media", "tray", "audio", "network", "bluetooth", "battery"] }), ["notifications", "center", "power", "diver"])
    assert.deepEqual(shift(["a", "b", "c"], 0, 1), ["b", "a", "c"])
    assert.deepEqual(shift(["a", "b", "c"], 2, 1), ["a", "b", "c"])
    assert.deepEqual(shift(["a", "b", "c"], 2, -2), ["c", "a", "b"])
})

test("bar position, style and drawer direction", () => {
    assert.equal(validateBar({ position: "left" }).position, "left")
    assert.equal(validateBar({ position: "middle" }).position, "top")
    assert.equal(validateBar({ style: "slab" }).style, "slab")
    assert.equal(validateBar({}).style, "islands")
    assert.equal(vertical("right"), true)
    assert.equal(vertical("bottom"), false)
    assert.deepEqual(["top", "bottom", "left", "right"].map(drawerArrow), ["down", "up", "right", "left"])
})

test("placeCorner opens popups next to the bar wherever it sits", () => {
    assert.equal(placeCorner("top-left", "top"), "top-left")
    assert.equal(placeCorner("top-center", "bottom"), "bottom-center")
    assert.equal(placeCorner("top-right", "bottom"), "bottom-right")
    assert.equal(placeCorner("top-left", "left"), "top-left")
    assert.equal(placeCorner("top-center", "left"), "center-left")
    assert.equal(placeCorner("top-right", "left"), "bottom-left")
    assert.equal(placeCorner("top-left", "right"), "top-right")
    assert.equal(placeCorner("top-center", "right"), "center-right")
    assert.equal(placeCorner("top-right", "right"), "bottom-right")
    assert.equal(placeCorner("center", "bottom"), "center")
    assert.equal(placeCorner("nonsense", "top"), "top-center")
})

test("deck effect replaces the old magnify flag", () => {
    assert.equal(validateDeck({}).effect, "bloom")
    assert.equal(validateDeck({ magnify: true }).effect, "magnify")
    assert.equal(validateDeck({ effect: "none", magnify: true }).effect, "none")
    assert.equal(validateDeck({}).reserve, true)
    assert.equal(validateDeck({ reserve: false }).reserve, false)
    assert.equal(validateDeck({ power: "end" }).power, "end")
})
