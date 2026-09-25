export const DELAYS = [0, 3, 5, 10]
export const DEFAULT_CAPTURE = { folder: "~/Pictures/Screenshots", videos: "~/Videos/Recordings", copy: true, save: true, delay: 0, audio: false }

function box(x, y, w, h) {
    return Math.round(x) + "," + Math.round(y) + " " + Math.round(w) + "x" + Math.round(h)
}

export function hyprRects(clients, monitors) {
    const shown = monitors.map(m => m.activeWorkspace && m.activeWorkspace.id)
    return clients.filter(c => c.mapped !== false && !c.hidden && shown.indexOf(c.workspace && c.workspace.id) >= 0).map(c => box(c.at[0], c.at[1], c.size[0], c.size[1]))
}

export function swayRects(tree) {
    const out = []
    const walk = (n, visible) => {
        const v = n.type === "workspace" ? n.visible === true : visible
        if ((n.type === "con" || n.type === "floating_con") && n.pid && v && n.visible !== false)
            out.push(box(n.rect.x, n.rect.y, n.rect.width, n.rect.height))
        for (const c of (n.nodes || []).concat(n.floating_nodes || []))
            walk(c, v)
    }
    walk(tree, true)
    return out
}

function pad(n) {
    return String(n).padStart(2, "0")
}

export function fileName(kind, d) {
    const stamp = d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) + " " + pad(d.getHours()) + "-" + pad(d.getMinutes()) + "-" + pad(d.getSeconds())
    return kind === "video" ? "Recording " + stamp + ".mp4" : "Screenshot " + stamp + ".png"
}

export function elapsed(ms) {
    const s = Math.max(0, Math.floor(ms / 1000))
    const h = Math.floor(s / 3600)
    const m = Math.floor(s % 3600 / 60)
    return (h > 0 ? h + ":" + pad(m) : String(m)) + ":" + pad(s % 60)
}

export function expand(path, home) {
    return path.indexOf("~/") === 0 ? home + path.slice(1) : path
}

export function validateCapture(raw) {
    const v = raw !== null && typeof raw === "object" && !Array.isArray(raw) ? raw : {}
    const str = (x, d) => typeof x === "string" && x.trim() !== "" ? x : d
    const copy = v.copy !== false
    return Object.assign({}, v, {
        folder: str(v.folder, DEFAULT_CAPTURE.folder),
        videos: str(v.videos, DEFAULT_CAPTURE.videos),
        copy: copy,
        save: v.save !== false || !copy,
        delay: DELAYS.indexOf(v.delay) >= 0 ? v.delay : 0,
        audio: v.audio === true
    })
}
