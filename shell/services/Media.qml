pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property bool demo: Demo.enabled
    property bool demoPlaying: Demo.player.playing
    readonly property var player: root.demo ? null : root.pick(Mpris.players.values)
    readonly property bool available: root.demo || root.player !== null
    readonly property string title: root.demo ? Demo.player.title : (root.player !== null ? root.player.trackTitle : "")
    readonly property string artist: root.demo ? Demo.player.artist : (root.player !== null ? root.player.trackArtist : "")
    readonly property string art: root.demo ? Demo.player.art : (root.player !== null ? root.player.trackArtUrl : "")
    readonly property string identity: root.demo ? Demo.player.identity : (root.player !== null ? root.player.identity : "")
    readonly property bool playing: root.demo ? root.demoPlaying : (root.player !== null && root.player.isPlaying)

    function pick(list: var): var {
        for (const p of list) {
            if (p.isPlaying)
                return p;
        }
        return list.length > 0 ? list[0] : null;
    }

    function toggle(): void {
        if (root.demo)
            root.demoPlaying = !root.demoPlaying;
        else if (root.player !== null && root.player.canTogglePlaying)
            root.player.togglePlaying();
    }

    function next(): void {
        if (!root.demo && root.player !== null && root.player.canGoNext)
            root.player.next();
    }

    function previous(): void {
        if (!root.demo && root.player !== null && root.player.canGoPrevious)
            root.player.previous();
    }
}
