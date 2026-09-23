export const GEOMETRY = {
    ring: { rx: 215, ry: 190 },
    slots: 5,
    sway: 0.02,
    swaySpeed: 0.5,
    drift: 0.04,
    silkSway: 14,
    silkSpeed: 1.6,
    linkStartGap: 15,
    linkEndX: 30,
    linkEndY: 22,
    sonar: { count: 3, growth: 1.7, opacity: 0.8, period: 2.2, scanPeriod: 0.73 },
    haloDegPerSec: 40
}

export function baseAngle(index, count) {
    return -Math.PI / 2 + (count > 0 ? index / count : 0) * Math.PI * 2
}

export function nodePosition(index, count, t, cx, cy, k) {
    const scale = k === undefined ? 1 : k
    const g = GEOMETRY.ring
    const angle = baseAngle(index, count) + t * GEOMETRY.drift + Math.sin(t * GEOMETRY.swaySpeed + index) * GEOMETRY.sway
    return { x: cx + Math.cos(angle) * g.rx * scale, y: cy + Math.sin(angle) * g.ry * scale, angle: angle }
}

export function linkGeometry(cx, cy, x, y, coreRadius, t, index, k) {
    const scale = k === undefined ? 1 : k
    const dx = x - cx
    const dy = y - cy
    const len = Math.hypot(dx, dy) || 1
    const ux = dx / len
    const uy = dy / len
    const r0 = coreRadius + GEOMETRY.linkStartGap
    const sx = cx + ux * r0
    const sy = cy + uy * r0
    const ex = x - ux * GEOMETRY.linkEndX
    const ey = y - uy * GEOMETRY.linkEndY
    const w = Math.sin(t * GEOMETRY.silkSpeed + index) * GEOMETRY.silkSway * scale
    return { sx: sx, sy: sy, qx: (sx + ex) / 2 - uy * w, qy: (sy + ey) / 2 + ux * w, ex: ex, ey: ey }
}

export function sonarRing(t, j, scanning) {
    const s = GEOMETRY.sonar
    const period = scanning ? s.scanPeriod : s.period
    const u = (((t / period + j / s.count) % 1) + 1) % 1
    return { scale: 1 + u * s.growth, opacity: (1 - u) * s.opacity }
}

export function haloRotation(t) {
    return (((t * GEOMETRY.haloDegPerSec) % 360) + 360) % 360
}

function signalOf(item) {
    return typeof item.signal === "number" ? item.signal : -1
}

function compare(a, b) {
    const c = (b.connected === true) - (a.connected === true)
    if (c !== 0)
        return c
    const k = (b.known === true) - (a.known === true)
    if (k !== 0)
        return k
    const s = signalOf(b) - signalOf(a)
    if (s !== 0)
        return s
    return String(a.name).localeCompare(String(b.name))
}

export function orderAndCap(items, slots) {
    const limit = slots === undefined ? GEOMETRY.slots : slots
    const sorted = items.slice().sort(compare)
    if (sorted.length <= limit)
        return { visible: sorted, overflow: 0 }
    return { visible: sorted.slice(0, limit - 1), overflow: sorted.length - (limit - 1) }
}
