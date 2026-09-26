import { DEFAULT_CONFIG, DEFAULT_SETTINGS, DEFAULT_GLASS, deepMerge } from "./settings.mjs"

export const INTERNAL = ["version", "parts", "toggleState"]

export function schema() {
    const all = deepMerge(deepMerge(DEFAULT_CONFIG, DEFAULT_SETTINGS), { glass: DEFAULT_GLASS })
    for (const key of INTERNAL)
        delete all[key]
    return all
}
