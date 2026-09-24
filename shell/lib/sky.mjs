const RAD = Math.PI / 180
const DAY_MS = 86400000
const J1970 = 2440588
const J2000 = 2451545
const OBLIQUITY = RAD * 23.4397
const SUN_DISTANCE = 149598000

export const SUN_HORIZON = -0.833
export const MOON_HORIZON = 0.133

export const PHASES = ["New moon", "Waxing crescent", "First quarter", "Waxing gibbous", "Full moon", "Waning gibbous", "Last quarter", "Waning crescent"]

function toDays(ms) {
    return ms / DAY_MS - 0.5 + J1970 - J2000
}

function rightAscension(l, b) {
    return Math.atan2(Math.sin(l) * Math.cos(OBLIQUITY) - Math.tan(b) * Math.sin(OBLIQUITY), Math.cos(l))
}

function declination(l, b) {
    return Math.asin(Math.sin(b) * Math.cos(OBLIQUITY) + Math.cos(b) * Math.sin(OBLIQUITY) * Math.sin(l))
}

function siderealTime(d, lw) {
    return RAD * (280.16 + 360.9856235 * d) - lw
}

function sunCoords(d) {
    const m = RAD * (357.5291 + 0.98560028 * d)
    const c = RAD * (1.9148 * Math.sin(m) + 0.02 * Math.sin(2 * m) + 0.0003 * Math.sin(3 * m))
    const l = m + c + RAD * 102.9372 + Math.PI
    return { dec: declination(l, 0), ra: rightAscension(l, 0) }
}

function moonCoords(d) {
    const ml = RAD * (218.316 + 13.176396 * d)
    const m = RAD * (134.963 + 13.064993 * d)
    const f = RAD * (93.272 + 13.22935 * d)
    const l = ml + RAD * 6.289 * Math.sin(m)
    const b = RAD * 5.128 * Math.sin(f)
    return { ra: rightAscension(l, b), dec: declination(l, b), dist: 385001 - 20905 * Math.cos(m) }
}

function horizontal(ms, lat, lon, c) {
    const d = toDays(ms)
    const phi = RAD * lat
    const h = siderealTime(d, RAD * -lon) - c.ra
    return {
        altitude: Math.asin(Math.sin(phi) * Math.sin(c.dec) + Math.cos(phi) * Math.cos(c.dec) * Math.cos(h)) / RAD,
        azimuth: (Math.atan2(Math.sin(h), Math.cos(h) * Math.sin(phi) - Math.tan(c.dec) * Math.cos(phi)) / RAD + 180) % 360
    }
}

export function sunPosition(ms, lat, lon) {
    return horizontal(ms, lat, lon, sunCoords(toDays(ms)))
}

export function moonPosition(ms, lat, lon) {
    return horizontal(ms, lat, lon, moonCoords(toDays(ms)))
}

export function moonIllumination(ms) {
    const d = toDays(ms)
    const s = sunCoords(d)
    const m = moonCoords(d)
    const phi = Math.acos(Math.sin(s.dec) * Math.sin(m.dec) + Math.cos(s.dec) * Math.cos(m.dec) * Math.cos(s.ra - m.ra))
    const inc = Math.atan2(SUN_DISTANCE * Math.sin(phi), m.dist - SUN_DISTANCE * Math.cos(phi))
    const angle = Math.atan2(Math.cos(s.dec) * Math.sin(s.ra - m.ra), Math.sin(s.dec) * Math.cos(m.dec) - Math.cos(s.dec) * Math.sin(m.dec) * Math.cos(s.ra - m.ra))
    return {
        fraction: (1 + Math.cos(inc)) / 2,
        phase: 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / Math.PI,
        angle: angle / RAD
    }
}

export function phaseName(phase) {
    const p = ((phase % 1) + 1) % 1
    const q = Math.round(p * 4) % 4
    if (Math.abs(p * 4 - Math.round(p * 4)) < 0.135)
        return PHASES[q * 2]
    return PHASES[Math.floor(p * 4) * 2 + 1]
}

export function curve(start, lat, lon, body, steps) {
    const out = []
    const pos = body === "moon" ? moonPosition : sunPosition
    for (let i = 0; i <= steps; i++) {
        const t = start + DAY_MS * i / steps
        out.push({ t: t, altitude: pos(t, lat, lon).altitude })
    }
    return out
}

export function crossings(samples, horizon) {
    let rise = null
    let set = null
    for (let i = 1; i < samples.length; i++) {
        const a = samples[i - 1]
        const b = samples[i]
        const da = a.altitude - horizon
        const db = b.altitude - horizon
        if ((da < 0) === (db < 0))
            continue
        const t = a.t + (b.t - a.t) * da / (da - db)
        if (db > da && rise === null)
            rise = t
        else if (db < da && set === null)
            set = t
    }
    return { rise: rise, set: set }
}

export function nextPhase(ms, target) {
    const step = DAY_MS / 8
    const ahead = p => ((target - p) % 1 + 1) % 1
    let prev = ahead(moonIllumination(ms).phase)
    for (let i = 1; i <= 8 * 31; i++) {
        const t = ms + step * i
        const cur = ahead(moonIllumination(t).phase)
        if (cur > prev + 0.5)
            return t - step * cur / (cur + 1 - prev)
        prev = cur
    }
    return null
}

export function daylight(altitude) {
    if (altitude >= 6)
        return "day"
    if (altitude >= -0.833)
        return "golden"
    if (altitude >= -6)
        return "civil"
    if (altitude >= -12)
        return "nautical"
    if (altitude >= -18)
        return "astronomical"
    return "night"
}

function coordinate(text, degreeDigits) {
    const sign = text[0] === "-" ? -1 : 1
    const digits = text.slice(1)
    const deg = Number(digits.slice(0, degreeDigits))
    const min = Number(digits.slice(degreeDigits, degreeDigits + 2))
    const sec = digits.length > degreeDigits + 2 ? Number(digits.slice(degreeDigits + 2, degreeDigits + 4)) : 0
    return sign * (deg + min / 60 + sec / 3600)
}

export function zoneLocation(table, zone) {
    for (const line of String(table).split("\n")) {
        if (line === "" || line[0] === "#")
            continue
        const cols = line.split("\t")
        if (cols[2] !== zone)
            continue
        const m = /^([+-]\d+)([+-]\d+)$/.exec(cols[1])
        if (m === null)
            return null
        return { latitude: coordinate(m[1], 2), longitude: coordinate(m[2], 3) }
    }
    return null
}

export function zoneFromPath(path) {
    const i = String(path).indexOf("zoneinfo/")
    return i < 0 ? "" : String(path).slice(i + 9).trim()
}

export function dayStart(ms) {
    const d = new Date(ms)
    return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()
}
