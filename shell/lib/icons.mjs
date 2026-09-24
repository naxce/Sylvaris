const g = cp => String.fromCodePoint(cp)

export const GLYPHS = {
    wifi: g(0xF05A9),
    wifiOff: g(0xF05AA),
    bluetooth: g(0xF00AF),
    bluetoothOff: g(0xF00B2),
    nightLight: g(0xF050E),
    dnd: g(0xF009B),
    performance: g(0xF14DE),
    toggle: g(0xF0521),
    hotspot: g(0xF0002),
    volume: g(0xF057E),
    volumeMute: g(0xF075F),
    speaker: g(0xF04C3),
    displays: g(0xF0379),
    theme: g(0xF03D8),
    settings: g(0xF0493),
    power: g(0xF0425),
    previous: g(0xF04AE),
    play: g(0xF040A),
    pause: g(0xF03E4),
    next: g(0xF04AD),
    back: g(0xF004D),
    scan: g(0xF0450),
    more: g(0xF01D8),
    link: g(0xF0337),
    disconnect: g(0xF00B2),
    trusted: g(0xF0498),
    forget: g(0xF0A7A),
    copy: g(0xF018F),
    lock: g(0xF033E),
    eye: g(0xF0208),
    check: g(0xF012C),
    chevronLeft: g(0xF0141),
    chevronRight: g(0xF0142),
    close: g(0xF0156),
    search: g(0xF0349),
    sunrise: g(0xF059C),
    sunset: g(0xF059B),
    sunny: g(0xF0599),
    night: g(0xF0594),
    daylight: g(0xF051F),
    bell: g(0xF009A),
    clearAll: g(0xF0C51),
    apps: g(0xF003B),
    tune: g(0xF062E),
    ethernet: g(0xF0200),
    music: g(0xF075A),
    pin: g(0xF0403),
    pinOff: g(0xF0404),
    newWindow: g(0xF0415),
    shuffle: g(0xF049D),
    repeat: g(0xF0456),
    repeatOnce: g(0xF0458),
    repeatOff: g(0xF0457),
    equalizer: g(0xF0EA2),
    sliders: g(0xF066A),
    headphones: g(0xF02CB),
    bolt: g(0xF140B),
    voice: g(0xF05CB),
    open: g(0xF03CC),
    keyboard: g(0xF030C),
    info: g(0xF02FD),
    grid: g(0xF0570),
    up: g(0xF005D),
    down: g(0xF0045),
    plus: g(0xF0415),
    chevronUp: g(0xF0143),
    chevronDown: g(0xF0140),
    restart: g(0xF0709),
    sleep: g(0xF04B2),
    logout: g(0xF0343),
    hibernate: g(0xF0717),
    firmware: g(0xF061A),
    monitorOff: g(0xF0379),
    cloudy: g(0xF0590),
    partlyCloudy: g(0xF0595),
    partlyNight: g(0xF0F31),
    rain: g(0xF0597),
    pouring: g(0xF0596),
    snow: g(0xF0598),
    storm: g(0xF0593),
    fog: g(0xF0591),
    wind: g(0xF059D),
    humidity: g(0xF058E),
    thermometer: g(0xF050F),
    image: g(0xF02E9),
    palette: g(0xF03D8),
    stars: g(0xF04CE),
    chart: g(0xF0128),
    planner: g(0xF00F0),
    alarm: g(0xF0020),
    checkCircle: g(0xF05E0),
    timer: g(0xF13AB),
    shuffleVariant: g(0xF049D)
}

const BLUETOOTH = {
    "audio-headphones": g(0xF02CB),
    "audio-headset": g(0xF02CE),
    "audio-card": g(0xF04C3),
    "input-mouse": g(0xF037D),
    "input-keyboard": g(0xF030C),
    "input-gaming": g(0xF02B4),
    "input-tablet": g(0xF04F6),
    "phone": g(0xF03F2),
    "computer": g(0xF0322),
    "video-display": g(0xF0379)
}

export function bluetoothIcon(bluezIcon) {
    return Object.prototype.hasOwnProperty.call(BLUETOOTH, bluezIcon) ? BLUETOOTH[bluezIcon] : GLYPHS.bluetooth
}

export function isAudioDevice(bluezIcon) {
    return typeof bluezIcon === "string" && bluezIcon.indexOf("audio") === 0
}

export function normalizeSignal(signal) {
    if (typeof signal !== "number" || !isFinite(signal))
        return -1
    if (signal > 1)
        return Math.min(1, signal / 100)
    return Math.max(0, signal)
}

export function wifiIcon(signal) {
    const s = normalizeSignal(signal)
    if (s >= 0.75)
        return g(0xF0928)
    if (s >= 0.5)
        return g(0xF0925)
    if (s >= 0.25)
        return g(0xF0922)
    if (s > 0)
        return g(0xF091F)
    return g(0xF092F)
}

export function batteryIcon(percent) {
    if (percent < 5)
        return g(0xF0083)
    const level = Math.min(10, Math.round(percent / 10))
    return level === 10 ? g(0xF0079) : g(0xF007A + level - 1)
}
