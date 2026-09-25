export const DEFAULT_CLIP = { limit: 50, persist: false, images: true }

export function remember(history, entry, limit) {
    if (entry.kind === "text" && String(entry.text || "").trim() === "")
        return history
    const same = e => e.kind === entry.kind && (entry.kind === "text" ? e.text === entry.text : e.hash === entry.hash)
    const old = history.find(same)
    const rest = history.filter(e => !same(e))
    const next = [Object.assign({}, entry, { pinned: old ? old.pinned : entry.pinned === true })].concat(rest)
    let kept = 0
    return next.filter(e => e.pinned || kept++ < limit)
}

export function find(history, query) {
    const q = String(query || "").trim().toLowerCase()
    const hits = q === "" ? history : history.filter(e => e.kind === "text" && e.text.toLowerCase().indexOf(q) >= 0)
    return hits.filter(e => e.pinned).concat(hits.filter(e => !e.pinned))
}

export function preview(text, max) {
    const line = String(text || "").split("\n").map(s => s.trim()).filter(s => s !== "").join(" ⏎ ")
    return line.length > max ? line.slice(0, max - 1) + "…" : line
}

export function secret(types) {
    return types.some(t => /passwordmanagerhint|x-kde-passwordManagerHint/i.test(t))
}

export function validateClip(raw) {
    const v = raw !== null && typeof raw === "object" && !Array.isArray(raw) ? raw : {}
    return Object.assign({}, v, {
        limit: Number.isInteger(v.limit) && v.limit >= 5 && v.limit <= 500 ? v.limit : DEFAULT_CLIP.limit,
        persist: v.persist === true,
        images: v.images !== false
    })
}
