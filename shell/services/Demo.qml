pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property bool enabled: Quickshell.env("SYLVARIS_DEMO") === "1"

    readonly property var bluetooth: [
        { address: "00:11:22:33:44:01", name: "Headphones", icon: "audio-headphones", connected: true, paired: true, trusted: true, batteryAvailable: true, battery: 0.9, busy: false },
        { address: "00:11:22:33:44:02", name: "Mouse", icon: "input-mouse", connected: true, paired: true, trusted: true, batteryAvailable: true, battery: 0.7, busy: false },
        { address: "00:11:22:33:44:03", name: "Controller", icon: "input-gaming", connected: false, paired: true, trusted: false, batteryAvailable: false, battery: 0, busy: false },
        { address: "00:11:22:33:44:04", name: "Phone", icon: "phone", connected: false, paired: false, trusted: false, batteryAvailable: false, battery: 0, busy: false },
        { address: "00:11:22:33:44:05", name: "Earbuds", icon: "audio-headset", connected: false, paired: true, trusted: true, batteryAvailable: false, battery: 0, busy: false },
        { address: "00:11:22:33:44:06", name: "A device with a remarkably long Bluetooth name that must not overflow", icon: "computer", connected: false, paired: false, trusted: false, batteryAvailable: false, battery: 0, busy: false },
        { address: "00:11:22:33:44:07", name: "Speaker", icon: "audio-card", connected: false, paired: false, trusted: false, batteryAvailable: false, battery: 0, busy: false },
        { address: "00:11:22:33:44:08", name: "Keyboard", icon: "input-keyboard", connected: false, paired: false, trusted: false, batteryAvailable: false, battery: 0, busy: false },
        { address: "00:11:22:33:44:09", name: "Tablet", icon: "input-tablet", connected: false, paired: false, trusted: false, batteryAvailable: false, battery: 0, busy: false },
        { address: "00:11:22:33:44:0A", name: "Watch", icon: "watch", connected: false, paired: false, trusted: false, batteryAvailable: false, battery: 0, busy: false }
    ]

    readonly property var wifi: [
        { name: "Home_5G", signal: 0.92, security: "Wpa2Psk", open: false, connected: true, known: true, busy: false },
        { name: "Home_2.4", signal: 0.8, security: "Wpa2Psk", open: false, connected: false, known: true, busy: false },
        { name: "Cafe", signal: 0.55, security: "Open", open: true, connected: false, known: false, busy: false },
        { name: "Neighbour", signal: 0.3, security: "Sae", open: false, connected: false, known: false, busy: false },
        { name: "PLAY_Free", signal: 0.2, security: "Open", open: true, connected: false, known: false, busy: false }
    ]

    readonly property var sinks: [
        { id: 1, description: "Headphones" },
        { id: 2, description: "Speakers" },
        { id: 3, description: "HDMI Display" }
    ]

    readonly property var player: ({ identity: "Music", title: "Evening Walk", artist: "The Example Band", art: "", playing: true })

    readonly property var outputs: [
        { name: "DP-1", description: "Example Monitor A (DP-1)", enabled: true, position: { x: 0, y: 500 }, scale: 1.0, transform: "normal", modes: [
                { width: 1920, height: 1080, refresh: 179.964, preferred: false, current: true },
                { width: 1920, height: 1080, refresh: 60.0, preferred: true, current: false }
            ] },
        { name: "DP-2", description: "Example Monitor B (DP-2)", enabled: true, position: { x: 1920, y: 0 }, scale: 1.0, transform: "normal", modes: [
                { width: 2560, height: 1440, refresh: 200.013, preferred: false, current: true },
                { width: 2560, height: 1440, refresh: 59.951, preferred: true, current: false }
            ] },
        { name: "HDMI-A-1", description: "Example TV (HDMI-A-1)", enabled: false, modes: [
                { width: 1920, height: 1080, refresh: 60.0, preferred: true, current: false }
            ] }
    ]

    readonly property var cards: [
        { name: "bluez_card.00_11_22_33_44_01", active_profile: "a2dp-sink", profiles: {
                "a2dp-sink": { available: true },
                "headset-head-unit": { available: true }
            } }
    ]
}
