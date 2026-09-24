export function origin(corner) {
    const c = String(corner || "")
    const v = c.indexOf("top") === 0 ? 0 : c.indexOf("bottom") === 0 ? 1 : 0.5
    const h = c.indexOf("left") >= 0 ? 0 : c.indexOf("right") >= 0 ? 1 : 0.5
    return { h: h, v: v }
}

export function scaledRect(x, y, w, h, corner, s, dy) {
    const o = origin(corner)
    const nw = w * s
    const nh = h * s
    return { x: x + (w - nw) * o.h, y: y + (h - nh) * o.v + dy, w: nw, h: nh }
}

export function rise(corner) {
    return origin(corner).v === 1 ? 1 : -1
}

export function stagger(phase, index, count, spread) {
    const n = Math.max(1, count)
    const s = Math.max(0, Math.min(0.9, spread === undefined ? 0.35 : spread))
    const start = s * index / n
    const t = (phase - start) / (1 - s)
    return Math.max(0, Math.min(1, t))
}
