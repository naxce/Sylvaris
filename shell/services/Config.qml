pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../lib/settings.mjs" as S

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || (root.home + "/.config")) + "/sylvaris"
    readonly property string path: root.dir + "/config.json"
    property var values: S.validateConfig({})
    property string notice: ""

    onNoticeChanged: {
        if (root.notice !== "")
            console.warn("sylvaris: " + root.notice);
    }

    function ingest(text: string): void {
        const r = S.parseJson(text);
        if (!r.ok) {
            backup.setText(text);
            root.notice = "config.json is not valid JSON; a copy was saved as config.json.bak";
            root.values = S.validateConfig({});
            return;
        }
        root.notice = "";
        root.values = S.validateConfig(r.value);
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.ingest(text())
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                root.notice = "config.json could not be read";
        }
    }

    FileView {
        id: backup
        path: root.path + ".bak"
        preload: false
        printErrors: false
    }
}
