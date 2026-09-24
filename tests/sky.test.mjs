import { test } from "node:test"
import assert from "node:assert/strict"
import { sunPosition, moonPosition, moonIllumination, phaseName, curve, crossings, nextPhase, daylight, zoneLocation, zoneFromPath, SUN_HORIZON } from "../shell/lib/sky.mjs"

const T = Date.UTC(2013, 2, 5)
const LAT = 50.5
const LON = 30.5
const near = (a, b, eps) => assert.ok(Math.abs(a - b) <= eps, a + " is not within " + eps + " of " + b)

test("sun position matches the reference", () => {
    const p = sunPosition(T, LAT, LON)
    near(p.azimuth, 36.74, 0.02)
    near(p.altitude, -40.11, 0.02)
})

test("moon position matches the reference", () => {
    const p = moonPosition(T, LAT, LON)
    near(p.azimuth, 123.94, 0.05)
    near(p.altitude, 0.39, 0.1)
})

test("moon illumination matches the reference", () => {
    const m = moonIllumination(T)
    near(m.fraction, 0.4848, 0.001)
    near(m.phase, 0.7548, 0.001)
    assert.equal(phaseName(m.phase), "Last quarter")
})

test("sunrise and sunset come from the sampled curve", () => {
    const c = crossings(curve(T, LAT, LON, "sun", 144), SUN_HORIZON)
    near(c.rise, Date.UTC(2013, 2, 5, 4, 34, 56), 90000)
    near(c.set, Date.UTC(2013, 2, 5, 15, 46, 57), 90000)
})

test("polar night has no sunrise", () => {
    const c = crossings(curve(Date.UTC(2013, 11, 21), 80, 0, "sun", 144), SUN_HORIZON)
    assert.deepEqual(c, { rise: null, set: null })
})

test("the next full moon lands on the known date", () => {
    near(nextPhase(T, 0.5), Date.UTC(2013, 2, 27, 9, 27), 6 * 3600000)
    near(nextPhase(T, 0), Date.UTC(2013, 2, 11, 19, 51), 6 * 3600000)
})

test("phase names wrap around", () => {
    assert.equal(phaseName(0), "New moon")
    assert.equal(phaseName(0.99), "New moon")
    assert.equal(phaseName(0.5), "Full moon")
    assert.equal(phaseName(0.26), "First quarter")
    assert.equal(phaseName(0.3), "Waxing gibbous")
    assert.equal(phaseName(0.1), "Waxing crescent")
    assert.equal(phaseName(0.9), "Waning crescent")
})

test("daylight names each band of sun altitude", () => {
    assert.deepEqual([30, 3, -3, -9, -15, -30].map(daylight), ["day", "golden", "civil", "nautical", "astronomical", "night"])
})

test("zoneLocation reads ISO 6709 coordinates from zone1970.tab", () => {
    const table = "# comment\nPL\t+5215+02100\tEurope/Warsaw\nUS\t+404251-0740023\tAmerica/New_York\tEastern\n"
    assert.deepEqual(zoneLocation(table, "Europe/Warsaw"), { latitude: 52.25, longitude: 21 })
    const ny = zoneLocation(table, "America/New_York")
    near(ny.latitude, 40.7142, 0.001)
    near(ny.longitude, -74.0064, 0.001)
    assert.equal(zoneLocation(table, "Mars/Olympus"), null)
})

test("zoneFromPath takes the zone out of a resolved localtime link", () => {
    assert.equal(zoneFromPath("/nix/store/x-tzdata/share/zoneinfo/Europe/Warsaw\n"), "Europe/Warsaw")
    assert.equal(zoneFromPath("/etc/localtime"), "")
})
