import { test } from "node:test"
import assert from "node:assert/strict"
import { checkManifest, parseScan, skeleton, validatePlugins, DEFAULT_PLUGINS, isPluginModule, KINDS } from "../shell/lib/plugins.mjs"
import { validateBar } from "../shell/lib/bar.mjs"

const good = { id: "uptime", name: "Uptime", version: "1.0.0", kind: "bar", entry: "Plugin.qml", description: "Shows uptime", author: "ada" }

test("checkManifest accepts a clean manifest and explains what is wrong otherwise", () => {
    assert.deepEqual(checkManifest(good, "uptime"), { ok: true, error: "", manifest: good })
    assert.equal(checkManifest(Object.assign({}, good, { id: "Up Time" }), "uptime").error, "id must be lowercase letters, digits and dashes")
    assert.equal(checkManifest(good, "other").error, "id uptime does not match its folder other")
    assert.equal(checkManifest(Object.assign({}, good, { kind: "rootkit" }), "uptime").error, "kind must be one of " + KINDS.join(", "))
    assert.equal(checkManifest(Object.assign({}, good, { entry: "../../x.qml" }), "uptime").error, "entry must be a .qml file inside the plugin folder")
    assert.equal(checkManifest(Object.assign({}, good, { entry: "/etc/x.qml" }), "uptime").error, "entry must be a .qml file inside the plugin folder")
    assert.equal(checkManifest(Object.assign({}, good, { name: "" }), "uptime").error, "name is required")
    assert.equal(checkManifest("nope", "uptime").error, "plugin.json must be an object")
})

test("parseScan reads the plugin folder listing", () => {
    const blob = "@@/p/uptime\n" + JSON.stringify(good) + "\n@@/p/broken\n{not json\n@@/p/empty\n"
    const list = parseScan(blob)
    assert.equal(list.length, 3)
    assert.equal(list[0].ok, true)
    assert.equal(list[0].dir, "/p/uptime")
    assert.equal(list[1].error, "plugin.json is not valid JSON")
    assert.equal(list[2].error, "plugin.json is missing")
})

test("skeleton makes a working starter plugin", () => {
    const files = skeleton("my-widget", "bar")
    assert.equal(JSON.parse(files["plugin.json"]).id, "my-widget")
    assert.ok(files["Plugin.qml"].indexOf("property var api") >= 0)
    assert.equal(checkManifest(JSON.parse(files["plugin.json"]), "my-widget").ok, true)
})

test("plugins settings and bar modules", () => {
    assert.deepEqual(validatePlugins({}), DEFAULT_PLUGINS)
    assert.deepEqual(validatePlugins({ enabled: { uptime: true, "Bad!": true, x: "yes" } }).enabled, { uptime: true })
    assert.equal(isPluginModule("plugin:uptime"), true)
    assert.equal(isPluginModule("plugin:../x"), false)
    assert.deepEqual(validateBar({ left: ["pad", "plugin:uptime", "plugin:Bad!"] }).left, ["pad", "plugin:uptime"])
})
