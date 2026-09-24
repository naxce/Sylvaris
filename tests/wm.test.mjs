import { test } from "node:test"
import assert from "node:assert/strict"
import { translate, niriReduce, niriWorkspaces } from "../shell/lib/wm.mjs"

test("Hyprland with a Lua config gets Lua dispatchers", () => {
    assert.deepEqual(translate("hyprland", true, "workspace", ["3"]), { via: "hyprland", command: "hl.dsp.focus({ workspace = 3 })" })
    assert.equal(translate("hyprland", true, "workspace", ["next"]).command, "hl.dsp.focus({ workspace = \"e+1\" })")
    assert.equal(translate("hyprland", true, "move-to", ["2"]).command, "hl.dsp.window.move({ workspace = 2 })")
    assert.equal(translate("hyprland", true, "focus", ["left"]).command, "hl.dsp.focus({ direction = \"left\" })")
    assert.equal(translate("hyprland", true, "float", []).command, "hl.dsp.window.float({ action = \"toggle\" })")
    assert.deepEqual(translate("hyprland", true, "reload", []), { via: "exec", command: ["hyprctl", "reload"] })
})

test("Hyprland with a classic config gets classic dispatchers", () => {
    assert.equal(translate("hyprland", false, "workspace", ["prev"]).command, "workspace e-1")
    assert.equal(translate("hyprland", false, "move", ["up"]).command, "movewindow u")
    assert.equal(translate("hyprland", false, "close", []).command, "killactive")
})

test("sway gets i3 commands", () => {
    assert.deepEqual(translate("sway", false, "workspace", ["4"]), { via: "i3", command: "workspace number 4" })
    assert.equal(translate("sway", false, "move-to", ["next"]).command, "move container to workspace next_on_output")
    assert.equal(translate("sway", false, "fullscreen", []).command, "fullscreen toggle")
})

test("niri gets niri msg actions", () => {
    assert.deepEqual(translate("niri", false, "workspace", ["2"]).command, ["niri", "msg", "action", "focus-workspace", "2"])
    assert.deepEqual(translate("niri", false, "workspace", ["next"]).command, ["niri", "msg", "action", "focus-workspace-down"])
    assert.deepEqual(translate("niri", false, "focus", ["left"]).command, ["niri", "msg", "action", "focus-column-left"])
    assert.deepEqual(translate("niri", false, "move", ["down"]).command, ["niri", "msg", "action", "move-window-down"])
    assert.deepEqual(translate("niri", false, "quit", []).command, ["niri", "msg", "action", "quit", "--skip-confirmation"])
})

test("exec runs through a shell everywhere", () => {
    assert.deepEqual(translate("niri", false, "exec", ["kitty", "--hold"]), { via: "exec", command: ["sh", "-c", "kitty --hold"] })
})

test("bad input is refused with a clear message", () => {
    assert.throws(() => translate("niri", false, "fly", []), /unknown compositor action: fly/)
    assert.throws(() => translate("niri", false, "workspace", ["x"]), /workspace number/)
    assert.throws(() => translate("niri", false, "focus", ["sideways"]), /left, right, up or down/)
    assert.throws(() => translate("unknown", false, "close", []), /no supported compositor/)
    assert.throws(() => translate("sway", false, "exec", []), /usage/)
})

test("the niri reducer follows workspace and window events", () => {
    let s = { workspaces: [], windows: [] }
    s = niriReduce(s, { WorkspacesChanged: { workspaces: [
        { id: 1, idx: 1, name: null, output: "DP-1", is_active: true, is_focused: true, is_urgent: false },
        { id: 2, idx: 2, name: "web", output: "DP-1", is_active: false, is_focused: false, is_urgent: false },
        { id: 3, idx: 1, name: null, output: "HDMI-A-1", is_active: true, is_focused: false, is_urgent: false }
    ] } })
    s = niriReduce(s, { WindowsChanged: { windows: [{ id: 10, workspace_id: 1, is_focused: true }] } })
    s = niriReduce(s, { WindowOpenedOrChanged: { window: { id: 11, workspace_id: 2, is_focused: true } } })
    assert.deepEqual(s.windows.map(w => [w.id, w.is_focused]), [[10, false], [11, true]])
    s = niriReduce(s, { WorkspaceActivated: { id: 2, focused: true } })
    const ws = niriWorkspaces(s)
    assert.deepEqual(ws.map(w => [w.output, w.name, w.active, w.focused, w.windows]), [
        ["DP-1", "1", false, false, 1],
        ["DP-1", "web", true, true, 1],
        ["HDMI-A-1", "1", true, false, 0]
    ])
    s = niriReduce(s, { WindowClosed: { id: 10 } })
    s = niriReduce(s, { WorkspaceUrgencyChanged: { id: 3, urgent: true } })
    assert.equal(niriWorkspaces(s)[0].windows, 0)
    assert.equal(niriWorkspaces(s)[2].urgent, true)
    assert.equal(niriReduce(s, { OverviewOpenedOrClosed: { is_open: true } }), s)
})
