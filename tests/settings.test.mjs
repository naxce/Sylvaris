import { test } from "node:test"
import assert from "node:assert/strict"
import {
    CORNERS, DEFAULT_CONFIG, DEFAULT_SETTINGS, parseJson, expandHome, deepMerge, migrate,
    validateConfig, validateSettings, merge, getPath, setPath, serialize, DEFAULT_GLASS, resolveGlass
} from "../shell/lib/settings.mjs"

test("parseJson treats empty text as an empty object", () => {
    assert.deepEqual(parseJson(""), { ok: true, value: {} })
    assert.deepEqual(parseJson("  \n"), { ok: true, value: {} })
    assert.deepEqual(parseJson(null), { ok: true, value: {} })
})

test("parseJson rejects invalid JSON and non-objects", () => {
    assert.equal(parseJson("{nope").ok, false)
    assert.equal(parseJson("[1,2]").ok, false)
    assert.equal(parseJson("42").ok, false)
    assert.equal(typeof parseJson("{nope").error, "string")
})

test("parseJson returns objects", () => {
    assert.deepEqual(parseJson('{"a":1}'), { ok: true, value: { a: 1 } })
})

test("expandHome expands a leading tilde only", () => {
    assert.equal(expandHome("~/x/y", "/home/u"), "/home/u/x/y")
    assert.equal(expandHome("~", "/home/u"), "/home/u")
    assert.equal(expandHome("/abs/~/x", "/home/u"), "/abs/~/x")
    assert.equal(expandHome("", "/home/u"), "")
})

test("deepMerge merges objects, replaces arrays and does not mutate", () => {
    const base = { a: { b: 1, c: 2 }, list: [1, 2], keep: true }
    const over = { a: { c: 3 }, list: [9] }
    const out = deepMerge(base, over)
    assert.deepEqual(out, { a: { b: 1, c: 3 }, list: [9], keep: true })
    assert.deepEqual(base, { a: { b: 1, c: 2 }, list: [1, 2], keep: true })
    assert.deepEqual(over, { a: { c: 3 }, list: [9] })
})

test("migrate adds version 1 and keeps newer versions", () => {
    assert.equal(migrate({}).version, 1)
    assert.equal(migrate({ version: 2 }).version, 2)
    assert.equal(migrate(null).version, 1)
})

test("validateConfig fills defaults and keeps unknown keys", () => {
    const v = validateConfig({ themeHook: "hook", extra: { x: 1 }, terminal: 5 })
    assert.equal(v.themeHook, "hook")
    assert.equal(v.terminal, DEFAULT_CONFIG.terminal)
    assert.equal(v.themesDir, DEFAULT_CONFIG.themesDir)
    assert.deepEqual(v.extra, { x: 1 })
    assert.equal(v.version, 1)
})

test("validateConfig keeps valid toggles, drops invalid ones and duplicates", () => {
    const v = validateConfig({
        toggles: [
            { id: "performance", label: "Performance", on: "a", off: "b" },
            { id: "Bad Id", label: "x" },
            { id: "nolabel" },
            { id: "performance", label: "Duplicate" },
            "junk"
        ]
    })
    assert.equal(v.toggles.length, 1)
    assert.deepEqual(v.toggles[0], { id: "performance", label: "Performance", icon: "\u{F0521}", on: "a", off: "b", status: "" })
})

test("validateConfig replaces non-array toggles and commands", () => {
    const v = validateConfig({ toggles: "x", commands: {} })
    assert.deepEqual(v.toggles, [])
    assert.deepEqual(v.commands, [])
})

test("validateSettings fixes invalid values field by field", () => {
    const v = validateSettings({
        cc: { corner: "bottom", other: 1 },
        nightLight: { enabled: "yes", temperature: 50000 },
        displays: { layouts: [] },
        toggleState: { a: true, b: "no" },
        hotspot: { ssid: "x".repeat(33), band: "z" },
        unknown: 7
    })
    assert.deepEqual(v.cc, { corner: "top-right", other: 1 })
    assert.deepEqual(v.nightLight, { enabled: false, temperature: 4000 })
    assert.deepEqual(v.displays, { layouts: {} })
    assert.deepEqual(v.toggleState, { a: true })
    assert.deepEqual(v.hotspot, { ssid: "Sylvaris", band: "bg" })
    assert.equal(v.unknown, 7)
})

