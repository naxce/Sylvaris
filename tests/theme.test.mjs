import { test } from "node:test"
import assert from "node:assert/strict"
import { DEFAULT_THEME, COLOR_KEYS, parseHex, withAlpha, validateTheme, tokens, nextThemeId, parseArgb, mixArgb, mixTokens, catalogEntry } from "../shell/lib/theme.mjs"

const warm = {
    id: "warm",
    name: "Warm",
    description: "Warm browns",
    wallpaper: "~/Pictures/warm.png",
    colors: {
        base: "#181310", surface: "#281f1a", accent: "#c9702f", accentHi: "#e0955c",
        accentDeep: "#a85c32", onAccent: "#181310", text: "#e7dac6", textDim: "#b2967b",
        textSoft: "#d3b9a1", danger: "#d9674a"
    },
    alpha: { surface: 0.9, glass: 0.62, line: 0.16, tint: 0.08 }
}

test("parseHex reads six-digit hex colors only", () => {
    assert.deepEqual(parseHex("#a85c32"), { r: 168, g: 92, b: 50 })
    assert.deepEqual(parseHex("#FFFFFF"), { r: 255, g: 255, b: 255 })
    assert.equal(parseHex("#fff"), null)
    assert.equal(parseHex("red"), null)
    assert.equal(parseHex(undefined), null)
})

test("withAlpha produces #aarrggbb and clamps alpha", () => {
    assert.equal(withAlpha("#181310", 0.9), "#e6181310")
    assert.equal(withAlpha("#a85c32", 0.16), "#29a85c32")
    assert.equal(withAlpha("#000000", 2), "#ff000000")
    assert.equal(withAlpha("#000000", -1), "#00000000")
    assert.equal(withAlpha("nope", 0.5), "#00000000")
})

test("validateTheme accepts a complete theme", () => {
    const r = validateTheme(warm)
    assert.equal(r.ok, true)
    assert.deepEqual(r.errors, [])
    assert.equal(r.theme.id, "warm")
    assert.equal(r.theme.wallpaper, "~/Pictures/warm.png")
    assert.equal(r.theme.colors.accent, "#c9702f")
})

test("validateTheme rejects themes without id or name", () => {
    const r = validateTheme({ name: "No id" })
    assert.equal(r.ok, false)
    assert.equal(r.theme.id, DEFAULT_THEME.id)
    assert.equal(validateTheme({ id: "Bad Id", name: "x" }).ok, false)
    assert.equal(validateTheme(null).ok, false)
    assert.equal(validateTheme([1]).ok, false)
})

test("validateTheme falls back per color and reports it", () => {
    const r = validateTheme({ id: "partial", name: "Partial", colors: { accent: "#123456", text: "oops" } })
    assert.equal(r.ok, true)
    assert.equal(r.theme.colors.accent, "#123456")
    assert.equal(r.theme.colors.text, DEFAULT_THEME.colors.text)
    assert.equal(r.theme.colors.base, DEFAULT_THEME.colors.base)
    assert.deepEqual(r.errors, ["invalid color text"])
    for (const key of COLOR_KEYS)
        assert.ok(parseHex(r.theme.colors[key]) !== null)
})

test("validateTheme uses text for a missing textSoft", () => {
    const r = validateTheme({ id: "t", name: "T", colors: { text: "#aabbcc" } })
    assert.equal(r.theme.colors.textSoft, "#aabbcc")
})

test("validateTheme falls back per alpha value", () => {
    const r = validateTheme({ id: "a", name: "A", alpha: { surface: 5, glass: 0.5 } })
    assert.equal(r.theme.alpha.surface, DEFAULT_THEME.alpha.surface)
    assert.equal(r.theme.alpha.glass, 0.5)
    assert.deepEqual(r.errors, ["invalid alpha surface"])
})

test("tokens derive the reference colors", () => {
    const t = tokens(validateTheme(warm).theme)
    assert.equal(t.surface, "#e6181310")
    assert.equal(t.glass, "#9e181310")
    assert.equal(t.node, "#f0281f1a")
    assert.equal(t.line, "#29a85c32")
    assert.equal(t.lineStrong, "#3da85c32")
    assert.equal(t.cardLine, "#24a85c32")
    assert.equal(t.tint, "#14a85c32")
    assert.equal(t.tintSoft, "#0fa85c32")
    assert.equal(t.tintMid, "#1aa85c32")
    assert.equal(t.tintStrong, "#29a85c32")
    assert.equal(t.moon, "#66a85c32")
    assert.equal(t.fill, "#59c9702f")
    assert.equal(t.glow, "#40c9702f")
    assert.equal(t.silk, "#cce0955c")
    assert.equal(t.sonar, "#b3e0955c")
    assert.equal(t.accent, "#c9702f")
    assert.equal(t.textSoft, "#d3b9a1")
})

test("parseArgb reads #aarrggbb and #rrggbb", () => {
    assert.deepEqual(parseArgb("#80a85c32"), { a: 128, r: 168, g: 92, b: 50 })
    assert.deepEqual(parseArgb("#a85c32"), { a: 255, r: 168, g: 92, b: 50 })
    assert.equal(parseArgb("nope"), null)
})

test("mixArgb interpolates every channel and clamps t", () => {
    assert.equal(mixArgb("#ff000000", "#ffffffff", 0.5), "#ff808080")
    assert.equal(mixArgb("#c9702f", "#00000000", 0), "#ffc9702f")
    assert.equal(mixArgb("#ff000000", "#ff102030", 2), "#ff102030")
    assert.equal(mixArgb("bad", "#ff102030", 0), "#ff102030")
    assert.equal(mixArgb("bad", "also bad", 0.5), "#00000000")
})

test("mixTokens mixes every key of the target", () => {
    const out = mixTokens({ a: "#ff000000" }, { a: "#ffffffff", b: "#ff102030" }, 1)
    assert.deepEqual(out, { a: "#ffffffff", b: "#ff102030" })
    assert.equal(mixTokens({ a: "#ff000000" }, { a: "#ffffffff" }, 0).a, "#ff000000")
})

test("nextThemeId cycles through sorted ids", () => {
    assert.equal(nextThemeId(["noir", "dachshund"], "dachshund"), "noir")
    assert.equal(nextThemeId(["noir", "dachshund"], "noir"), "dachshund")
    assert.equal(nextThemeId(["b", "a"], "missing"), "a")
    assert.equal(nextThemeId([], "x"), "")
})

test("tokens expose the opaque surface as pane", () => {
    const t = tokens(validateTheme(warm).theme)
    assert.equal(t.pane, warm.colors.surface)
})

test("catalogEntry uses the theme name and fields", () => {
    const e = catalogEntry("warm", warm)
    assert.equal(e.id, "warm")
    assert.equal(e.name, warm.name)
    assert.equal(e.colors.accent, warm.colors.accent)
})

test("catalogEntry falls back to the id when the name is missing or blank", () => {
    assert.equal(catalogEntry("coal", Object.assign({}, warm, { name: undefined })).name, "coal")
    assert.equal(catalogEntry("coal", Object.assign({}, warm, { name: "  " })).name, "coal")
})

test("catalogEntry survives a broken theme", () => {
    const e = catalogEntry("junk", [1, 2])
    assert.equal(e.name, "junk")
    assert.equal(e.wallpaper, "")
    assert.equal(e.colors.accent, DEFAULT_THEME.colors.accent)
})
