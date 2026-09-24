function lower(v) {
    return String(v || "").toLowerCase()
}

function subsequence(text, q) {
    let i = 0
    for (const c of text) {
        if (c === q[i])
            i++
        if (i === q.length)
            return true
    }
    return false
}

export function score(app, query) {
    const q = lower(query).trim()
    if (q === "")
        return 1
    const name = lower(app.name)
    if (name === q)
        return 120
    if (name.indexOf(q) === 0)
        return 100
    if (name.split(/[\s\-_.]+/).some(w => w.indexOf(q) === 0))
        return 80
    if (name.indexOf(q) >= 0)
        return 60
    const extra = [app.genericName, app.id].concat(app.keywords || []).map(lower)
    if (extra.some(w => w.indexOf(q) >= 0))
        return 40
    if (lower(app.comment).indexOf(q) >= 0)
        return 20
    if (q.length >= 2 && subsequence(name, q))
        return 10
    return 0
}

export function search(apps, query) {
    const scored = []
    for (const app of apps) {
        const s = score(app, query)
        if (s > 0)
            scored.push({ app: app, s: s })
    }
    scored.sort((a, b) => b.s - a.s || lower(a.app.name).localeCompare(lower(b.app.name)))
    return scored.map(x => x.app)
}

export function visible(apps) {
    const seen = {}
    const out = []
    for (const app of apps) {
        if (app.noDisplay || seen[app.id])
            continue
        seen[app.id] = true
        out.push(app)
    }
    return out.sort((a, b) => lower(a.name).localeCompare(lower(b.name)))
}

export function pages(list, perPage) {
    const out = []
    for (let i = 0; i < list.length; i += perPage)
        out.push(list.slice(i, i + perPage))
    return out.length === 0 ? [[]] : out
}

export function move(index, key, count, columns, perPage) {
    if (count === 0)
        return -1
    const page = Math.floor(index / perPage)
    const inPage = index % perPage
    let next = index
    if (key === "left")
        next = index - 1
    else if (key === "right")
        next = index + 1
    else if (key === "up")
        next = inPage >= columns ? index - columns : index
    else if (key === "down")
        next = inPage + columns < perPage ? index + columns : index
    else if (key === "pageUp")
        next = (page - 1) * perPage
    else if (key === "pageDown")
        next = (page + 1) * perPage
    return Math.max(0, Math.min(count - 1, next))
}
