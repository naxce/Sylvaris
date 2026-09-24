import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.center
import qs.theme
import "lib/ipc.mjs" as I

ShellRoot {
    id: root

    property var parts: ({
            center: centerPart,
            theme: themePart
        })
    readonly property var boot: [Tokens, Ipc, Config, Settings, Theme, Resin, ThemePreview, Compositor, Audio, Media, NightLight, Dnd, Toggles, BluetoothService, NetworkService, Hotspot, Displays]

    function part(name: string): var {
        return root.parts[name] === undefined ? null : root.parts[name];
    }

    function stateObject(): var {
        return {
            version: 1,
            compositor: {
                name: Compositor.name,
                focused: Compositor.focusedName(),
                screens: Compositor.screenNames()
            },
            audio: {
                available: Audio.available,
                volume: Audio.volume,
                muted: Audio.muted,
                output: Audio.outputName,
                sinks: Audio.sinks
            },
            media: {
                available: Media.available,
                title: Media.title,
                playing: Media.playing
            },
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
                themePart.cancel();
        }
    }

    SylTheme {
        id: themePart
        onOpened: centerPart.close()
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
                set: id => {
                    if (Theme.ids.indexOf(id) < 0)
                        throw new Error("unknown theme: " + id);
                    Theme.apply(id);
                },
                list: () => Theme.ids
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
                previous: () => Media.previous()
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
            settings: {
                default: "all",
                all: () => Settings.values,
                get: key => Settings.get(key) === undefined ? null : Settings.get(key),
                set: (key, ...rest) => root.setting(key || "", rest.join(" "))
            },
            list: {
                default: "all",
                all: () => Ipc.list()
            }
        })

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
