import QtQuick
import Quickshell
import qs
import qs.services
import qs.components
import "../lib/bar.mjs" as B
import "../lib/eq.mjs" as E
import "../lib/wm.mjs" as W
import "../lib/icons.mjs" as Icons

Popup {
    id: root

    property string section: "general"
    readonly property var sections: [
        {
            key: "general",
            label: "General",
            glyph: Icons.GLYPHS.tune
        },
        {
            key: "appearance",
            label: "Appearance",
            glyph: Icons.GLYPHS.theme
        },
        {
            key: "bar",
            label: "Bar",
            glyph: Icons.GLYPHS.grid
        },
        {
            key: "deck",
            label: "Deck",
            glyph: Icons.GLYPHS.pin
        },
        {
            key: "launcher",
            label: "Launcher",
            glyph: Icons.GLYPHS.apps
        },
        {
            key: "notifications",
            label: "Notifications",
            glyph: Icons.GLYPHS.bell
        },
        {
            key: "sound",
            label: "Sound",
            glyph: Icons.GLYPHS.volume
        },
        {
            key: "displays",
            label: "Displays",
            glyph: Icons.GLYPHS.displays
        },
        {
            key: "clock",
            label: "Clock",
            glyph: Icons.GLYPHS.night
        },
        {
            key: "commands",
            label: "Commands",
            glyph: Icons.GLYPHS.keyboard
        },
        {
            key: "about",
            label: "About",
            glyph: Icons.GLYPHS.info
        }
    ]
    readonly property var corners: [
        {
            key: "top-left",
            label: "Left"
        },
        {
            key: "top-center",
            label: "Center"
        },
        {
            key: "top-right",
            label: "Right"
        }
    ]
    readonly property var glassKeys: [
        {
            key: "opacity",
            label: "Panel opacity",
            max: 1
        },
        {
            key: "layerOpacity",
            label: "Tile opacity",
            max: 1
        },
        {
            key: "tint",
            label: "Accent tint",
            max: 1
        },
        {
            key: "sheen",
            label: "Sheen",
            max: 1
        },
        {
            key: "flow",
            label: "Sheen movement",
            max: 3
        },
        {
            key: "rim",
            label: "Rim light",
            max: 1
        },
        {
            key: "grain",
            label: "Grain",
            max: 0.2
        }
    ]
    readonly property var binds: [
        {
            label: "Control center",
            key: "A",
            command: "sylvaris center"
        },
        {
            label: "Clock and calendar",
            key: "D",
            command: "sylvaris clock"
        },
        {
            label: "Notifications",
            key: "N",
            command: "sylvaris notify"
        },
        {
            label: "App launcher",
            key: "Space",
            command: "sylvaris pad"
        },
        {
            label: "Media",
            key: "P",
            command: "sylvaris media open"
        },
        {
            label: "Theme picker",
            key: "T",
            command: "sylvaris theme"
        },
        {
            label: "Settings",
            key: "comma",
            command: "sylvaris settings"
        },
        {
            label: "Play or pause",
            key: "XF86AudioPlay",
            command: "sylvaris media toggle"
        },
        {
            label: "Volume up",
            key: "XF86AudioRaiseVolume",
            command: "sylvaris audio up 5"
        },
        {
            label: "Volume down",
            key: "XF86AudioLowerVolume",
            command: "sylvaris audio down 5"
        }
    ]

    signal partRequested(string name, string arg)

    namespace: "sylsettings"
    corner: "center"
    dim: 0.25
    panelWidth: Tokens.settingsWidth
    panelHeight: Tokens.settingsHeight

    function showSection(name: string): void {
        if (name !== "" && root.sections.some(s => s.key === name))
            root.section = name;
        root.open();
    }

    function hand(name: string, arg: string): void {
        root.close();
        root.partRequested(name, arg);
    }

    function glass(key: string): real {
        return Resin.values[key];
    }

    Item {
        id: sidebar
        width: Tokens.settingsSidebar
        height: parent.height

        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: Qt.alpha(Theme.text, 0.08)
        }

        Row {
            x: 22
            y: 26
            spacing: 12

            Rectangle {
                width: 40
                height: 40
                radius: 12
                color: Theme.accent

                Glyph {
                    anchors.centerIn: parent
                    text: Icons.GLYPHS.settings
                    size: 20
                    color: Theme.onAccent
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: "Settings"
                    color: Theme.text
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.titleSize
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Sylvaris"
                    color: Theme.textDim
                    font.family: Tokens.fontUi
                    font.pixelSize: Tokens.smallSize
                }
            }
        }

        Column {
            x: 12
            y: 90
            width: parent.width - 24
            spacing: 2

            Repeater {
                model: root.sections

                delegate: Item {
                    required property var modelData
                    readonly property bool current: root.section === modelData.key
                    width: parent.width
                    height: 42

                    Glass {
                        anchors.fill: parent
                        radius: Tokens.radiusRow
                        inner: true
                        lit: parent.current
                        opacity: parent.current || navArea.containsMouse ? 1 : 0
                        offBorder: "transparent"
                    }

                    Glyph {
                        id: navGlyph
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.glyph
                        size: 17
                        color: parent.current ? Theme.onAccent : Theme.accent
                    }

                    Text {
                        anchors.left: navGlyph.right
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: parent.current ? Theme.onAccent : Theme.text
                        font.family: Tokens.fontUi
                        font.pixelSize: Tokens.bodySize
                        font.weight: parent.current ? Font.DemiBold : Font.Normal
                    }

                    MouseArea {
                        id: navArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.section = modelData.key;
                            content.contentY = 0;
                        }
                    }
                }
            }
        }
    }

    Text {
        id: pageTitle
        x: sidebar.width + 36
        y: 28
        text: root.sections.filter(s => s.key === root.section)[0].label
        color: Theme.text
        font.family: Tokens.fontUi
        font.pixelSize: 26
        font.weight: Font.DemiBold
    }

    Glyph {
        anchors.right: parent.right
        anchors.rightMargin: 28
        anchors.verticalCenter: pageTitle.verticalCenter
        text: Icons.GLYPHS.close
        size: 20
        color: closeArea.containsMouse ? Theme.text : Theme.textDim

        MouseArea {
            id: closeArea
            anchors.fill: parent
            anchors.margins: -10
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.close()
        }
    }

    Flickable {
        id: content
        x: sidebar.width + 36
        y: pageTitle.y + pageTitle.height + 22
        width: parent.width - x - 36
        height: parent.height - y - 20
        clip: true
        contentHeight: page.item ? page.item.implicitHeight + 20 : 0
        boundsBehavior: Flickable.StopAtBounds

        Loader {
            id: page
            width: content.width
            sourceComponent: ({
                    general: generalPage,
                    appearance: appearancePage,
                    bar: barPage,
                    deck: deckPage,
                    launcher: launcherPage,
                    notifications: notificationsPage,
                    sound: soundPage,
                    displays: displaysPage,
                    clock: clockPage,
                    commands: commandsPage,
                    about: aboutPage
                })[root.section]
        }
    }

    Component {
        id: generalPage

        Column {
            spacing: 24

            Card {
                title: "Panels"

                SettingRow {
                    title: "Control center"
                    subtitle: "Where SylCenter and SylMedia open"

                    Segmented {
                        width: 300
                        options: root.corners
                        current: Settings.values.center.corner
                        onPicked: key => Settings.set("center.corner", key)
                    }
                }

                SettingRow {
                    title: "Clock"
                    subtitle: "Where SylClock opens"

                    Segmented {
                        width: 300
                        options: root.corners
                        current: Settings.values.clock.corner
                        onPicked: key => Settings.set("clock.corner", key)
                    }
                }

                SettingRow {
                    title: "Notifications"
                    subtitle: "Where toasts and the notification center appear"
                    last: true

                    Segmented {
                        width: 300
                        options: root.corners
                        current: Settings.values.notifications.corner
                        onPicked: key => Settings.set("notifications.corner", key)
                    }
                }
            }

            Card {
                title: "From config.json"
                note: "These live in " + Config.path + ", which Sylvaris never writes. Edit that file or your Nix config; changes apply as soon as it is saved."

                Repeater {
                    model: ["avatar", "terminal", "lockCommand", "themeHook", "themesDir"]

                    delegate: SettingRow {
                        required property string modelData
                        required property int index
                        title: modelData
                        last: index === 4

                        Text {
                            width: Math.min(implicitWidth, 380)
                            text: Config.values[modelData] === "" ? "not set" : Config.values[modelData]
                            elide: Text.ElideMiddle
                            color: Theme.textSoft
                            font.family: Tokens.fontMono
                            font.pixelSize: Tokens.smallSize
                        }
                    }
                }
            }
        }
    }

    Component {
        id: appearancePage

        Column {
            spacing: 24

            Card {
                title: "Theme"

                SettingRow {
                    title: Theme.theme.name || "Built-in"
                    subtitle: Theme.theme.description || "The active theme"

                    Chip {
                        text: "Open the theme picker"
                        glyph: Icons.GLYPHS.theme
                        onClicked: root.hand("theme", "")
                    }
                }

                SettingRow {
                    title: "Apply directly"
                    last: true

                    Flow {
                        width: 420
                        spacing: 6
                        layoutDirection: Qt.RightToLeft

                        Repeater {
                            model: Theme.ids

                            delegate: Chip {
                                required property string modelData
                                text: Theme.catalog[modelData] !== undefined ? Theme.catalog[modelData].name : modelData
                                lit: modelData === Theme.currentId
                                onClicked: Theme.apply(modelData)
                            }
                        }
                    }
                }
            }

            Card {
                title: "Resin Glass"
                note: "Every panel, tile and card is drawn in translucent glass. Blur comes from your compositor."

                SettingRow {
                    title: "Glass"
                    subtitle: "Off brings back solid panels"

                    Toggle {
                        checked: Resin.enabled
                        onToggled: v => Settings.set("glass.enabled", v)
                    }
                }

                Repeater {
                    model: root.glassKeys

                    delegate: SettingRow {
                        required property var modelData
                        required property int index
                        title: modelData.label
                        last: index === root.glassKeys.length - 1
                        opacity: Resin.enabled ? 1 : 0.45

                        Slider {
                            width: 300
                            value: root.glass(modelData.key) / modelData.max
                            label: root.glass(modelData.key).toFixed(modelData.max < 1 ? 3 : 2)
                            onMoved: v => Settings.set("glass." + modelData.key, Math.round(v * modelData.max * 1000) / 1000)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: barPage

        Column {
            spacing: 24

            Card {
                title: "SylBar"

                SettingRow {
                    title: "Show the bar"

                    Toggle {
                        checked: Settings.values.bar.enabled
                        onToggled: v => Settings.set("bar.enabled", v)
                    }
                }

                SettingRow {
                    title: "Floating"
                    subtitle: "A rounded bar with a gap around it, or one that spans the edge"
                    last: true

                    Toggle {
                        checked: Settings.values.bar.floating
                        onToggled: v => Settings.set("bar.floating", v)
                    }
                }
            }

            Card {
                title: "Modules"
                note: "Click a module to move it along or remove it; add the ones you are missing to any side."

                Repeater {
                    model: ["left", "center", "right"]

                    delegate: Item {
                        id: side
                        required property string modelData
                        property int picked: -1
                        readonly property var list: Settings.values.bar[modelData]
                        width: parent.width
                        height: sideFlow.implicitHeight + 50

                        Text {
                            y: 14
                            text: side.modelData.charAt(0).toUpperCase() + side.modelData.slice(1)
                            color: Theme.textDim
                            font.family: Tokens.fontUi
                            font.pixelSize: Tokens.smallSize
                            font.weight: Font.DemiBold
                        }

                        Flow {
                            id: sideFlow
                            y: 38
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: side.list

                                delegate: Row {
                                    required property string modelData
                                    required property int index
                                    spacing: 4

                                    Chip {
                                        text: modelData
                                        lit: side.picked === index
                                        onClicked: side.picked = side.picked === index ? -1 : index
                                    }

                                    Repeater {
                                        model: side.picked === index ? [
                                            {
                                                glyph: Icons.GLYPHS.chevronLeft,
                                                act: -1
                                            },
                                            {
                                                glyph: Icons.GLYPHS.chevronRight,
                                                act: 1
                                            },
                                            {
                                                glyph: Icons.GLYPHS.close,
                                                act: 0
                                            }
                                        ] : []

                                        delegate: Chip {
                                            required property var modelData
                                            glyph: modelData.glyph
                                            onClicked: {
                                                const list = side.list;
                                                const i = side.picked;
                                                if (modelData.act === 0) {
                                                    Settings.set("bar." + side.modelData, list.filter((m, k) => k !== i));
                                                    side.picked = -1;
                                                } else {
                                                    Settings.set("bar." + side.modelData, B.shift(list, i, modelData.act));
                                                    side.picked = Math.max(0, Math.min(list.length - 1, i + modelData.act));
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: B.unused(Settings.values.bar)

                                delegate: Chip {
                                    required property string modelData
                                    text: modelData
                                    glyph: Icons.GLYPHS.plus
                                    opacity: 0.6
                                    onClicked: Settings.set("bar." + side.modelData, side.list.concat([modelData]))
                                }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            visible: side.modelData !== "right"
                            width: parent.width
                            height: 1
                            color: Qt.alpha(Theme.text, 0.08)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: deckPage

        Column {
            spacing: 24

            Card {
                title: "SylDeck"

                SettingRow {
                    title: "Show the deck"
                    subtitle: "A dock for pinned and running apps along the bottom"

                    Toggle {
                        checked: Settings.values.deck.enabled
                        onToggled: v => Settings.set("deck.enabled", v)
                    }
                }

                SettingRow {
                    title: "Magnify icons"

                    Toggle {
                        checked: Settings.values.deck.magnify
                        onToggled: v => Settings.set("deck.magnify", v)
                    }
                }

                SettingRow {
                    title: "Hide automatically"
                    subtitle: "Slides away until the pointer reaches the bottom edge"

                    Toggle {
                        checked: Settings.values.deck.autohide
                        onToggled: v => Settings.set("deck.autohide", v)
                    }
                }

                SettingRow {
                    title: "Icon size"

                    Stepper {
                        value: Settings.values.deck.size
                        from: 36
                        to: 96
                        onStepped: v => Settings.set("deck.size", v)
                    }
                }

                SettingRow {
                    title: "App launcher button"
                    last: true

                    Segmented {
                        width: 280
                        current: Settings.values.deck.pad
                        options: [
                            {
                                key: "start",
                                label: "Start"
                            },
                            {
                                key: "end",
                                label: "End"
                            },
                            {
                                key: "none",
                                label: "None"
                            }
                        ]
                        onPicked: key => Settings.set("deck.pad", key)
                    }
                }
            }

            Card {
                title: "Pinned apps"
                note: Settings.values.deck.pinned.length === 0 ? "Nothing pinned yet. Right-click an app in SylPad or in the deck to keep it here." : ""

                Repeater {
                    model: Settings.values.deck.pinned

                    delegate: SettingRow {
                        required property string modelData
                        required property int index
                        readonly property var entry: Demo.enabled ? Apps.byId(modelData) : DesktopEntries.byId(modelData)
                        title: entry ? entry.name : modelData
                        subtitle: modelData
                        last: index === Settings.values.deck.pinned.length - 1

                        Row {
                            spacing: 6

                            Repeater {
                                model: [
                                    {
                                        glyph: Icons.GLYPHS.up,
                                        act: -1
                                    },
                                    {
                                        glyph: Icons.GLYPHS.down,
                                        act: 1
                                    },
                                    {
                                        glyph: Icons.GLYPHS.close,
                                        act: 0
                                    }
                                ]

                                delegate: Chip {
                                    required property var modelData
                                    glyph: modelData.glyph
                                    onClicked: {
                                        const list = Settings.values.deck.pinned;
                                        Settings.set("deck.pinned", modelData.act === 0 ? list.filter((p, k) => k !== index) : B.shift(list, index, modelData.act));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: launcherPage

        Column {
            spacing: 24

            Card {
                title: "SylPad"
                note: "Open it with the apps button on the bar or deck, or bind `sylvaris pad` to a key."

                SettingRow {
                    title: "Columns"

                    Stepper {
                        value: Settings.values.pad.columns
                        from: 3
                        to: 10
                        onStepped: v => Settings.set("pad.columns", v)
                    }
                }

                SettingRow {
                    title: "Rows"
                    last: true

                    Stepper {
                        value: Settings.values.pad.rows
                        from: 2
                        to: 8
                        onStepped: v => Settings.set("pad.rows", v)
                    }
                }
            }
        }
    }

    Component {
        id: notificationsPage

        Column {
            spacing: 24

            Card {
                title: "SylNotify"

                SettingRow {
                    title: "Do not disturb"
                    subtitle: "Only urgent notifications pop up; everything still lands in the notification center"

                    Toggle {
                        checked: Dnd.enabled
                        onToggled: v => Dnd.setEnabled(v)
                    }
                }

                SettingRow {
                    title: "Toast duration"
                    subtitle: "Unless the app asks for something else"
                    last: true

                    Slider {
                        width: 300
                        value: (Settings.values.notifications.timeout - 1000) / 59000
                        label: (Settings.values.notifications.timeout / 1000).toFixed(0) + " s"
                        onMoved: v => Settings.set("notifications.timeout", Math.round(1000 + v * 59) * 1000)
                    }
                }
            }

            Card {
                title: "Daemon"
                note: Notifications.enabled ? "Sylvaris is your notification daemon. Stop swaync, mako or dunst so it can receive notifications." : "notifications.server is false in config.json, so another daemon handles notifications."
            }
        }
    }

    Component {
        id: soundPage

        Column {
            spacing: 24

            Card {
                title: "Output"

                Repeater {
                    model: Audio.sinks

                    delegate: SettingRow {
                        required property var modelData
                        required property int index
                        title: modelData.name
                        last: index === Audio.sinks.length - 1

                        Chip {
                            text: modelData.current ? "In use" : "Use"
                            lit: modelData.current
                            onClicked: Audio.setDefault(modelData.key)
                        }
                    }
                }
            }

            Card {
                title: "Equalizer"

                SettingRow {
                    title: "Equalizer"
                    subtitle: "Preset: " + E.PRESET_NAMES[Equalizer.cfg.preset]

                    Row {
                        spacing: 10

                        Chip {
                            text: "Adjust"
                            glyph: Icons.GLYPHS.equalizer
                            onClicked: root.hand("media", "sound")
                        }

                        Toggle {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: Equalizer.cfg.enabled
                            onToggled: v => Equalizer.set({
                                    enabled: v
                                })
                        }
                    }
                }

                SettingRow {
                    title: "Spatial audio"
                    subtitle: "Headphone crossfeed"
                    last: true

                    Toggle {
                        checked: Equalizer.cfg.spatial
                        onToggled: v => Equalizer.set({
                                spatial: v
                            })
                    }
                }
            }
        }
    }

    Component {
        id: displaysPage

        Column {
            spacing: 24

            Card {
                title: "Night light"

                SettingRow {
                    title: "Night light"
                    subtitle: NightLight.available ? "Warmer colours through wlsunset" : "Install wlsunset to use night light"

                    Toggle {
                        checked: NightLight.enabled
                        onToggled: v => NightLight.setEnabled(v)
                    }
                }

                SettingRow {
                    title: "Colour temperature"
                    last: true

                    Slider {
                        width: 300
                        value: (NightLight.temperature - 2500) / 4000
                        label: NightLight.temperature + " K"
                        onMoved: v => Settings.set("nightLight.temperature", Math.round((2500 + v * 4000) / 100) * 100)
                    }
                }
            }

            Card {
                title: "Screens"

                SettingRow {
                    title: "Arrange displays"
                    subtitle: "Resolution, refresh rate, scale and position, with automatic revert"
                    last: true

                    Chip {
                        text: "Open"
                        glyph: Icons.GLYPHS.displays
                        onClicked: root.hand("center", "displays")
                    }
                }
            }
        }
    }

    Component {
        id: clockPage

        Column {
            spacing: 24

            Card {
                title: "Location"
                note: "SylClock uses your location for the sun and moon. Set `location = { latitude = …; longitude = …; }` in config.json or your Nix config to override the time zone guess."

                SettingRow {
                    title: "Source"

                    Text {
                        text: Sky.source === "config" ? "config.json" : Sky.source === "timezone" ? "Time zone (" + Sky.zone + ")" : "Unknown"
                        color: Theme.textSoft
                        font.family: Tokens.fontUi
                        font.pixelSize: Tokens.bodySize
                    }
                }

                SettingRow {
                    title: "Coordinates"
                    last: true

                    Text {
                        text: Sky.available ? Sky.latitude.toFixed(2) + ", " + Sky.longitude.toFixed(2) : "—"
                        color: Theme.textSoft
                        font.family: Tokens.fontMono
                        font.pixelSize: Tokens.bodySize
                    }
                }
            }
        }
    }

    Component {
        id: commandsPage

        Column {
            spacing: 24

            Card {
                title: "Keybinds for " + (Compositor.name === "hyprland" ? (Compositor.usingLua ? "Hyprland (Lua)" : "Hyprland") : Compositor.name)
                note: "Every part of Sylvaris is a `sylvaris` command. Copy a line into your compositor config; the keys are only suggestions."

                Repeater {
                    model: root.binds

                    delegate: SettingRow {
                        id: bindRow
                        required property var modelData
                        required property int index
                        readonly property string line: W.bindSnippet(Compositor.name, Compositor.usingLua, modelData.key, modelData.command)
                        title: modelData.label
                        subtitle: line
                        last: index === root.binds.length - 1

                        Chip {
                            text: "Copy"
                            glyph: Icons.GLYPHS.copy
                            onClicked: Quickshell.clipboardText = bindRow.line
                        }
                    }
                }
            }

            Card {
                title: "Everything else"
                note: "`sylvaris list` prints every part and action, `sylvaris get` and `sylvaris set` read and change any setting on this screen, and `sylvaris watch` streams state changes for scripts."
            }
        }
    }

    Component {
        id: aboutPage

        Column {
            spacing: 24

            Card {
                title: "Sylvaris"

                SettingRow {
                    title: "Compositor"

                    Text {
                        text: Compositor.name
                        color: Theme.textSoft
                        font.family: Tokens.fontUi
                        font.pixelSize: Tokens.bodySize
                    }
                }

                SettingRow {
                    title: "Configuration folder"
                    subtitle: Config.dir + "\nconfig.json is yours, settings.json is what this screen writes, themes/ holds theme bundles"

                    Chip {
                        text: "Open"
                        glyph: Icons.GLYPHS.open
                        onClicked: Quickshell.execDetached(["xdg-open", Config.dir])
                    }
                }

                SettingRow {
                    title: "Reload Sylvaris"
                    subtitle: "Reloads the shell without losing notifications"
                    last: true

                    Chip {
                        text: "Reload"
                        onClicked: Quickshell.reload(false)
                    }
                }
            }

            Card {
                title: "Credits"
                note: "The constellation idea is inspired by ilyamiro/serpantinum. AirPods support follows the accessory protocol documented by LibrePods."
            }
        }
    }
}
