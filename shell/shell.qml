import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property var parts: ({})

    function part(name: string): var {
        return root.parts[name] === undefined ? null : root.parts[name];
    }

    function stateObject(): var {
        return {
            version: 1,
            parts: Object.keys(root.parts)
        };
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
