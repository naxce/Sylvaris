import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.center
import qs.theme
import qs.clock
import qs.notify
import qs.pad
import qs.bar
import qs.deck
import qs.media
import qs.settings
import qs.power
import qs.paper
import "lib/ipc.mjs" as I
import "lib/eq.mjs" as E

ShellRoot {
    id: root

    property var parts: ({
            center: centerPart,
            theme: themePart,
            clock: clockPart,
            notify: notifyPart,
            pad: padPart,
            media: mediaPart,
            settings: settingsPart,
            power: powerPart,
            paper: paperPart
        })
    readonly property var boot: [Tokens, Ipc, Config, Settings, Sky, Weather, Notifications, Apps, Equalizer, Headphones, Theme, Resin, ThemePreview, Compositor, Audio, Media, NightLight, Dnd, Toggles, BluetoothService, NetworkService, Hotspot, Displays]

    function solo(keep: var): void {
        for (const name of Object.keys(root.parts)) {
            if (root.parts[name] !== keep)
                root.parts[name].close();
        }
    }

    function openOn(name: string, arg: string, screen: var): void {
        const p = root.part(name);
        if (p === null)
            return;
        if (name === "center")
            p.toggleOn(screen, arg);
        else
            p.toggleOn(screen);
    }

    function screenOf(p: var): var {
        return p.wanted && p.screenInfo ? p.screenInfo.name : null;
    }

    function part(name: string): var {
        return root.parts[name] === undefined ? null : root.parts[name];
    }

    function stateObject(): var {
        return {
            version: 1,
            compositor: Compositor.state(),
            audio: {
                available: Audio.available,
                volume: Audio.volume,
                muted: Audio.muted,
                output: Audio.outputName,
                sinks: Audio.sinks
            },
            media: Media.state(),
            eq: Object.assign({
                running: Equalizer.running,
                target: Equalizer.target
            }, Equalizer.cfg),
            headphones: Headphones.state(),
            nightLight: {
                available: NightLight.available,
                enabled: NightLight.enabled,
                temperature: NightLight.temperature,
                error: NightLight.error
            },
            dnd: {
                available: Dnd.available,
                tool: Dnd.tool,
                enabled: Dnd.enabled
            },
            toggles: Toggles.items,
            bluetooth: {
                available: BluetoothService.available,
                enabled: BluetoothService.enabled,
                scanning: BluetoothService.scanning,
                summary: BluetoothService.summary,
                items: BluetoothService.items,
                error: BluetoothService.error
            },
            network: {
                available: NetworkService.available,
                hasWifi: NetworkService.hasWifi,
                enabled: NetworkService.enabled,
                summary: NetworkService.summary,
                items: NetworkService.items,
                error: NetworkService.error
            },
            hotspot: {
                available: Hotspot.available,
                active: Hotspot.active,
                profileExists: Hotspot.profileExists,
                error: Hotspot.error
            },
            displays: {
                available: Displays.available,
                key: Displays.key,
                outputs: Displays.outputs.map(o => o.name),
                countdown: Displays.countdown,
                enabled: Object.keys(Displays.current).filter(k => Displays.current[k].enabled),
                error: Displays.error
            },
            parts: Object.keys(root.parts),
            center: {
                open: centerPart.shown,
                view: centerPart.view,
                focus: centerPart.focusKey,
                screen: centerPart.screenInfo ? centerPart.screenInfo.name : ""
            },
            clock: {
                open: clockPart.shown
            },
            settingsPanel: {
                open: settingsPart.wanted,
                section: settingsPart.section
            },
            sky: Sky.state(),
            weather: Weather.state(),
            notifications: Notifications.state(),
            pad: {
                open: padPart.wanted,
                query: padPart.query,
                results: padPart.results.length,
                page: padPart.page,
                pages: padPart.pageList.length,
                selected: padPart.selected,
                launched: Apps.lastLaunched
            },
            config: Config.values,
            configNotice: Config.notice,
            settings: Settings.values,
            settingsNotice: Settings.notice,
            glass: {
                values: Resin.values,
                notice: Resin.notice
            },
            theme: {
                id: Theme.currentId,
                active: Theme.theme.id,
                name: Theme.theme.name,
                errors: Theme.errors,
                ids: Theme.ids,
                tokens: Theme.target,
                catalog: Object.keys(Theme.catalog).sort(),
                hookError: Theme.hookError,
                open: themePart.shown,
                front: themePart.front,
                original: ThemePreview.original,
                applied: ThemePreview.applied
            }
        };
    }

    SylCenter {
        id: centerPart
        onPartRequested: name => {
            const p = root.part(name);
            if (p !== null)
                p.open();
        }
        onShownChanged: {
            if (centerPart.shown)
                root.solo(centerPart);
        }
    }

    SylTheme {
        id: themePart
        onOpened: root.solo(themePart)
    }

    SylClock {
        id: clockPart
        onOpened: root.solo(clockPart)
    }

    SylNotify {
        id: notifyPart
        onOpened: root.solo(notifyPart)
    }

    SylPad {
        id: padPart
        onOpened: root.solo(padPart)
    }

    SylMedia {
        id: mediaPart
        onOpened: root.solo(mediaPart)
    }

    SylSettings {
        id: settingsPart
        onOpened: root.solo(settingsPart)
        onPartRequested: (name, arg) => {
            if (name === "center")
                centerPart.setView(arg);
            else if (name === "media") {
                mediaPart.openTab(arg);
                mediaPart.open();
            } else if (root.part(name) !== null) {
                root.part(name).open();
            }
        }
    }

    SylPower {
        id: powerPart
        onOpened: root.solo(powerPart)
    }

    SylPaper {
        id: paperPart
        onOpened: root.solo(paperPart)
    }

    Toasts {}

    SylBar {
        open: ({
                center: root.screenOf(centerPart),
                clock: root.screenOf(clockPart),
                notify: root.screenOf(notifyPart),
                pad: root.screenOf(padPart),
                power: root.screenOf(powerPart)
            })
        onRequest: (name, arg, screen) => root.openOn(name, arg, screen)
    }

    SylDeck {
        padOpen: padPart.wanted
        onRequest: (name, arg, screen) => root.openOn(name, arg, screen)
    }

    function setting(key: string, value: string): string {
        if (key === "")
            throw new Error("usage: set <key> <value>");
        if (!Settings.trySet(key, I.parseValue(value)))
            throw new Error("invalid value for " + key + ", it stays " + JSON.stringify(Settings.get(key)));
        return JSON.stringify(Settings.get(key));
    }

    readonly property var commands: ({
            center: {
                toggle: () => centerPart.toggle(),
                open: () => centerPart.open(),
                close: () => centerPart.close(),
                view: name => {
                    if (name === undefined)
                        throw new Error("usage: center view <name>");
                    if (name === "theme")
                        themePart.open();
                    else
                        centerPart.setView(name);
                }
            },
            theme: {
                toggle: () => themePart.toggle(),
                open: () => themePart.open(),
                close: () => themePart.close(),
                next: () => themePart.step(1),
                prev: () => themePart.step(-1),
                apply: () => themePart.commit(),
                cycle: () => Theme.cycle(),
                search: (...q) => {
                    themePart.query = q.join(" ");
                    return themePart.ids;
                },
                set: id => {
                    if (Theme.ids.indexOf(id) < 0)
                        throw new Error("unknown theme: " + id);
                    Theme.apply(id);
                },
                list: () => Theme.ids
            },
            clock: {
                toggle: () => clockPart.toggle(),
                open: () => clockPart.open(),
                close: () => clockPart.close()
            },
            notify: {
                toggle: () => notifyPart.toggle(),
                open: () => notifyPart.open(),
                close: () => notifyPart.close(),
                clear: () => Notifications.clear(),
                dismiss: id => {
                    if (Notifications.entry(Number(id)) === null)
                        throw new Error("no notification with id " + id);
                    Notifications.dismiss(Number(id));
                },
                invoke: (id, action) => {
                    if (Notifications.entry(Number(id)) === null)
                        throw new Error("no notification with id " + id);
                    Notifications.invoke(Number(id), action || "default");
                }
            },
            settings: {
                toggle: () => settingsPart.toggle(),
                open: section => settingsPart.showSection(section || ""),
                close: () => settingsPart.close(),
                all: () => Settings.values,
                get: key => Settings.get(key) === undefined ? null : Settings.get(key),
                set: (key, ...rest) => root.setting(key || "", rest.join(" "))
            },
            weather: {
                default: "state",
                state: () => Weather.state(),
                refresh: () => Weather.refresh()
            },
            paper: {
                toggle: () => paperPart.toggle(),
                open: () => paperPart.open(),
                close: () => paperPart.close(),
                set: (...p) => paperPart.set(p.join(" ")),
                next: () => paperPart.step(1),
                prev: () => paperPart.step(-1),
                reset: () => paperPart.reset(),
                current: () => paperPart.current
            },
            power: {
                toggle: () => powerPart.toggle(),
                open: () => powerPart.open(),
                close: () => powerPart.close(),
                list: () => powerPart.ids,
                run: id => powerPart.run(id || "")
            },
            pad: {
                toggle: () => padPart.toggle(),
                open: () => padPart.open(),
                close: () => padPart.close()
            },
            wm: {
                default: "state",
                state: () => Compositor.state(),
                workspace: (...a) => Compositor.run("workspace", a),
                "move-to": (...a) => Compositor.run("move-to", a),
                focus: (...a) => Compositor.run("focus", a),
                move: (...a) => Compositor.run("move", a),
                close: () => Compositor.run("close", []),
                fullscreen: () => Compositor.run("fullscreen", []),
                float: () => Compositor.run("float", []),
                exec: (...a) => Compositor.run("exec", a),
                reload: () => Compositor.run("reload", []),
                quit: () => Compositor.run("quit", [])
            },
            audio: {
                default: "mute",
                up: step => Audio.setVolume(Audio.volume + Number(step || 5) / 100),
                down: step => Audio.setVolume(Audio.volume - Number(step || 5) / 100),
                set: v => Audio.setVolume(Number(v) / 100),
                mute: () => Audio.toggleMute()
            },
            media: {
                toggle: () => Media.toggle(),
                next: () => Media.next(),
                previous: () => Media.previous(),
                seek: s => Media.seekTo(Number(s)),
                open: tab => {
                    if (tab !== undefined)
                        mediaPart.openTab(tab);
                    mediaPart.open();
                },
                close: () => mediaPart.close(),
                panel: () => mediaPart.toggle()
            },
            eq: {
                toggle: () => Equalizer.set({
                        enabled: !Equalizer.cfg.enabled
                    }),
                on: () => Equalizer.set({
                        enabled: true
                    }),
                off: () => Equalizer.set({
                        enabled: false
                    }),
                preset: name => {
                    if (E.PRESETS[name] === undefined)
                        throw new Error("presets: " + Object.keys(E.PRESETS).join(", "));
                    Equalizer.set({
                        preset: name,
                        enabled: true
                    });
                },
                band: (i, db) => {
                    const n = Number(i);
                    if (!(n >= 1 && n <= E.BANDS.length) || isNaN(Number(db)))
                        throw new Error("usage: eq band <1-" + E.BANDS.length + "> <dB>");
                    Equalizer.setBand(n - 1, Math.max(-E.LIMIT, Math.min(E.LIMIT, Number(db))));
                },
                spatial: v => Equalizer.set({
                        spatial: v === undefined ? !Equalizer.cfg.spatial : v === "on"
                    })
            },
            headphones: {
                default: "state",
                state: () => Headphones.state(),
                noise: mode => Headphones.setNoise(mode),
                awareness: v => Headphones.setAwareness(v === undefined ? !Headphones.awareness : v === "on")
            },
            nightlight: {
                toggle: () => NightLight.setEnabled(!NightLight.enabled),
                on: () => NightLight.setEnabled(true),
                off: () => NightLight.setEnabled(false)
            },
            dnd: {
                toggle: () => Dnd.setEnabled(!Dnd.enabled),
                on: () => Dnd.setEnabled(true),
                off: () => Dnd.setEnabled(false)
            },
            wifi: {
                toggle: () => NetworkService.setEnabled(!NetworkService.enabled),
                on: () => NetworkService.setEnabled(true),
                off: () => NetworkService.setEnabled(false)
            },
            bluetooth: {
                toggle: () => BluetoothService.setEnabled(!BluetoothService.enabled),
                on: () => BluetoothService.setEnabled(true),
                off: () => BluetoothService.setEnabled(false)
            },
            state: {
                default: "all",
                all: () => root.stateObject(),
                get: key => {
                    const v = root.stateObject()[key];
                    if (v === undefined)
                        throw new Error("unknown state topic: " + key);
                    return v;
                }
            },
            list: {
                default: "all",
                all: () => Ipc.list()
            },
            shell: {
                default: "config",
                reload: () => Quickshell.reload(false),
                config: () => ({
                        folder: Config.dir,
                        config: Config.path,
                        settings: Settings.path,
                        themes: Theme.themesDir,
                        state: Theme.stateFile
                    })
            }
        })

    Binding {
        target: Tokens
        property: "lite"
        value: Settings.values.performance || Settings.values.toggleState.performance === true
    }

    Binding {
        target: Tokens
        property: "motion"
        value: Settings.values.motion.reduced ? 0.01 : Settings.values.motion.scale
    }

    Binding {
        target: Ipc
        property: "commands"
        value: root.commands
    }

    Binding {
        target: Ipc
        property: "snapshot"
        value: root.stateObject()
    }

    IpcHandler {
        target: "sylvaris"

        function run(request: string): string {
            const r = I.parseRequest(request);
            return r.ok ? Ipc.run(r.words) : "error: " + r.error;
        }
    }
}
