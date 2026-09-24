export const MODULES = ["pad", "workspaces", "window", "clock", "media", "tray", "audio", "network", "bluetooth", "battery", "notifications", "center", "power"]
export const POSITIONS = ["top", "bottom", "left", "right"]
export const STYLES = ["islands", "slab"]

export const DEFAULT_BAR = {
    enabled: true,
    floating: true,
    position: "top",
    style: "islands",
    left: ["pad", "workspaces", "window"],
    center: ["clock"],
    right: ["media", "tray", "audio", "network", "bluetooth", "battery", "notifications", "center", "power"]
}

export const DEFAULT_DECK = { enabled: false, pinned: [], pad: "start", power: "none", effect: "bloom", autohide: false, reserve: true, size: 56 }
export const DECK_EFFECTS = ["bloom", "magnify", "none"]

function isObject(v) {
    return v !== null && typeof v === "object" && !Array.isArray(v)
}

function modules(v, fallback, taken) {
    if (!Array.isArray(v))
        return fallback.filter(m => !taken[m] && (taken[m] = true))
    const out = []
    for (const m of v) {
        if (MODULES.indexOf(m) >= 0 && !taken[m]) {
            taken[m] = true
            out.push(m)
        }
    }
    return out
}

export function validateBar(raw) {
    const b = isObject(raw) ? raw : {}
    const taken = {}
    return Object.assign({}, b, {
        enabled: b.enabled !== false,
        floating: b.floating !== false,
        position: POSITIONS.indexOf(b.position) >= 0 ? b.position : DEFAULT_BAR.position,
        style: STYLES.indexOf(b.style) >= 0 ? b.style : DEFAULT_BAR.style,
        left: modules(b.left, DEFAULT_BAR.left, taken),
        center: modules(b.center, DEFAULT_BAR.center, taken),
        right: modules(b.right, DEFAULT_BAR.right, taken)
    })
}

export function validateDeck(raw) {
    const d = isObject(raw) ? raw : {}
    const pinned = Array.isArray(d.pinned) ? d.pinned.filter((id, i, a) => typeof id === "string" && id !== "" && a.indexOf(id) === i) : []
    return Object.assign({}, d, {
        enabled: d.enabled === true,
        pinned: pinned,
        pad: ["start", "end", "none"].indexOf(d.pad) >= 0 ? d.pad : DEFAULT_DECK.pad,
        power: ["start", "end", "none"].indexOf(d.power) >= 0 ? d.power : DEFAULT_DECK.power,
        effect: DECK_EFFECTS.indexOf(d.effect) >= 0 ? d.effect : d.magnify === true ? "magnify" : DEFAULT_DECK.effect,
        autohide: d.autohide === true,
        reserve: d.reserve !== false,
        size: Number.isInteger(d.size) && d.size >= 36 && d.size <= 96 ? d.size : DEFAULT_DECK.size
    })
}

export function deckItems(pinned, windows, entryOf) {
    const items = pinned.map(id => ({ id: id, pinned: true, windows: [] }))
    const index = {}
    items.forEach((it, i) => index[it.id] = i)
    windows.forEach((w, wi) => {
        const id = entryOf(w.appId) || w.appId || "unknown"
        if (index[id] === undefined) {
            index[id] = items.length
            items.push({ id: id, pinned: false, windows: [] })
        }
        items[index[id]].windows.push(wi)
    })
    return items
}

export function nextWindow(indices, windows) {
    if (indices.length === 0)
        return -1
    const at = indices.findIndex(i => windows[i].activated)
    return at < 0 ? indices[0] : indices[(at + 1) % indices.length]
}

export function unused(bar) {
    return MODULES.filter(m => bar.left.indexOf(m) < 0 && bar.center.indexOf(m) < 0 && bar.right.indexOf(m) < 0)
}

export function shift(list, index, delta) {
    const to = index + delta
    if (index < 0 || index >= list.length || to < 0 || to >= list.length)
        return list.slice()
    const out = list.slice()
    out.splice(to, 0, out.splice(index, 1)[0])
    return out
}

export function togglePin(pinned, id) {
    return pinned.indexOf(id) >= 0 ? pinned.filter(p => p !== id) : pinned.concat([id])
}

export function magnify(distance, reach) {
    const d = Math.abs(distance)
    if (d >= reach)
        return 1
    return 1 + 0.45 * Math.pow(Math.cos(d / reach * Math.PI / 2), 2)
}

export function vertical(position) {
    return position === "left" || position === "right"
}

export function drawerArrow(position) {
    return { top: "down", bottom: "up", left: "right", right: "left" }[position] || "down"
}

export function popupCorner(position, side) {
    if (position === "bottom")
        return side === "left" ? "bottom-left" : side === "center" ? "bottom-center" : "bottom-right"
    if (position === "left")
        return "top-left"
    if (position === "right")
        return "top-right"
    return side === "left" ? "top-left" : side === "center" ? "top-center" : "top-right"
}
