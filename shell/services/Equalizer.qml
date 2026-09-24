pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../lib/eq.mjs" as E

Singleton {
    id: root

    readonly property var cfg: Settings.values.media.eq
    readonly property bool enabled: root.cfg.enabled || root.cfg.spatial
    readonly property var effective: root.cfg.enabled ? root.cfg : Object.assign({}, root.cfg, {
        bands: E.PRESETS.flat
    })
    readonly property string path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/sylvaris/eq.conf"
    readonly property var node: root.find("sylvaris_eq")
    readonly property bool running: filter.running
    property string target: ""
    property bool pending: false
    property string error: ""

    function find(name: string): var {
        if (Demo.enabled || !Pipewire.ready)
            return null;
        for (const n of Pipewire.nodes.values) {
            if (n.name === name)
                return n;
        }
        return null;
    }

    function hardwareDefault(): string {
        const s = Pipewire.defaultAudioSink;
        return s && s.name.indexOf("sylvaris_eq") !== 0 ? s.name : root.target;
    }

    function set(patch: var): void {
        const next = Object.assign({}, root.cfg, patch);
        if (patch.bands !== undefined && patch.preset === undefined)
            next.preset = E.presetOf(next.bands);
        if (patch.preset !== undefined && patch.preset !== "custom")
            next.bands = E.PRESETS[patch.preset].slice();
        Settings.set("media.eq", next);
    }

    function setBand(i: int, gain: real): void {
        const bands = root.cfg.bands.slice();
        bands[i] = Math.round(gain * 2) / 2;
        root.set({
            bands: bands
        });
    }

    function retarget(name: string): void {
        root.target = name;
        if (root.enabled)
            restart.restart();
    }

    function start(): void {
        if (Demo.enabled)
            return;
        if (root.target === "")
            root.target = root.hardwareDefault();
        file.setText(E.config(root.effective, root.target));
        if (filter.running) {
            root.pending = true;
            filter.running = false;
        } else {
            filter.running = true;
        }
    }

    function stop(): void {
        root.pending = false;
        restart.stop();
        filter.running = false;
        const hw = root.find(root.target);
        if (hw !== null)
            Pipewire.preferredDefaultAudioSink = hw;
    }

    onEnabledChanged: {
        if (root.enabled)
            root.start();
        else
            root.stop();
    }

    onCfgChanged: {
        if (root.enabled && root.running)
            restart.restart();
    }

    onNodeChanged: {
        if (root.node !== null && root.enabled)
            Pipewire.preferredDefaultAudioSink = root.node;
    }

    Component.onCompleted: {
        if (root.enabled)
            startLater.start();
    }

    Timer {
        id: startLater
        interval: 1500
        onTriggered: root.start()
    }

    Timer {
        id: restart
        interval: 450
        onTriggered: root.start()
    }

    FileView {
        id: file
        path: root.path
        atomicWrites: true
        blockWrites: true
        printErrors: false
    }

    Process {
        id: filter
        command: ["sh", "-c", "pkill -f \"^[^ ]*pipewire -c $1$\"; pipewire -c \"$1\" & p=$!; trap 'kill $p 2>/dev/null; exit' INT TERM; while kill -0 $p 2>/dev/null && kill -0 $PPID 2>/dev/null; do sleep 1; done; kill $p 2>/dev/null", "sylvaris-eq", root.path]
        onRunningChanged: {
            if (!running && root.pending) {
                root.pending = false;
                running = true;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                root.error = t === "" ? "" : t.split("\n").pop();
            }
        }
    }

    PwObjectTracker {
        objects: root.node === null ? [] : [root.node]
    }
}
