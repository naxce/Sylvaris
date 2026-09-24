export const SEP = "\u001f"

function isObject(v) {
    return v !== null && typeof v === "object" && !Array.isArray(v)
}

export function dispatch(commands, words) {
    if (!Array.isArray(words) || words.length === 0 || words[0] === "")
        return { ok: false, error: "no command given" }
    const part = words[0]
    const table = commands[part]
    if (!isObject(table))
        return { ok: false, error: "unknown part: " + part }
    const action = words.length > 1 && words[1] !== "" ? words[1] : table.default || "toggle"
    if (action === "default" || typeof table[action] !== "function")
        return { ok: false, error: "unknown " + part + " action: " + action }
    try {
        const result = table[action].apply(null, words.slice(2))
        return { ok: true, result: result === undefined ? null : result }
    } catch (e) {
        return { ok: false, error: String(e && e.message ? e.message : e) }
    }
}

export function format(r) {
    if (!r.ok)
        return "error: " + r.error
    if (r.result === null)
        return "ok"
    return typeof r.result === "string" ? r.result : JSON.stringify(r.result)
}

export function describe(commands) {
    const out = {}
    for (const part of Object.keys(commands).sort())
        out[part] = Object.keys(commands[part]).filter(k => typeof commands[part][k] === "function")
    return out
}

export function parseRequest(line) {
    const text = String(line).trim()
    if (text === "")
        return { ok: false, error: "empty request" }
    if (text.indexOf(SEP) >= 0) {
        const words = String(line).split(SEP)
        if (words[words.length - 1] === "")
            words.pop()
        return { ok: true, words: words }
    }
    if (text[0] !== "[")
        return { ok: true, words: text.split(/\s+/) }
    try {
        const words = JSON.parse(text)
        if (!Array.isArray(words) || !words.every(w => typeof w === "string"))
            return { ok: false, error: "a request is an array of strings" }
        return { ok: true, words: words }
    } catch (e) {
        return { ok: false, error: "a request is an array of strings" }
    }
}

export function topics(snapshot) {
    const out = {}
    for (const key of Object.keys(isObject(snapshot) ? snapshot : {}))
        out[key] = JSON.stringify(snapshot[key] === undefined ? null : snapshot[key])
    return out
}

export function changed(last, next) {
    return Object.keys(next).filter(k => last[k] !== next[k])
}

export function parseValue(text) {
    try {
        return JSON.parse(text)
    } catch (e) {
        return text
    }
}
