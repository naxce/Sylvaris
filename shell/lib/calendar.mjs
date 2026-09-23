export function monthGrid(year, month, firstDay) {
    const first = new Date(year, month, 1).getDay()
    const lead = (first - firstDay + 7) % 7
    const cells = []
    for (let i = 0; i < 42; i++) {
        const d = new Date(year, month, 1 - lead + i)
        cells.push({ year: d.getFullYear(), month: d.getMonth(), day: d.getDate(), inMonth: d.getMonth() === month && d.getFullYear() === year })
    }
    return cells
}

export function shiftMonth(year, month, delta) {
    const total = year * 12 + month + delta
    return { year: Math.floor(total / 12), month: ((total % 12) + 12) % 12 }
}

export function weekdayLabels(firstDay, names) {
    const out = []
    for (let i = 0; i < 7; i++)
        out.push(names[(firstDay + i) % 7])
    return out
}

export function isSameDay(cell, date) {
    return cell.year === date.getFullYear() && cell.month === date.getMonth() && cell.day === date.getDate()
}
