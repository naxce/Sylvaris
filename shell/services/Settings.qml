pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../lib/settings.mjs" as S

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || (root.home + "/.config")) + "/sylvaris"
    readonly property string path: root.dir + "/settings.json"
    property var values: S.validateSettings({})
    readonly property var merged: S.merge(Config.values, root.values)
    property string notice: ""
    property string lastWritten: ""
    property bool loadedOnce: false

    onNoticeChanged: {
        if (root.notice !== "")
            console.warn("sylvaris: " + root.notice);
    }

    function get(key: string): var {
        return S.getPath(root.values, key);
    }

    function trySet(key: string, value: var): bool {
        const next = S.validateSettings(S.setPath(root.values, key, value));
        if (JSON.stringify(S.getPath(next, key)) !== JSON.stringify(value))
            return false;
        root.set(key, value);
        return true;
    }

    function set(key: string, value: var): void {
        root.values = S.validateSettings(S.setPath(root.values, key, value));
        writeTimer.restart();
    }

    function ingest(text: string): void {
        if (text === root.lastWritten)
            return;
        const r = S.parseJson(text);
        if (!r.ok) {
            backup.setText(text);
            if (root.loadedOnce) {
                root.notice = "settings.json is not valid JSON; a copy was saved as settings.json.bak and the last good settings stay in use";
                return;
            }
            root.notice = "settings.json is not valid JSON; a copy was saved as settings.json.bak and defaults are in use";
            root.values = S.validateSettings({});
            return;
        }
        root.notice = "";
        root.loadedOnce = true;
        root.values = S.validateSettings(r.value);
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.dir])

    Timer {
        id: writeTimer
        interval: 300
        onTriggered: {
            const text = S.serialize(root.values);
            root.lastWritten = text;
            file.setText(text);
        }
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.ingest(text())
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                root.notice = "settings.json could not be read";
        }
    }

    FileView {
        id: backup
        path: root.path + ".bak"
        preload: false
        printErrors: false
    }
}
