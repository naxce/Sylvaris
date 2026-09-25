import { test } from "node:test"
import assert from "node:assert/strict"
import { remember, find, preview, secret, DEFAULT_CLIP, validateClip } from "../shell/lib/clip.mjs"

const t = (id, text, pinned) => ({ id: id, kind: "text", text: text, pinned: pinned === true, at: 0 })

test("remember puts a new entry first, moves repeats up and trims unpinned ones past the limit", () => {
    let h = []
    h = remember(h, t("1", "a"), 3)
    h = remember(h, t("2", "b"), 3)
    h = remember(h, t("3", "a"), 3)
    assert.deepEqual(h.map(e => e.text), ["a", "b"])
    h = remember([t("p", "keep", true), t("x", "x"), t("y", "y")], t("z", "z"), 2)
    assert.deepEqual(h.map(e => e.text), ["z", "keep", "x"])
    assert.deepEqual(remember(h, t("e", "  "), 2), h)
})

test("find matches text case-insensitively and keeps pinned entries first", () => {
    const h = [t("1", "Hello world"), t("2", "bye", true), t("3", "HELLO again")]
    assert.deepEqual(find(h, "hello").map(e => e.id), ["1", "3"])
    assert.deepEqual(find(h, "").map(e => e.id), ["2", "1", "3"])
})

test("preview shows one tidy line", () => {
    assert.equal(preview("  line one\n\n  line two  ", 40), "line one ⏎ line two")
    assert.equal(preview("x".repeat(50), 10), "xxxxxxxxx…")
})

test("secret spots what password managers mark as sensitive", () => {
    assert.equal(secret(["text/plain", "x-kde-passwordManagerHint"]), true)
    assert.equal(secret(["text/plain;charset=utf-8"]), false)
})

test("validateClip keeps limits sane", () => {
    assert.deepEqual(validateClip({}), DEFAULT_CLIP)
    assert.equal(validateClip({ limit: 5000 }).limit, DEFAULT_CLIP.limit)
    assert.equal(validateClip({ limit: 20 }).limit, 20)
    assert.equal(validateClip({ persist: true }).persist, true)
    assert.equal(validateClip({ images: false }).images, false)
})
