import { GLYPHS } from "./icons.mjs"

export const MODULES = {
    center: { label: "Control Center", section: "general", glyph: "tune" },
    theme: { label: "Theme", section: "appearance", glyph: "theme" },
    clock: { label: "Clock", section: "clock", glyph: "night" },
    notify: { label: "Notifications", section: "notifications", glyph: "bell" },
    pad: { label: "Launcher", section: "launcher", glyph: "apps" },
    media: { label: "Media", section: "sound", glyph: "music" },
    settings: { label: "Settings", section: "general", glyph: "tune" },
    power: { label: "Power", section: "power", glyph: "power" },
    paper: { label: "Wallpaper", section: "wallpaper", glyph: "image" },
    diver: { label: "Diver", section: "diver", glyph: "planner" },
    switcher: { label: "Window switcher", section: "switcher", glyph: "switcher" },
    lock: { label: "Lock screen", section: "lock", glyph: "lock" },
    polkit: { label: "Authentication", section: "polkit", glyph: "shield" },
    clip: { label: "Clipboard", section: "clip", glyph: "clipboard" },
    capture: { label: "Screenshots", section: "capture", glyph: "camera" },
    access: { label: "Accessibility", section: "access", glyph: "accessibility" },
    plugins: { label: "Plugins", section: "plugins", glyph: "puzzle" }
}

export const PRODUCT = {
    bar: "SylBar", deck: "SylDeck", center: "SylCenter", theme: "SylTheme", clock: "SylClock", notify: "SylNotify",
    pad: "SylPad", media: "SylMedia", settings: "SylSettings", power: "SylPower", paper: "SylPaper", diver: "SylDiver",
    switcher: "SylSwitch", lock: "SylLock", polkit: "SylPolkit", clip: "SylClip", capture: "SylCapture", access: "SylAccessibility", plugins: "SylPlugins"
}

export function tiles() {
    return Object.keys(MODULES).map(name => ({
        id: "sylvaris." + name,
        name: MODULES[name].label,
        genericName: "Sylvaris settings",
        keywords: ["sylvaris", "settings", name, MODULES[name].section],
        section: MODULES[name].section,
        glyph: GLYPHS[MODULES[name].glyph]
    }))
}
