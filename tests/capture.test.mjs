import { test } from "node:test"
import assert from "node:assert/strict"
import { hyprRects, swayRects, fileName, elapsed, DEFAULT_CAPTURE, validateCapture, expand } from "../shell/lib/capture.mjs"

test("hyprRects lists visible, mapped windows as slurp boxes", () => {
    const clients = [
        { at: [10, 20], size: [800, 600], workspace: { id: 1 }, mapped: true, hidden: false, title: "a" },
        { at: [0, 0], size: [100, 100], workspace: { id: 2 }, mapped: true, hidden: false, title: "other ws" },
        { at: [5, 5], size: [50, 50], workspace: { id: 1 }, mapped: false, hidden: false, title: "unmapped" }
    ]
    const monitors = [{ activeWorkspace: { id: 1 } }]
    assert.deepEqual(hyprRects(clients, monitors), ["10,20 800x600"])
})

test("swayRects walks the tree and keeps visible windows", () => {
    const tree = { nodes: [{ type: "output", nodes: [{ type: "workspace", visible: true, nodes: [{ type: "con", pid: 1, visible: true, rect: { x: 0, y: 30, width: 640, height: 480 }, nodes: [] }], floating_nodes: [{ type: "floating_con", pid: 2, visible: true, rect: { x: 100, y: 100, width: 200, height: 150 }, nodes: [] }] }, { type: "workspace", visible: false, nodes: [{ type: "con", pid: 3, visible: false, rect: { x: 0, y: 0, width: 9, height: 9 }, nodes: [] }] }] }] }
    assert.deepEqual(swayRects(tree), ["0,30 640x480", "100,100 200x150"])
})

test("fileName stamps screenshots and recordings", () => {
    const d = new Date(2026, 8, 25, 4, 5, 6)
    assert.equal(fileName("shot", d), "Screenshot 2026-09-25 04-05-06.png")
    assert.equal(fileName("video", d), "Recording 2026-09-25 04-05-06.mp4")
})

test("elapsed reads like a stopwatch", () => {
    assert.equal(elapsed(0), "0:00")
    assert.equal(elapsed(65000), "1:05")
    assert.equal(elapsed(3725000), "1:02:05")
})

test("validateCapture and expand", () => {
    assert.deepEqual(validateCapture({}), DEFAULT_CAPTURE)
    assert.equal(validateCapture({ delay: 7 }).delay, 0)
    assert.equal(validateCapture({ delay: 5 }).delay, 5)
    assert.equal(validateCapture({ folder: 3 }).folder, DEFAULT_CAPTURE.folder)
    assert.equal(validateCapture({ copy: false, save: false }).save, true)
    assert.equal(expand("~/Pictures/Shots", "/home/a"), "/home/a/Pictures/Shots")
})
