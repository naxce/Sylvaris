import { test } from "node:test"
import assert from "node:assert/strict"
import { ACTIONS, normalize, validateKeybinds, bindArgs, unbindArgs, keyName, diff } from "../shell/lib/keys.mjs"

test("normalize orders modifiers and cleans the key", () => {
    assert.equal(normalize("shift+super+s"), "SUPER+SHIFT+S")
    assert.equal(normalize("SUPER + space"), "SUPER+space")
    assert.equal(normalize("ctrl+alt+Delete"), "CTRL+ALT+Delete")
    assert.equal(normalize("SUPER+"), "")
    assert.equal(normalize("SUPER+SHIFT"), "")
    assert.equal(normalize("SUPER+a;rm -rf"), "")
})

test("validateKeybinds keeps known actions with valid keys", () => {
    assert.deepEqual(validateKeybinds({ "clip toggle": "super+v", "rm -rf": "SUPER+X", "lock now": "bad key!" }), { "clip toggle": "SUPER+V" })
    assert.deepEqual(validateKeybinds(null), {})
    assert.ok(ACTIONS.every(a => a.id && a.label))
})

test("bindArgs and unbindArgs speak Hyprland Lua, classic Hyprland and sway", () => {
    assert.deepEqual(bindArgs("hyprland", true, "SUPER+SHIFT+S", "capture shot area"), ["hyprctl", "eval", "hl.bind(\"SUPER + SHIFT + S\", hl.dsp.exec_cmd(\"sylvaris capture shot area\"))"])
    assert.deepEqual(unbindArgs("hyprland", true, "SUPER+SHIFT+S"), ["hyprctl", "eval", "hl.unbind(\"SUPER + SHIFT + S\")"])
    assert.deepEqual(bindArgs("hyprland", false, "SUPER+V", "clip toggle"), ["hyprctl", "keyword", "bind", "SUPER,V,exec,sylvaris clip toggle"])
    assert.deepEqual(unbindArgs("hyprland", false, "CTRL+ALT+L"), ["hyprctl", "keyword", "unbind", "CTRL ALT,L"])
    assert.deepEqual(bindArgs("sway", false, "SUPER+SHIFT+S", "capture shot area"), ["swaymsg", "bindsym", "Mod4+Shift+s", "exec", "sylvaris capture shot area"])
    assert.deepEqual(unbindArgs("sway", false, "ALT+Tab"), ["swaymsg", "unbindsym", "Mod1+Tab"])
    assert.equal(bindArgs("niri", false, "SUPER+V", "clip toggle"), null)
})

test("keyName turns key events into key names", () => {
    assert.equal(keyName(0x56, "v"), "V")
    assert.equal(keyName(0x20, " "), "space")
    assert.equal(keyName(0x01000004, "\r"), "Return")
    assert.equal(keyName(0x01000001, "\t"), "Tab")
    assert.equal(keyName(0x01000030, ""), "F1")
    assert.equal(keyName(0x0100003b, ""), "F12")
    assert.equal(keyName(0x01000009, ""), "Print")
    assert.equal(keyName(0x01000012, ""), "Left")
    assert.equal(keyName(0x01000021, ""), "")
})

test("diff says what to unbind and bind", () => {
    assert.deepEqual(diff({ a: "SUPER+A", b: "SUPER+B" }, { a: "SUPER+A", b: "SUPER+C", c: "SUPER+D" }), {
        unbind: ["SUPER+B"],
        bind: [["SUPER+C", "b"], ["SUPER+D", "c"]]
    })
    assert.deepEqual(diff({ a: "SUPER+A" }, {}), { unbind: ["SUPER+A"], bind: [] })
})
