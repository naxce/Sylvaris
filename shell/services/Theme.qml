pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs
import "../lib/theme.mjs" as T
import "../lib/settings.mjs" as S

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string stateFile: S.expandHome(Config.values.themeStateFile, root.home)
    readonly property string themesDir: S.expandHome(Config.values.themesDir, root.home)
    property string currentId: ""
    property var theme: T.DEFAULT_THEME
    property var errors: []
    property var ids: []
    readonly property var target: T.tokens(root.theme)
    property var fromTokens: T.tokens(T.DEFAULT_THEME)
    property var toTokens: root.fromTokens
    property real progress: 1
    readonly property var tk: T.mixTokens(root.fromTokens, root.toTokens, root.progress)
    readonly property string wallpaper: S.expandHome(root.theme.wallpaper, root.home)

    property color base: root.tk.base
    property color surface: root.tk.surface
    property color glass: root.tk.glass
    property color node: root.tk.node
    property color line: root.tk.line
    property color lineStrong: root.tk.lineStrong
    property color cardLine: root.tk.cardLine
    property color tint: root.tk.tint
    property color tintSoft: root.tk.tintSoft
    property color tintMid: root.tk.tintMid
    property color tintStrong: root.tk.tintStrong
    property color moon: root.tk.moon
    property color fill: root.tk.fill
    property color glow: root.tk.glow
    property color silk: root.tk.silk
    property color sonar: root.tk.sonar
    property color accent: root.tk.accent
    property color accentHi: root.tk.accentHi
    property color accentDeep: root.tk.accentDeep
    property color onAccent: root.tk.onAccent
    property color text: root.tk.text
    property color textDim: root.tk.textDim
    property color textSoft: root.tk.textSoft
    property color danger: root.tk.danger


    onTargetChanged: {
        root.fromTokens = root.tk;
        root.toTokens = root.target;
        root.progress = 0;
        fade.restart();
    }

    NumberAnimation {
        id: fade
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: Tokens.colorDuration
    }

    function fallback(reason: string): void {
        root.theme = T.DEFAULT_THEME;
        root.errors = reason === "" ? [] : [reason];
    }

    function ingest(text: string): void {
        const p = S.parseJson(text);
        if (!p.ok) {
            root.fallback("theme " + root.currentId + " is not valid JSON");
            return;
        }
        const r = T.validateTheme(p.value);
        root.theme = r.theme;
        root.errors = r.errors;
    }

    function refreshIds(): void {
        const out = [];
        for (let i = 0; i < folder.count; i++)
            out.push(String(folder.get(i, "fileBaseName")));
        root.ids = out.sort();
    }

    function apply(id: string): void {
        if (id === "")
            return;
        const hook = S.expandHome(Config.values.themeHook, root.home);
        if (hook !== "")
            Quickshell.execDetached(["sh", "-c", hook + " \"$1\"", "sylvaris-theme", id]);
        else
            Quickshell.execDetached(["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf %s \"$2\" > \"$1\"", "sylvaris-theme", root.stateFile, id]);
    }

    function cycle(): void {
        root.apply(T.nextThemeId(root.ids, root.currentId));
    }

    onCurrentIdChanged: {
        if (root.currentId === "")
            root.fallback("");
    }

    FileView {
        id: stateView
        path: root.stateFile
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.currentId = text().trim()
        onLoadFailed: root.currentId = ""
    }

    FileView {
        id: themeView
        path: root.currentId === "" ? "" : root.themesDir + "/" + root.currentId + ".json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.ingest(text())
        onLoadFailed: root.fallback("theme file not found: " + root.currentId + ".json")
    }

    FolderListModel {
        id: folder
        folder: "file://" + root.themesDir
        nameFilters: ["*.json"]
        showDirs: false
        onCountChanged: root.refreshIds()
    }
}
