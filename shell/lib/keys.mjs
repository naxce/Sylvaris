export const ACTIONS = [
    { id: "pad toggle", label: "Launcher" },
    { id: "center toggle", label: "Control center" },
    { id: "switcher next", label: "Next window" },
    { id: "switcher prev", label: "Previous window" },
    { id: "clock toggle", label: "Calendar and weather" },
    { id: "notify toggle", label: "Notifications" },
    { id: "clip toggle", label: "Clipboard history" },
    { id: "capture toggle", label: "Capture panel" },
    { id: "capture shot area", label: "Screenshot of an area" },
    { id: "capture shot window", label: "Screenshot of a window" },
    { id: "capture shot screen", label: "Screenshot of the screen" },
    { id: "capture record area", label: "Record an area" },
    { id: "capture stop", label: "Stop recording" },
    { id: "lock now", label: "Lock the screen" },
    { id: "power toggle", label: "Power menu" },
    { id: "theme toggle", label: "Theme picker" },
    { id: "theme cycle", label: "Next theme" },
    { id: "paper toggle", label: "Wallpapers" },
    { id: "diver toggle", label: "Diver planner" },
    { id: "media toggle", label: "Media player" },
    { id: "settings toggle", label: "Settings" },
    { id: "access toggle", label: "Accessibility" },
    { id: "access zoom in", label: "Zoom in" },
    { id: "access zoom out", label: "Zoom out" },
    { id: "dnd toggle", label: "Do not disturb" },
    { id: "nightlight toggle", label: "Night light" }
]

const MODS = ["SUPER", "CTRL", "ALT", "SHIFT"]
const ALIAS = { WIN: "SUPER", META: "SUPER", MOD4: "SUPER", CONTROL: "CTRL", MOD1: "ALT" }

export function normalize(text) {
    const parts = String(text || "").split("+").map(s => s.trim()).filter(s => s !== "")
    if (parts.length === 0)
        return ""
    const key = parts[parts.length - 1]
    const mods = parts.slice(0, -1).map(m => ALIAS[m.toUpperCase()] || m.toUpperCase())
    if (mods.some(m => MODS.indexOf(m) < 0) || MODS.indexOf(key.toUpperCase()) >= 0 || !/^[A-Za-z0-9_]+$/.test(key))
        return ""
    const ordered = MODS.filter(m => mods.indexOf(m) >= 0)
    return ordered.concat([key.length === 1 ? key.toUpperCase() : key]).join("+")
}

export function validateKeybinds(raw) {
    const out = {}
    if (raw === null || typeof raw !== "object" || Array.isArray(raw))
        return out
    const known = ACTIONS.map(a => a.id)
    for (const id of Object.keys(raw)) {
        const combo = normalize(raw[id])
        if (known.indexOf(id) >= 0 && combo !== "")
            out[id] = combo
    }
    return out
}

function split(combo) {
    const parts = combo.split("+")
    return { mods: parts.slice(0, -1), key: parts[parts.length - 1] }
}

const SWAY = { SUPER: "Mod4", CTRL: "Ctrl", ALT: "Mod1", SHIFT: "Shift" }

export function bindArgs(compositor, usingLua, combo, action) {
    const c = split(combo)
    const cmd = "sylvaris " + action
    if (compositor === "hyprland")
        return usingLua ? ["hyprctl", "eval", "hl.bind(\"" + c.mods.concat([c.key]).join(" + ") + "\", hl.dsp.exec_cmd(\"" + cmd + "\"))"] : ["hyprctl", "keyword", "bind", c.mods.join(" ") + "," + c.key + ",exec," + cmd]
    if (compositor === "sway")
        return ["swaymsg", "bindsym", c.mods.map(m => SWAY[m]).concat([c.key.length === 1 ? c.key.toLowerCase() : c.key]).join("+"), "exec", cmd]
    return null
}

export function unbindArgs(compositor, usingLua, combo) {
    const c = split(combo)
    if (compositor === "hyprland")
        return usingLua ? ["hyprctl", "eval", "hl.unbind(\"" + c.mods.concat([c.key]).join(" + ") + "\")"] : ["hyprctl", "keyword", "unbind", c.mods.join(" ") + "," + c.key]
    if (compositor === "sway")
        return ["swaymsg", "unbindsym", c.mods.map(m => SWAY[m]).concat([c.key.length === 1 ? c.key.toLowerCase() : c.key]).join("+")]
    return null
}

const SPECIAL = {
    0x20: "space", 0x01000004: "Return", 0x01000005: "Return", 0x01000001: "Tab", 0x01000003: "BackSpace",
    0x01000007: "Delete", 0x01000006: "Insert", 0x01000010: "Home", 0x01000011: "End", 0x01000016: "Prior", 0x01000017: "Next",
    0x01000009: "Print", 0x01000012: "Left", 0x01000013: "Up", 0x01000014: "Right", 0x01000015: "Down"
}

export function keyName(code, text) {
    if (SPECIAL[code])
        return SPECIAL[code]
    if (code >= 0x01000030 && code <= 0x01000047)
        return "F" + (code - 0x01000030 + 1)
    if (code >= 0x30 && code <= 0x39 || code >= 0x41 && code <= 0x5a)
        return String.fromCharCode(code)
    return ""
}

export function diff(applied, wanted) {
    const unbind = []
    const bind = []
    for (const id of Object.keys(applied))
        if (wanted[id] !== applied[id])
            unbind.push(applied[id])
    for (const id of Object.keys(wanted))
        if (applied[id] !== wanted[id])
            bind.push([wanted[id], id])
    return { unbind: unbind, bind: bind }
}
