import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.cc

ShellRoot {
    id: root

    property var parts: ({
            cc: ccPart
        })
    readonly property var boot: [Tokens, Config, Settings, Theme, Compositor, Audio, Media, NightLight, Dnd, Toggles, BluetoothService, NetworkService, Hotspot, Displays]

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
                error: Displays.error
            },
            parts: Object.keys(root.parts),
            cc: {
                open: ccPart.shown,
                view: ccPart.view,
                focus: ccPart.focusKey
            },
            config: Config.values,
            configNotice: Config.notice,
            settings: Settings.values,
            settingsNotice: Settings.notice,
            theme: {
                id: Theme.currentId,
                active: Theme.theme.id,
                name: Theme.theme.name,
                errors: Theme.errors,
                ids: Theme.ids,
                tokens: Theme.target
            }
        };
    }

    SylvarisCC {
        id: ccPart
    }

    IpcHandler {
        target: "sylvaris"

        function toggle(name: string): string {
            const p = root.part(name);
            if (p === null)
                return "unknown part: " + name;
            p.toggle();
            return "ok";
        }

        function open(name: string): string {
            const p = root.part(name);
            if (p === null)
                return "unknown part: " + name;
            p.open();
            return "ok";
        }

        function close(name: string): string {
            const p = root.part(name);
            if (p === null)
                return "unknown part: " + name;
            p.close();
            return "ok";
        }

        function view(name: string): string {
            const p = root.part("cc");
            if (p === null)
                return "unknown part: cc";
            p.setView(name);
            return "ok";
        }

        function state(): string {
            return JSON.stringify(root.stateObject());
        }
    }
}
