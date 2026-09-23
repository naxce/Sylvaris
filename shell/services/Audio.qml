pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property bool demo: Demo.enabled
    property real demoVolume: 0.62
    property bool demoMuted: false
    property string demoDefault: "1"
    readonly property var sink: root.demo ? null : Pipewire.defaultAudioSink
    readonly property bool available: root.demo || (Pipewire.ready && root.sink !== null)
    readonly property real volume: root.demo ? root.demoVolume : (root.sink !== null && root.sink.audio ? root.sink.audio.volume : 0)
    readonly property bool muted: root.demo ? root.demoMuted : (root.sink !== null && root.sink.audio ? root.sink.audio.muted : false)
    readonly property var sinks: root.demo ? root.demoSinks() : root.realSinks()
    readonly property string outputName: {
        for (const s of root.sinks) {
            if (s.current)
                return s.name;
        }
        return "";
    }

    function nodeName(n: var): string {
        return n.description || n.nickname || n.name;
    }

    function demoSinks(): var {
        return Demo.sinks.map(s => ({
                    key: String(s.id),
                    name: s.description,
                    current: String(s.id) === root.demoDefault
                }));
    }

    function realSinks(): var {
        const out = [];
        for (const n of Pipewire.nodes.values) {
            if (n.isSink && !n.isStream && n.audio)
                out.push({
                    key: String(n.id),
                    name: root.nodeName(n),
                    current: root.sink !== null && n.id === root.sink.id
                });
        }
        return out;
    }

    function setVolume(v: real): void {
        const c = Math.max(0, Math.min(1, v));
        if (root.demo)
            root.demoVolume = c;
        else if (root.sink !== null && root.sink.audio)
            root.sink.audio.volume = c;
    }

    function toggleMute(): void {
        if (root.demo)
            root.demoMuted = !root.demoMuted;
        else if (root.sink !== null && root.sink.audio)
            root.sink.audio.muted = !root.sink.audio.muted;
    }

    function setDefault(key: string): void {
        if (root.demo) {
            root.demoDefault = key;
            return;
        }
        for (const n of Pipewire.nodes.values) {
            if (String(n.id) === key)
                Pipewire.preferredDefaultAudioSink = n;
        }
    }

    PwObjectTracker {
        objects: root.demo || root.sink === null ? [] : [root.sink]
    }
}
