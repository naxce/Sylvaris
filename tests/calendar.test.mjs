import { test } from "node:test"
import assert from "node:assert/strict"
import { monthGrid, shiftMonth, weekdayLabels, isSameDay } from "../shell/lib/calendar.mjs"

test("monthGrid has 42 cells starting on the requested weekday", () => {
    const monday = monthGrid(2026, 8, 1)
    assert.equal(monday.length, 42)
    assert.deepEqual(monday[0], { year: 2026, month: 7, day: 31, inMonth: false })
    assert.deepEqual(monday[1], { year: 2026, month: 8, day: 1, inMonth: true })
    assert.deepEqual(monday[41], { year: 2026, month: 9, day: 11, inMonth: false })
    const sunday = monthGrid(2026, 8, 0)
    assert.deepEqual(sunday[0], { year: 2026, month: 7, day: 30, inMonth: false })
    assert.equal(monday.filter(c => c.inMonth).length, 30)
})

test("monthGrid handles a month starting on the first weekday", () => {
    const grid = monthGrid(2026, 5, 1)
    assert.deepEqual(grid[0], { year: 2026, month: 5, day: 1, inMonth: true })
})

test("shiftMonth wraps years", () => {
    assert.deepEqual(shiftMonth(2026, 0, -1), { year: 2025, month: 11 })
    assert.deepEqual(shiftMonth(2026, 11, 1), { year: 2027, month: 0 })
    assert.deepEqual(shiftMonth(2026, 5, 14), { year: 2027, month: 7 })
})

test("weekdayLabels rotates Sunday-first names", () => {
    const names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    assert.deepEqual(weekdayLabels(1, names), ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
    assert.deepEqual(weekdayLabels(0, names), names)
})

test("isSameDay compares a cell with a date", () => {
    assert.equal(isSameDay({ year: 2026, month: 8, day: 23 }, new Date(2026, 8, 23, 18, 37)), true)
    assert.equal(isSameDay({ year: 2026, month: 8, day: 22 }, new Date(2026, 8, 23)), false)
})
