export const FILTERS = ["none", "grayscale", "invert", "protanopia", "deuteranopia", "tritanopia"]
export const DEFAULT_ACCESS = { zoom: 1, filter: "none", text: 1, cursor: 0 }

export function validateAccess(raw) {
    const v = raw !== null && typeof raw === "object" && !Array.isArray(raw) ? raw : {}
    const num = (x, lo, hi, d) => typeof x === "number" && x >= lo && x <= hi ? x : d
    return Object.assign({}, v, {
        zoom: num(v.zoom, 1, 5, DEFAULT_ACCESS.zoom),
        filter: FILTERS.indexOf(v.filter) >= 0 ? v.filter : DEFAULT_ACCESS.filter,
        text: num(v.text, 0.8, 1.6, DEFAULT_ACCESS.text),
        cursor: Number.isInteger(v.cursor) && (v.cursor === 0 || v.cursor >= 16 && v.cursor <= 128) ? v.cursor : DEFAULT_ACCESS.cursor
    })
}

export function hyprCommands(usingLua, a, shaderDir) {
    const shader = a.filter === "none" ? "" : shaderDir + "/" + a.filter + ".frag"
    if (usingLua)
        return [
            ["eval", "hl.config({ cursor = { zoom_factor = " + a.zoom + " } })"],
            ["eval", "hl.config({ decoration = { screen_shader = \"" + shader + "\" } })"]
        ]
    return [
        ["keyword", "cursor:zoom_factor", String(a.zoom)],
        ["keyword", "decoration:screen_shader", shader === "" ? "[[EMPTY]]" : shader]
    ]
}

export function supports(name) {
    const hypr = name === "hyprland"
    return { zoom: hypr, filter: hypr }
}