test("validateSettings keeps valid values", () => {
    const v = validateSettings({
        cc: { corner: "top-left" },
        nightLight: { enabled: true, temperature: 3500 },
        hotspot: { ssid: "Mine", band: "a" }
    })
    assert.equal(v.cc.corner, "top-left")
    assert.deepEqual(v.nightLight, { enabled: true, temperature: 3500 })
    assert.deepEqual(v.hotspot, { ssid: "Mine", band: "a" })
    assert.ok(CORNERS.includes("top-center"))
})

test("validateSettings of nothing equals the defaults", () => {
    assert.deepEqual(validateSettings({}), JSON.parse(JSON.stringify(DEFAULT_SETTINGS)))
})

test("merge lets settings win over config on shared keys", () => {
    const out = merge({ extra: "config", themeHook: "h" }, { extra: "settings" })
    assert.equal(out.extra, "settings")
    assert.equal(out.themeHook, "h")
    assert.equal(out.cc.corner, "top-right")
})

test("getPath and setPath work on nested keys without mutating", () => {
    const obj = { a: { b: 1 } }
    const next = setPath(obj, "a.c.d", 5)
    assert.equal(getPath(next, "a.c.d"), 5)
    assert.equal(getPath(next, "a.b"), 1)
    assert.equal(getPath(obj, "a.c"), undefined)
    assert.equal(getPath(obj, "x.y"), undefined)
    const layouts = setPath({}, "displays.layouts.DP-1+HDMI-A-1", { x: 1 })
    assert.deepEqual(layouts, { displays: { layouts: { "DP-1+HDMI-A-1": { x: 1 } } } })
})

test("serialize produces parseable JSON with a trailing newline", () => {
    const text = serialize({ a: 1 })
    assert.ok(text.endsWith("\n"))
    assert.deepEqual(JSON.parse(text), { a: 1 })
})

test("resolveGlass returns the defaults without input", () => {
    const r = resolveGlass(undefined, undefined)
    assert.deepEqual(r.values, DEFAULT_GLASS)
    assert.deepEqual(r.errors, [])
    assert.deepEqual(DEFAULT_GLASS, { enabled: true, opacity: 0.55, layerOpacity: 0.35, tint: 0.14, sheen: 0.35, flow: 1, rim: 0.5, grain: 0.035 })
})

test("resolveGlass lets settings.json override config.json", () => {
    const r = resolveGlass({ opacity: 0.4, rim: 0.2 }, { opacity: 0.7, enabled: false })
    assert.equal(r.values.opacity, 0.7)
    assert.equal(r.values.rim, 0.2)
    assert.equal(r.values.enabled, false)
    assert.deepEqual(r.errors, [])
})

test("resolveGlass keeps the lower layer for invalid values and reports them", () => {
    const r = resolveGlass({ opacity: 0.4 }, { opacity: 55, flow: "fast", grain: 0.5, enabled: "no", shine: 1 })
    assert.equal(r.values.opacity, 0.4)
    assert.equal(r.values.flow, 1)
    assert.equal(r.values.grain, 0.035)
    assert.equal(r.values.enabled, true)
    assert.deepEqual(r.errors, [
        "settings.json glass.opacity must be a number from 0 to 1",
        "settings.json glass.flow must be a number from 0 to 3",
        "settings.json glass.grain must be a number from 0 to 0.2",
        "settings.json glass.enabled must be true or false",
        "settings.json glass.shine is not a glass key"
    ])
})

test("resolveGlass rejects a glass block that is not an object", () => {
    const r = resolveGlass([1], "x")
    assert.deepEqual(r.values, DEFAULT_GLASS)
    assert.deepEqual(r.errors, ["config.json glass must be an object", "settings.json glass must be an object"])
})

test("validateSettings keeps the glass block for resolveGlass", () => {
    assert.deepEqual(validateSettings({ glass: { opacity: 0.3 } }).glass, { opacity: 0.3 })
})
