import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { bluezCardName, parseCards, profileKind, profileLabel, cardProfile } from "../shell/lib/audio.mjs"

const cards = parseCards(readFileSync(new URL("./fixtures/pactl-cards.json", import.meta.url), "utf8"))

test("bluezCardName upper-cases and underscores the address", () => {
    assert.equal(bluezCardName("74:3f:8e:90:8e:4b"), "bluez_card.74_3F_8E_90_8E_4B")
})

test("parseCards returns an empty list for bad input", () => {
    assert.deepEqual(parseCards("nope"), [])
    assert.deepEqual(parseCards("{}"), [])
    assert.equal(cards.length, 3)
})

test("profileKind and profileLabel classify profiles", () => {
    assert.equal(profileKind("a2dp-sink-sbc"), "hifi")
    assert.equal(profileKind("headset-head-unit"), "headset")
    assert.equal(profileKind("off"), "off")
    assert.equal(profileLabel("hifi"), "Hi-Fi (A2DP)")
    assert.equal(profileLabel("headset"), "Headset (HFP)")
    assert.equal(profileLabel("off"), "Off")
})

test("cardProfile proposes the headset profile from hi-fi", () => {
    assert.deepEqual(cardProfile(cards, "00:11:22:33:44:01"), {
        card: "bluez_card.00_11_22_33_44_01",
        active: "a2dp-sink",
        kind: "hifi",
        label: "Hi-Fi (A2DP)",
        next: "headset-head-unit"
    })
})

test("cardProfile skips unavailable profiles", () => {
    const p = cardProfile(cards, "00:11:22:33:44:05")
    assert.equal(p.kind, "headset")
    assert.equal(p.next, "a2dp-sink-sbc")
})

test("cardProfile returns null for unknown devices", () => {
    assert.equal(cardProfile(cards, "AA:BB:CC:DD:EE:FF"), null)
})
