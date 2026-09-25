import { test } from "node:test"
import assert from "node:assert/strict"
import { GLYPHS, bluetoothIcon, isAudioDevice, normalizeSignal, wifiIcon, batteryIcon, nudge } from "../shell/lib/icons.mjs"

const g = cp => String.fromCodePoint(cp)

test("GLYPHS are single Nerd Font code points", () => {
    for (const key of Object.keys(GLYPHS))
        assert.equal([...GLYPHS[key]].length, 1, key)
    assert.equal(GLYPHS.wifi, g(0xF05A9))
    assert.equal(GLYPHS.bluetooth, g(0xF00AF))
    assert.equal(GLYPHS.hotspot, g(0xF0002))
})

test("bluetoothIcon maps BlueZ icon names", () => {
    assert.equal(bluetoothIcon("audio-headphones"), g(0xF02CB))
    assert.equal(bluetoothIcon("audio-headset"), g(0xF02CE))
    assert.equal(bluetoothIcon("audio-card"), g(0xF04C3))
    assert.equal(bluetoothIcon("input-mouse"), g(0xF037D))
    assert.equal(bluetoothIcon("input-keyboard"), g(0xF030C))
    assert.equal(bluetoothIcon("input-gaming"), g(0xF02B4))
    assert.equal(bluetoothIcon("phone"), g(0xF03F2))
    assert.equal(bluetoothIcon("computer"), g(0xF0322))
    assert.equal(bluetoothIcon("something-new"), GLYPHS.bluetooth)
    assert.equal(bluetoothIcon(undefined), GLYPHS.bluetooth)
})

test("isAudioDevice matches audio-* icons only", () => {
    assert.equal(isAudioDevice("audio-headset"), true)
    assert.equal(isAudioDevice("input-mouse"), false)
    assert.equal(isAudioDevice(null), false)
})

test("normalizeSignal accepts 0..1 and 0..100", () => {
    assert.equal(normalizeSignal(0.5), 0.5)
    assert.equal(normalizeSignal(80), 0.8)
    assert.equal(normalizeSignal(150), 1)
    assert.equal(normalizeSignal(-3), 0)
    assert.equal(normalizeSignal(undefined), -1)
    assert.equal(normalizeSignal(NaN), -1)
})

test("wifiIcon picks a strength glyph", () => {
    assert.equal(wifiIcon(0.9), g(0xF0928))
    assert.equal(wifiIcon(0.6), g(0xF0925))
    assert.equal(wifiIcon(0.3), g(0xF0922))
    assert.equal(wifiIcon(0.1), g(0xF091F))
    assert.equal(wifiIcon(0), g(0xF092F))
    assert.equal(wifiIcon(undefined), g(0xF092F))
})

test("batteryIcon picks a level glyph", () => {
    assert.equal(batteryIcon(100), g(0xF0079))
    assert.equal(batteryIcon(90), g(0xF0082))
    assert.equal(batteryIcon(52), g(0xF007E))
    assert.equal(batteryIcon(10), g(0xF007A))
    assert.equal(batteryIcon(3), g(0xF0083))
})

test("nudge lowers the chevrons whose ink sits high in their box and leaves other glyphs alone", () => {
    assert.deepEqual(nudge(GLYPHS.chevronDown), { x: 0, y: 0.083 })
    assert.deepEqual(nudge(GLYPHS.chevronRight), { x: 0, y: 0.049 })
    assert.deepEqual(nudge(GLYPHS.bell), { x: 0, y: 0 })
    assert.deepEqual(nudge(""), { x: 0, y: 0 })
})
