import QtQuick
import Quickshell
import Quickshell.Io
import qs.greet

ShellRoot {
    SylGreet {
        id: greet
    }

    IpcHandler {
        target: "sylvaris"

        function run(request: string): string {
            return JSON.stringify(greet.state());
        }
    }
}
