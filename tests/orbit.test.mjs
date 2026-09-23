import { test } from "node:test"
import assert from "node:assert/strict"
import { GEOMETRY, baseAngle, nodePosition, linkGeometry, sonarRing, haloRotation, orderAndCap } from "../shell/lib/orbit.mjs"

const close = (a, b, eps = 1e-9) => assert.ok(Math.abs(a - b) < eps, a + " != " + b)

test("baseAngle starts at the top and spreads evenly", () => {
    close(baseAngle(0, 4), -Math.PI / 2)
    close(baseAngle(1, 4), 0)
    close(baseAngle(2, 4), Math.PI / 2)
    close(baseAngle(0, 0), -Math.PI / 2)
})

test("nodes sit on the ring and drift together", () => {
    for (const t of [0, 1.3, 7.7]) {
        const p = nodePosition(1, 5, t, 310, 282)
        const e = ((p.x - 310) / GEOMETRY.ring.rx) ** 2 + ((p.y - 282) / GEOMETRY.ring.ry) ** 2
        close(e, 1)
        const offset = p.angle - baseAngle(1, 5) - t * GEOMETRY.drift
        assert.ok(Math.abs(offset) <= GEOMETRY.sway + 1e-12)
    }
})

test("six nodes of up to 188 px never overlap while turning", () => {
    for (let t = 0; t < 200; t += 0.05) {
        const points = []
        for (let i = 0; i < 6; i++)
            points.push(nodePosition(i, 6, t, 0, 0))
        for (let i = 0; i < 6; i++) {
            for (let j = i + 1; j < 6; j++) {
                const dx = Math.abs(points[i].x - points[j].x)
                const dy = Math.abs(points[i].y - points[j].y)
                assert.ok(dx >= 188 || dy >= 48, "nodes " + i + " and " + j + " overlap at t=" + t)
            }
        }
    }
})

test("nodePosition scales radii by k", () => {
    const p = nodePosition(0, 1, 0, 0, 0, 2)
    close(p.x, Math.cos(p.angle) * GEOMETRY.ring.rx * 2)
    close(p.y, Math.sin(p.angle) * GEOMETRY.ring.ry * 2)
})

test("linkGeometry starts outside the core and ends before the node", () => {
    const g = linkGeometry(0, 0, 200, 0, 59, 0, 0)
    close(g.sx, 74)
    close(g.sy, 0)
    close(g.ex, 170)
    close(g.ey, 0)
    close(g.qx, 122)
    close(g.qy, 0)
})

test("linkGeometry sways the control point perpendicular to the link", () => {
    const t = Math.PI / 2 / GEOMETRY.silkSpeed
    const g = linkGeometry(0, 0, 200, 0, 59, t, 0)
    close(g.qx, 122)
    close(g.qy, GEOMETRY.silkSway)
})

test("sonarRing grows and fades over its period", () => {
    assert.deepEqual(sonarRing(0, 0, false), { scale: 1, opacity: 0.8 })
    const half = sonarRing(1.1, 0, false)
    close(half.scale, 1.85)
    close(half.opacity, 0.4)
    const scanHalf = sonarRing(0.365, 0, true)
    close(scanHalf.scale, 1.85)
    const third = sonarRing(0, 1, false)
    close(third.scale, 1 + GEOMETRY.sonar.growth / 3)
})

test("haloRotation turns 40 degrees per second and wraps", () => {
    close(haloRotation(0), 0)
    close(haloRotation(10), 40)
    close(haloRotation(9.5), 20)
    assert.ok(haloRotation(-1) >= 0 && haloRotation(-1) < 360)
})

test("orderAndCap sorts connected, then known, then signal, then name", () => {
    const items = [
        { name: "b", connected: false, known: false, signal: 0.9 },
        { name: "a", connected: false, known: false, signal: 0.9 },
        { name: "known", connected: false, known: true },
        { name: "live", connected: true, known: true },
        { name: "weak", connected: false, known: false, signal: 0.1 }
    ]
    const out = orderAndCap(items)
    assert.deepEqual(out.visible.map(i => i.name), ["live", "known", "a", "b", "weak"])
    assert.equal(out.overflow, 0)
    assert.equal(items[0].name, "b")
})

test("orderAndCap shows up to five items, or four and a +N more slot", () => {
    const items = []
    for (let i = 0; i < 11; i++)
        items.push({ name: "d" + String(i).padStart(2, "0"), connected: false, known: false })
    const out = orderAndCap(items)
    assert.equal(out.visible.length, 4)
    assert.equal(out.overflow, 7)
    const five = orderAndCap(items.slice(0, 5))
    assert.equal(five.visible.length, 5)
    assert.equal(five.overflow, 0)
    assert.equal(orderAndCap(items, 20).overflow, 0)
})
