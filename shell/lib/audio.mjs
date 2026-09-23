export function bluezCardName(address) {
    return "bluez_card." + String(address).toUpperCase().replace(/:/g, "_")
}

export function parseCards(text) {
    try {
        const raw = JSON.parse(text)
        return Array.isArray(raw) ? raw : []
    } catch (e) {
        return []
    }
}

export function profileKind(name) {
    if (typeof name !== "string")
        return "off"
    if (name.indexOf("a2dp") === 0)
        return "hifi"
    if (name.indexOf("headset") === 0)
        return "headset"
    return "off"
}

export function profileLabel(kind) {
    if (kind === "hifi")
        return "Hi-Fi (A2DP)"
    if (kind === "headset")
        return "Headset (HFP)"
    return "Off"
}

function pick(profiles, preferred, prefix) {
    const usable = key => profiles[key] && profiles[key].available !== false
    if (usable(preferred))
        return preferred
    for (const key of Object.keys(profiles).sort()) {
        if (key.indexOf(prefix) === 0 && usable(key))
            return key
    }
    return ""
}

export function cardProfile(cards, address) {
    const name = bluezCardName(address)
    let card = null
    for (const c of cards) {
        if (c && c.name === name)
            card = c
    }
    if (card === null)
        return null
    const profiles = card.profiles && typeof card.profiles === "object" ? card.profiles : {}
    const kind = profileKind(card.active_profile)
    const next = kind === "hifi" ? pick(profiles, "headset-head-unit", "headset") : pick(profiles, "a2dp-sink", "a2dp")
    return { card: name, active: card.active_profile, kind: kind, label: profileLabel(kind), next: next }
}
