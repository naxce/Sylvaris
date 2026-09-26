import { test } from "node:test"
import assert from "node:assert/strict"
import { perfArgs } from "../shell/lib/perf.mjs"

test("perfArgs trims the compositor and a reload brings the config back", () => {
    assert.deepEqual(perfArgs("hyprland", true, false), ["hyprctl", "reload"])
    assert.equal(perfArgs("hyprland", true, true)[1], "eval")
    assert.ok(perfArgs("hyprland", true, true)[2].includes("animations = { enabled = false }"))
    assert.ok(perfArgs("hyprland", false, true)[2].startsWith("keyword animations:enabled 0 ; "))
    assert.deepEqual(perfArgs("sway", false, false), ["swaymsg", "reload"])
    assert.equal(perfArgs("niri", false, true), null)
})
