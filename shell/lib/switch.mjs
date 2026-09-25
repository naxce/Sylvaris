export function keyOf(w) {
    return w.handle ? w.handle : w.appId + "\u0001" + w.title
}

export function touch(order, key, alive) {
    const kept = order.filter(k => k !== key && alive.indexOf(k) >= 0)
    return key === null || key === undefined ? kept : [key].concat(kept)
}

export function ordered(windows, order, key) {
    const rank = w => {
        const i = order.indexOf(key(w))
        return i < 0 ? order.length : i
    }
    return windows.map((w, i) => ({ w: w, r: rank(w), i: i })).sort((a, b) => a.r - b.r || a.i - b.i).map(x => x.w)
}

export function wrap(index, delta, count) {
    if (count <= 0)
        return -1
    return ((index + delta) % count + count) % count
}
