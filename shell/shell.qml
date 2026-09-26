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
import qs.diver
import qs.switcher
import qs.lock
import qs.polkit
import qs.clip
import qs.capture
import qs.access
import qs.plugins
import "lib/ipc.mjs" as I
import "lib/eq.mjs" as E
import "lib/settings.mjs" as S
import "lib/modules.mjs" as M

ShellRoot {
    id: root

    readonly property bool ready: Config.ready && Settings.ready
    readonly property var live: root.ready ? S.liveParts(Settings.values.parts).concat(S.liveServices(Settings.values.parts)) : []
    readonly property var loaders: ({
            center: centerLoader,
            theme: themeLoader,
            clock: clockLoader,
            notify: notifyLoader,
            pad: padLoader,
            media: mediaLoader,
            settings: settingsLoader,
            power: powerLoader,
            paper: paperLoader,
            diver: diverLoader,
            switcher: switcherLoader,
            lock: lockLoader,
            polkit: polkitLoader,
            clip: clipLoader,
            capture: captureLoader,
            access: accessLoader,
            plugins: pluginsLoader
        })
    readonly property var parts: {
        const out = {};
        for (const name of Object.keys(root.loaders)) {
            if (root.loaders[name].item)
                out[name] = root.loaders[name].item;
        }
        return out;
    }
    readonly property var services: ({
            Sky: () => Sky,
            Weather: () => Weather,
            Diver: () => Diver,
            Notifications: () => Notifications,
            Apps: () => Apps,
            Equalizer: () => Equalizer,
            Headphones: () => Headphones,
            ThemePreview: () => ThemePreview,
            Audio: () => Audio,
            Media: () => Media,
            NightLight: () => NightLight,
            Dnd: () => Dnd,
            Toggles: () => Toggles,
            BluetoothService: () => BluetoothService,
            NetworkService: () => NetworkService,
            Hotspot: () => Hotspot,
            Displays: () => Displays,
            Plugins: () => Plugins
        })
    readonly property var boot: [Tokens, Ipc, Config, Settings, Theme, Resin, Compositor, Keybinds].concat(root.live.filter(name => root.services[name] !== undefined).map(name => root.services[name]()))

    readonly property var openPanel: {
        for (const name of ["center", "clock", "media", "notify", "paper"]) {
            const p = root.part(name);
            if (p !== null && p.wanted && p.screenInfo && p.placed !== undefined)
                return {
                    corner: p.placed,
                    width: p.panelWidth,
                    height: p.panelHeight,
                    screen: p.screenInfo.name
                };
        }
        return null;
    }

    function on(name: string): bool {
        return root.live.indexOf(name) >= 0;
    }

    function need(name: string): var {
        const p = root.part(name);
        if (p === null)
            throw new Error(name + " is excluded by the parts setting; turn it back on with: sylvaris set parts." + name + " true");
        return p;
    }

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
        return p !== null && p.wanted && p.screenInfo ? p.screenInfo.name : null;
    }

    function part(name: string): var {
        return root.parts[name] === undefined ? null : root.parts[name];
    }

    function stateObject(): var {
        const center = root.part("center");
        const clock = root.part("clock");
        const settings = root.part("settings");
        const pad = root.part("pad");
        const theme = root.part("theme");
        const out = {
            version: 1,
            compositor: Compositor.state(),
            audio: root.on("Audio") ? {
                available: Audio.available,
                volume: Audio.volume,
                muted: Audio.muted,
                output: Audio.outputName,
                sinks: Audio.sinks
            } : undefined,
            media: root.on("Media") ? Media.state() : undefined,
            eq: root.on("Equalizer") ? Object.assign({
                running: Equalizer.running,
                target: Equalizer.target
            }, Equalizer.cfg) : undefined,
            headphones: root.on("Headphones") ? Headphones.state() : undefined,
            nightLight: root.on("NightLight") ? {
                available: NightLight.available,
                enabled: NightLight.enabled,
                temperature: NightLight.temperature,
                error: NightLight.error
            } : undefined,
            dnd: root.on("Dnd") ? {
                available: Dnd.available,
                tool: Dnd.tool,
                enabled: Dnd.enabled
            } : undefined,
            toggles: root.on("Toggles") ? Toggles.items : undefined,
            bluetooth: root.on("BluetoothService") ? {
                available: BluetoothService.available,
                enabled: BluetoothService.enabled,
                scanning: BluetoothService.scanning,
                summary: BluetoothService.summary,
                items: BluetoothService.items,
                error: BluetoothService.error
            } : undefined,
            network: root.on("NetworkService") ? {
                available: NetworkService.available,
                hasWifi: NetworkService.hasWifi,
                enabled: NetworkService.enabled,
                summary: NetworkService.summary,
                items: NetworkService.items,
                error: NetworkService.error
            } : undefined,
            hotspot: root.on("Hotspot") ? {
                available: Hotspot.available,
                active: Hotspot.active,
                profileExists: Hotspot.profileExists,
                error: Hotspot.error
            } : undefined,
            displays: root.on("Displays") ? {
                available: Displays.available,
                key: Displays.key,
                outputs: Displays.outputs.map(o => o.name),
                countdown: Displays.countdown,
                enabled: Object.keys(Displays.current).filter(k => Displays.current[k].enabled),
                error: Displays.error
            } : undefined,
            parts: root.live.filter(name => root.services[name] === undefined),
            center: center !== null ? {
                open: center.shown,
                view: center.view,
                focus: center.focusKey,
                screen: center.screenInfo ? center.screenInfo.name : ""
            } : undefined,
            clock: clock !== null ? {
                open: clock.shown
            } : undefined,
            settingsPanel: settings !== null ? {
                open: settings.wanted,
                section: settings.section
            } : undefined,
            sky: root.on("Sky") ? Sky.state() : undefined,
            weather: root.on("Weather") ? Weather.state() : undefined,
            diver: root.on("Diver") ? Diver.state() : undefined,
            notifications: root.on("Notifications") ? Notifications.state() : undefined,
            pad: pad !== null ? {
                open: pad.wanted,
                query: pad.query,
                results: pad.results.length,
                page: pad.page,
                pages: pad.pageList.length,
                selected: pad.selected,
                launched: Apps.lastLaunched
            } : undefined,
            switcher: root.part("switcher") !== null ? root.part("switcher").state() : undefined,
            lock: root.part("lock") !== null ? root.part("lock").state() : undefined,
            polkit: root.part("polkit") !== null ? root.part("polkit").state() : undefined,
            clip: root.part("clip") !== null ? root.part("clip").state() : undefined,
            capture: root.part("capture") !== null ? root.part("capture").state() : undefined,
            access: root.part("access") !== null ? root.part("access").state() : undefined,
            keybinds: Keybinds.applied,
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
                linked: Theme.linked,
                open: theme !== null && theme.shown,
                front: theme !== null ? theme.front : null,
                original: theme !== null ? ThemePreview.original : null,
                applied: theme !== null ? ThemePreview.applied : null
            }
        };
        for (const key of Object.keys(out)) {
            if (out[key] === undefined)
                delete out[key];
        }
        return out;
    }

    LazyLoader {
        id: centerLoader
        active: root.on("center")

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
    }

    LazyLoader {
        id: themeLoader
        active: root.on("theme")

        SylTheme {
            id: themePart
            onOpened: root.solo(themePart)
        }
    }

    LazyLoader {
        id: clockLoader
        active: root.on("clock")

        SylClock {
            id: clockPart
            onOpened: root.solo(clockPart)
        }
    }

    LazyLoader {
        id: notifyLoader
        active: root.on("notify")

        SylNotify {
            id: notifyPart
            onOpened: root.solo(notifyPart)
        }
    }

    LazyLoader {
        id: padLoader
        active: root.on("pad")

        SylPad {
            id: padPart
            tiles: root.on("settings") ? M.tiles() : []
            onOpened: root.solo(padPart)
            onSettingsRequested: section => root.need("settings").showSection(section)
        }
    }

    LazyLoader {
        id: mediaLoader
        active: root.on("media")

        SylMedia {
            id: mediaPart
            onOpened: root.solo(mediaPart)
        }
    }

    LazyLoader {
        id: settingsLoader
        active: root.on("settings")

        SylSettings {
            id: settingsPart
            onOpened: root.solo(settingsPart)
            onPartRequested: (name, arg) => {
                const p = root.part(name);
                if (p === null)
                    return;
                if (name === "center") {
                    p.setView(arg);
                    return;
                }
                if (name === "media")
                    p.openTab(arg);
                p.open();
            }
        }
    }

    LazyLoader {
        id: powerLoader
        active: root.on("power")

        SylPower {
            id: powerPart
            onOpened: root.solo(powerPart)
        }
    }

    LazyLoader {
        id: paperLoader
        active: root.on("paper")

        SylPaper {
            id: paperPart
            onOpened: root.solo(paperPart)
        }
    }

    LazyLoader {
        id: diverLoader
        active: root.on("diver")

        SylDiver {
            id: diverPart
            onOpened: root.solo(diverPart)
        }
    }

    LazyLoader {
        id: pluginsLoader
        active: root.on("plugins")

        SylPlugins {
            id: pluginsPart
            onOpened: root.solo(pluginsPart)
        }
    }

    LazyLoader {
        id: accessLoader
        active: root.on("access")

        SylAccess {
            id: accessPart
            onOpened: root.solo(accessPart)
        }
    }

    LazyLoader {
        id: captureLoader
        active: root.on("capture")

        SylCapture {
            id: capturePart
            onOpened: root.solo(capturePart)
        }
    }

    LazyLoader {
        id: clipLoader
        active: root.on("clip")

        SylClip {
            id: clipPart
            onOpened: root.solo(clipPart)
        }
    }

    LazyLoader {
        id: polkitLoader
        active: root.on("polkit")

        SylPolkit {
            id: polkitPart
            onOpened: root.solo(polkitPart)
        }
    }

    LazyLoader {
        id: lockLoader
        active: root.on("lock")

        SylLock {
            id: lockPart
            onOpened: root.solo(lockPart)
        }
    }

    LazyLoader {
        id: switcherLoader
        active: root.on("switcher")

        SylSwitch {
            id: switcherPart
            onOpened: root.solo(switcherPart)
        }
    }

    LazyLoader {
        active: root.on("notify")

        Toasts {
            avoid: root.openPanel
        }
    }

    LazyLoader {
        active: root.on("bar")

        SylBar {
            open: ({
                    center: root.screenOf(root.part("center")),
                    clock: root.screenOf(root.part("clock")),
                    notify: root.screenOf(root.part("notify")),
                    pad: root.screenOf(root.part("pad")),
                    power: root.screenOf(root.part("power"))
                })
            onRequest: (name, arg, screen) => root.openOn(name, arg, screen)
        }
    }

    LazyLoader {
        active: root.on("deck")

        SylDeck {
            padOpen: root.part("pad") !== null && root.part("pad").wanted
            onRequest: (name, arg, screen) => root.openOn(name, arg, screen)
        }
    }

    function setting(key: string, value: string): string {
        if (key === "")
            throw new Error("usage: set <key> <value>");
        if (!Settings.trySet(key, I.parseValue(value)))
            throw new Error("invalid value for " + key + ", it stays " + JSON.stringify(Settings.get(key)));
        return JSON.stringify(Settings.get(key));
    }

    readonly property var owners: ({
            center: "center",
            clock: "clock",
            pad: "pad",
            paper: "paper",
            power: "power",
            notify: "Notifications",
            diver: "Diver",
            weather: "Weather",
            audio: "Audio",
            media: "Media",
            eq: "Equalizer",
            headphones: "Headphones",
            nightlight: "NightLight",
            dnd: "Dnd",
            wifi: "NetworkService",
            bluetooth: "BluetoothService"
        })

    readonly property var commands: {
        const all = ({
            center: {
                toggle: () => root.need("center").toggle(),
                open: () => root.need("center").open(),
                close: () => root.need("center").close(),
                view: name => {
                    if (name === undefined)
                        throw new Error("usage: center view <name>");
                    if (name === "theme")
                        root.need("theme").open();
                    else
                        root.need("center").setView(name);
                }
            },
            theme: {
                toggle: () => root.need("theme").toggle(),
                open: () => root.need("theme").open(),
                close: () => root.need("theme").close(),
                next: () => root.need("theme").step(1),
                prev: () => root.need("theme").step(-1),
                apply: () => root.need("theme").commit(),
                cycle: () => Theme.cycle(),
                search: (...q) => {
                    root.need("theme").query = q.join(" ");
                    return root.need("theme").ids;
                },
                set: id => {
                    if (Theme.ids.indexOf(id) < 0)
                        throw new Error("unknown theme: " + id);
                    Theme.apply(id);
                },
                list: () => Theme.ids
            },
            clock: {
                toggle: () => root.need("clock").toggle(),
                open: () => root.need("clock").open(),
                close: () => root.need("clock").close(),
                day: key => {
                    const c = root.need("clock");
                    const d = key === undefined || key === "today" ? Qt.formatDate(new Date(), "yyyy-MM-dd") : key;
                    if (!/^\d{4}-\d{2}-\d{2}$/.test(d))
                        throw new Error("usage: clock day <yyyy-mm-dd|today>");
                    c.open();
                    c.picked = d;
                }
            },
            notify: {
                toggle: () => root.need("notify").toggle(),
                open: () => root.need("notify").open(),
                close: () => root.need("notify").close(),
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
                toggle: () => root.need("settings").toggle(),
                open: section => root.need("settings").showSection(section || ""),
                close: () => root.need("settings").close(),
                all: () => Settings.values,
                get: key => Settings.get(key) === undefined ? null : Settings.get(key),
                set: (key, ...rest) => root.setting(key || "", rest.join(" "))
            },
            diver: {
                default: "state",
                state: () => Diver.state(),
                sync: () => Diver.sync(),
                toggle: () => root.need("diver").toggle(),
                open: () => root.need("diver").open(),
                close: () => root.need("diver").close(),
                view: v => {
                    const d = root.need("diver");
                    d.panel.setView(v || "");
                    d.open();
                },
                new: (...words) => {
                    root.need("diver");
                    Diver.request("new", words.join(" "), "");
                },
                edit: id => {
                    root.need("diver");
                    if (Diver.find(id || "") === null)
                        throw new Error("no task with id " + id);
                    Diver.request("edit", id, "");
                },
                day: key => {
                    root.need("diver");
                    const d = key === undefined || key === "today" ? Qt.formatDate(new Date(), "yyyy-MM-dd") : key;
                    if (!/^\d{4}-\d{2}-\d{2}$/.test(d))
                        throw new Error("usage: diver day <yyyy-mm-dd|today>");
                    Diver.request("day", "", d);
                },
                delete: id => Diver.remove(id || ""),
                set: (id, field, ...value) => Diver.setField(id || "", field || "", value.join(" ")),
                move: (id, where) => Diver.move(id || "", where || ""),
                list: (verb, path, ...name) => Diver.listOp(verb || "", path === undefined ? "" : path, name.join(" ")),
                lists: () => Diver.lists(),
                focus: (id, minutes) => Diver.startFocus(id || "", Number(minutes || 25)),
                unfocus: () => Diver.stopFocus(),
                pair: code => Diver.pair(code || ""),
                unpair: () => Diver.unpair(),
                add: (...words) => {
                    if (words.length === 0)
                        throw new Error("usage: diver add <text, e.g. call mom tomorrow 18:00>");
                    return Diver.add(words.join(" "), "");
                },
                done: id => Diver.done(id || ""),
                snooze: (id, minutes) => Diver.snooze(id || "", Number(minutes || 10)),
                today: () => Diver.state().today,
                next: () => Diver.state().next,
                test: () => {
                    Diver.alarm = {
                        rid: "test",
                        id: "",
                        at: Date.now(),
                        start: Date.now(),
                        before: 0,
                        alarm: true,
                        title: "This is how a Diver alarm looks",
                        path: "test"
                    };
                },
                dismiss: () => Diver.dismiss()
            },
            weather: {
                default: "state",
                state: () => Weather.state(),
                refresh: () => Weather.refresh()
            },
            paper: {
                toggle: () => root.need("paper").toggle(),
                open: () => root.need("paper").open(),
                close: () => root.need("paper").close(),
                set: (...p) => root.need("paper").set(p.join(" ")),
                next: () => root.need("paper").step(1),
                prev: () => root.need("paper").step(-1),
                reset: () => root.need("paper").reset(),
                current: () => root.need("paper").current
            },
            power: {
                toggle: () => root.need("power").toggle(),
                open: () => root.need("power").open(),
                close: () => root.need("power").close(),
                list: () => root.need("power").ids,
                run: id => root.need("power").run(id || "")
            },
            pad: {
                toggle: () => root.need("pad").toggle(),
                open: () => root.need("pad").open(),
                close: () => root.need("pad").close()
            },
            plugins: {
                default: "list",
                toggle: () => root.need("plugins").toggle(),
                open: id => id ? root.need("plugins").openPlugin(id) : root.need("plugins").open(),
                close: () => root.need("plugins").close(),
                list: () => Plugins.state().plugins,
                enable: id => {
                    if (Plugins.byId(id || "") === null)
                        throw new Error("no working plugin called " + id);
                    Plugins.setEnabled(id, true);
                },
                disable: id => Plugins.setEnabled(id || "", false),
                new: (id, kind) => Plugins.create(id || "", kind || "bar"),
                install: url => Plugins.install(url || ""),
                remove: id => Plugins.remove(id || ""),
                refresh: () => Plugins.refresh(),
                state: () => Plugins.state()
            },
            access: {
                toggle: () => root.need("access").toggle(),
                open: () => root.need("access").open(),
                close: () => root.need("access").close(),
                zoom: v => root.need("access").zoom(v || "in"),
                filter: name => root.need("access").filter(name || "none"),
                state: () => root.need("access").state()
            },
            capture: {
                toggle: () => root.need("capture").toggle(),
                open: () => root.need("capture").open(),
                close: () => root.need("capture").close(),
                shot: mode => root.need("capture").shoot(mode || "region"),
                record: mode => root.need("capture").record(mode || "region"),
                stop: () => root.need("capture").stop(),
                state: () => root.need("capture").state()
            },
            clip: {
                toggle: () => root.need("clip").toggle(),
                open: () => root.need("clip").open(),
                close: () => root.need("clip").close(),
                clear: () => root.need("clip").clear(),
                list: () => root.need("clip").state().items,
                copy: n => {
                    const c = root.need("clip");
                    const e = c.shownList[Number(n || 1) - 1];
                    if (e === undefined)
                        throw new Error("usage: clip copy <number from clip list>");
                    c.copy(e);
                },
                state: () => root.need("clip").state()
            },
            polkit: {
                default: "state",
                state: () => root.need("polkit").state(),
                preview: () => root.need("polkit").showPreview(),
                cancel: () => root.need("polkit").cancel()
            },
            lock: {
                default: "now",
                now: () => root.need("lock").lock(),
                state: () => root.need("lock").state()
            },
            switcher: {
                default: "next",
                next: () => root.need("switcher").step(1),
                prev: () => root.need("switcher").step(-1),
                commit: () => root.need("switcher").commit(),
                close: () => root.need("switcher").close(),
                state: () => root.need("switcher").state()
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
                        root.need("media").openTab(tab);
                    root.need("media").open();
                },
                close: () => root.need("media").close(),
                panel: () => root.need("media").toggle()
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
        });
        const out = {};
        for (const name of Object.keys(all)) {
            if (root.owners[name] === undefined || root.on(root.owners[name]))
                out[name] = all[name];
        }
        return out;
    }

    Binding {
        target: Tokens
        property: "lite"
        value: Settings.values.performance || Settings.values.toggleState.performance === true
    }

    Binding {
        target: Tokens
        property: "textScale"
        value: Settings.values.access.text
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
