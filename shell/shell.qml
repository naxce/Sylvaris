import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.cc
import qs.tp

ShellRoot {
    id: root

    property var parts: ({
            cc: ccPart,
            tp: tpPart
        })
    readonly property var boot: [Tokens, Config, Settings, Theme, Resin, ThemePreview, Compositor, Audio, Media, NightLight, Dnd, Toggles, BluetoothService, NetworkService, Hotspot, Displays]

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
            cc: {
                open: ccPart.shown,
                view: ccPart.view,
                focus: ccPart.focusKey,
                screen: ccPart.screenInfo ? ccPart.screenInfo.name : ""
            },
            tp: {
                open: tpPart.shown,
                front: tpPart.front,
                original: ThemePreview.original,
                applied: ThemePreview.applied
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
                hookError: Theme.hookError
            }
        };
    }

    SylvarisCC {
        id: ccPart
        onPartRequested: name => {
            const p = root.part(name);
            if (p !== null)
                p.open();
        }
        onShownChanged: {
            if (ccPart.shown)
                tpPart.cancel();
        }
    }

    SylvarisTP {
        id: tpPart
        onOpened: ccPart.close()
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
            if (name === "tp") {
                tpPart.open();
                return "ok";
            }
            const p = root.part("cc");
            if (p === null)
                return "unknown part: cc";
            p.setView(name);
            return "ok";
        }

        function tp(action: string): string {
            if (action === "next")
                tpPart.step(1);
            else if (action === "prev")
                tpPart.step(-1);
            else if (action === "apply")
                tpPart.commit();
            else
                return "unknown tp action: " + action;
            return "ok";
        }

        function state(): string {
            return JSON.stringify(root.stateObject());
        }
    }
}
