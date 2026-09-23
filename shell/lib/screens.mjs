export function pickScreen(names, wanted) {
    if (!Array.isArray(names) || names.length === 0)
        return -1
    const i = names.indexOf(wanted)
    return i < 0 ? 0 : i
}
