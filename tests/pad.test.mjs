import { test } from "node:test"
import assert from "node:assert/strict"
import { score, search, visible, pages, move } from "../shell/lib/pad.mjs"

const apps = [
    { id: "firefox", name: "Firefox", genericName: "Web Browser", keywords: ["internet"], comment: "Browse the web" },
    { id: "kitty", name: "kitty", genericName: "Terminal emulator", keywords: [], comment: "" },
    { id: "files", name: "Nemo Files", genericName: "File Manager", keywords: [], comment: "" },
    { id: "steam", name: "Steam", genericName: "", keywords: ["games"], comment: "Play games" },
    { id: "hidden", name: "Hidden", noDisplay: true },
    { id: "firefox", name: "Firefox duplicate" }
]

test("score ranks exact, prefix, word prefix, substring, extra fields, comment and subsequence", () => {
    assert.equal(score(apps[0], "firefox"), 120)
    assert.equal(score(apps[0], "fire"), 100)
    assert.equal(score(apps[2], "fil"), 80)
    assert.equal(score(apps[0], "efo"), 60)
    assert.equal(score(apps[0], "browser"), 40)
    assert.equal(score(apps[3], "play"), 20)
    assert.equal(score(apps[0], "ffx"), 10)
    assert.equal(score(apps[1], "zzz"), 0)
})

test("search sorts by score, then name", () => {
    assert.deepEqual(search(apps.slice(0, 4), "te").map(a => a.id), ["steam", "firefox", "kitty"])
    assert.deepEqual(search(apps.slice(0, 4), "").map(a => a.id), ["firefox", "kitty", "files", "steam"])
})

test("visible drops hidden entries and duplicate ids, sorted by name", () => {
    assert.deepEqual(visible(apps).map(a => a.name), ["Firefox", "kitty", "Nemo Files", "Steam"])
})

test("pages splits the list and always has at least one page", () => {
    assert.deepEqual(pages([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]])
    assert.deepEqual(pages([], 2), [[]])
})

test("move walks the grid without leaving it", () => {
    assert.equal(move(0, "left", 20, 4, 8), 0)
    assert.equal(move(0, "right", 20, 4, 8), 1)
    assert.equal(move(1, "down", 20, 4, 8), 5)
    assert.equal(move(5, "down", 20, 4, 8), 5)
    assert.equal(move(5, "up", 20, 4, 8), 1)
    assert.equal(move(7, "right", 20, 4, 8), 8)
    assert.equal(move(3, "pageDown", 20, 4, 8), 8)
    assert.equal(move(17, "pageDown", 20, 4, 8), 19)
    assert.equal(move(9, "pageUp", 20, 4, 8), 0)
    assert.equal(move(0, "right", 0, 4, 8), -1)
})
