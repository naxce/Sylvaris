export const DIRECTIONS = ["left", "right", "up", "down"]

function target(arg) {
    const s = String(arg === undefined ? "" : arg)
    if (s === "next" || s === "prev")
        return s
    if (/^[0-9]+$/.test(s))
        return Number(s)
    throw new Error("expected a workspace number, next or prev")
}

function direction(arg) {
    if (DIRECTIONS.indexOf(arg) < 0)
        throw new Error("expected left, right, up or down")
    return arg
}

function lua(verb, arg) {
    switch (verb) {
    case "workspace": {
        const t = target(arg)
        return "hl.dsp.focus({ workspace = " + (t === "next" ? "\"e+1\"" : t === "prev" ? "\"e-1\"" : t) + " })"
    }
    case "move-to": {
        const t = target(arg)
        return "hl.dsp.window.move({ workspace = " + (t === "next" ? "\"e+1\"" : t === "prev" ? "\"e-1\"" : t) + " })"
    }
    case "focus":
        return "hl.dsp.focus({ direction = \"" + direction(arg) + "\" })"
    case "move":
        return "hl.dsp.window.move({ direction = \"" + direction(arg) + "\" })"
    case "close":
        return "hl.dsp.window.close()"
    case "fullscreen":
        return "hl.dsp.window.fullscreen({ action = \"toggle\", mode = \"fullscreen\" })"
    case "float":
        return "hl.dsp.window.float({ action = \"toggle\" })"
    case "quit":
        return "hl.dsp.exit()"
    }
    return null
}

function hyprClassic(verb, arg) {
    const dir = { left: "l", right: "r", up: "u", down: "d" }
    switch (verb) {
    case "workspace": {
        const t = target(arg)
        return "workspace " + (t === "next" ? "e+1" : t === "prev" ? "e-1" : t)
    }
    case "move-to": {
        const t = target(arg)
        return "movetoworkspace " + (t === "next" ? "e+1" : t === "prev" ? "e-1" : t)
    }
    case "focus":
        return "movefocus " + dir[direction(arg)]
    case "move":
        return "movewindow " + dir[direction(arg)]
    case "close":
        return "killactive"
    case "fullscreen":
        return "fullscreen 0"
    case "float":
        return "togglefloating"
    case "quit":
        return "exit"
    }
    return null
}

function sway(verb, arg) {
    switch (verb) {
    case "workspace": {
        const t = target(arg)
        return t === "next" ? "workspace next_on_output" : t === "prev" ? "workspace prev_on_output" : "workspace number " + t
    }
    case "move-to": {
        const t = target(arg)
        return t === "next" ? "move container to workspace next_on_output" : t === "prev" ? "move container to workspace prev_on_output" : "move container to workspace number " + t
    }
    case "focus":
        return "focus " + direction(arg)
    case "move":
        return "move " + direction(arg)
    case "close":
        return "kill"
    case "fullscreen":
        return "fullscreen toggle"
    case "float":
        return "floating toggle"
    case "reload":
        return "reload"
    case "quit":
        return "exit"
    }
    return null
}

function niri(verb, arg) {
    switch (verb) {
    case "workspace": {
        const t = target(arg)
        return t === "next" ? ["focus-workspace-down"] : t === "prev" ? ["focus-workspace-up"] : ["focus-workspace", String(t)]
    }
    case "move-to": {
        const t = target(arg)
        return t === "next" ? ["move-window-to-workspace-down"] : t === "prev" ? ["move-window-to-workspace-up"] : ["move-window-to-workspace", String(t)]
    }
    case "focus":
        return { left: ["focus-column-left"], right: ["focus-column-right"], up: ["focus-window-up"], down: ["focus-window-down"] }[direction(arg)]
    case "move":
        return { left: ["move-column-left"], right: ["move-column-right"], up: ["move-window-up"], down: ["move-window-down"] }[direction(arg)]
    case "close":
        return ["close-window"]
    case "fullscreen":
        return ["fullscreen-window"]
    case "float":
        return ["toggle-window-floating"]
    case "reload":
        return ["load-config-file"]
    case "quit":
        return ["quit", "--skip-confirmation"]
    }
    return null
}

export const VERBS = ["workspace", "move-to", "focus", "move", "close", "fullscreen", "float", "exec", "reload", "quit"]

export function translate(name, usingLua, verb, args) {
    if (VERBS.indexOf(verb) < 0)
        throw new Error("unknown compositor action: " + verb)
    const arg = args[0]
    if (verb === "exec") {
        if (args.length === 0)
            throw new Error("usage: wm exec <command>")
        return { via: "exec", command: ["sh", "-c", args.join(" ")] }
    }
    if (name === "hyprland") {
        if (verb === "reload")
            return { via: "exec", command: ["hyprctl", "reload"] }
        return { via: "hyprland", command: usingLua ? lua(verb, arg) : hyprClassic(verb, arg) }
    }
    if (name === "sway")
        return { via: "i3", command: sway(verb, arg) }
    if (name === "niri")
        return { via: "exec", command: ["niri", "msg", "action"].concat(niri(verb, arg)) }
    throw new Error("no supported compositor is running")
}

function byId(list) {
    const out = {}
    for (const x of list)
        out[x.id] = x
    return out
}

export function niriReduce(state, event) {
    const s = { workspaces: state.workspaces, windows: state.windows }
    const key = Object.keys(event)[0]
    const e = event[key]
    if (key === "WorkspacesChanged")
        s.workspaces = e.workspaces
    else if (key === "WorkspaceActivated") {
        const ws = byId(s.workspaces)[e.id]
        const output = ws ? ws.output : null
        s.workspaces = s.workspaces.map(w => Object.assign({}, w, {
            is_active: w.id === e.id ? true : w.output === output ? false : w.is_active,
            is_focused: e.focused ? w.id === e.id : w.is_focused
        }))
    } else if (key === "WorkspaceUrgencyChanged")
        s.workspaces = s.workspaces.map(w => w.id === e.id ? Object.assign({}, w, { is_urgent: e.urgent }) : w)
    else if (key === "WorkspaceActiveWindowChanged")
        s.workspaces = s.workspaces.map(w => w.id === e.workspace_id ? Object.assign({}, w, { active_window_id: e.active_window_id }) : w)
    else if (key === "WindowsChanged")
        s.windows = e.windows
    else if (key === "WindowOpenedOrChanged") {
        const w = e.window
        const rest = s.windows.filter(x => x.id !== w.id).map(x => w.is_focused ? Object.assign({}, x, { is_focused: false }) : x)
        s.windows = rest.concat([w])
    } else if (key === "WindowClosed")
        s.windows = s.windows.filter(x => x.id !== e.id)
    else if (key === "WindowFocusChanged")
        s.windows = s.windows.map(x => Object.assign({}, x, { is_focused: x.id === e.id }))
    else if (key === "WindowUrgencyChanged")
        s.windows = s.windows.map(x => x.id === e.id ? Object.assign({}, x, { is_urgent: e.urgent }) : x)
    else
        return state
    return s
}

export function niriWorkspaces(state) {
    const counts = {}
    for (const w of state.windows)
        counts[w.workspace_id] = (counts[w.workspace_id] || 0) + 1
    return state.workspaces.map(w => ({
        id: String(w.id),
        index: w.idx,
        name: w.name || String(w.idx),
        output: w.output || "",
        active: w.is_active,
        focused: w.is_focused,
        urgent: w.is_urgent,
        windows: counts[w.id] || 0
    })).sort(order)
}

export function order(a, b) {
    return a.output < b.output ? -1 : a.output > b.output ? 1 : a.index - b.index
}
