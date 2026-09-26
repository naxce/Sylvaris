import QtQuick
import Quickshell
import qs
import qs.services
import qs.components
import "../lib/icons.mjs" as Icons

Column {
    id: root

    property string armed: ""
    property string problem: ""
    property string newKind: "bar"

    function attempt(fn: var): void {
        try {
            root.problem = "";
            fn();
        } catch (e) {
            root.problem = e.message;
        }
    }

    spacing: 24

    Component.onCompleted: Plugins.refresh()

    Card {
        title: "Installed"
        note: "Plugins live in " + Plugins.dir + ". They run with the same rights as Sylvaris, so only turn on ones you trust. A bar plugin shows up once you add plugin:<id> to a bar group; a panel opens with “sylvaris plugins open <id>”."

        Text {
            visible: Plugins.list.length === 0
            width: parent.width
            topPadding: 4
            bottomPadding: 8
            text: "No plugins yet. Make one below or install one from a Git address."
            color: Theme.textDim
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.smallSize
        }

        Repeater {
            model: Plugins.list

            delegate: SettingRow {
                required property var modelData
                required property int index
                title: modelData.ok ? modelData.manifest.name + "  ·  " + modelData.manifest.kind : modelData.id
                subtitle: modelData.ok ? (modelData.manifest.description || modelData.id) + (modelData.manifest.version ? " · " + modelData.manifest.version : "") : "Not loaded: " + modelData.error
                last: index === Plugins.list.length - 1

                Row {
                    spacing: 8

                    Chip {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.armed === modelData.id ? "Really remove?" : "Remove"
                        glyph: Icons.GLYPHS.trash
                        lit: root.armed === modelData.id
                        onClicked: {
                            if (root.armed !== modelData.id) {
                                root.armed = modelData.id;
                                return;
                            }
                            root.armed = "";
                            root.attempt(() => Plugins.remove(modelData.id));
                        }
                    }

                    Toggle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: modelData.ok
                        checked: Plugins.isEnabled(modelData.id)
                        onToggled: v => Plugins.setEnabled(modelData.id, v)
                    }
                }
            }
        }
    }

    Card {
        title: "Make a plugin"
        note: "Creates a folder with plugin.json and a Plugin.qml that already works. Plugins can import qs, qs.services and qs.components to look like the rest of Sylvaris."

        Row {
            width: parent.width
            spacing: 8

            TextBox {
                id: newId
                width: parent.width - kindPick.width - makeChip.width - 16
                placeholder: "my-plugin"
            }

            Segmented {
                id: kindPick
                width: 210
                anchors.verticalCenter: parent.verticalCenter
                options: [
                    {
                        key: "bar",
                        label: "Bar"
                    },
                    {
                        key: "panel",
                        label: "Panel"
                    },
                    {
                        key: "service",
                        label: "Service"
                    }
                ]
                current: root.newKind
                onPicked: key => root.newKind = key
            }

            Chip {
                id: makeChip
                anchors.verticalCenter: parent.verticalCenter
                text: "Create"
                glyph: Icons.GLYPHS.plus
                onClicked: root.attempt(() => {
                    Plugins.create(newId.text.trim(), root.newKind);
                    newId.text = "";
                })
            }
        }
    }

    Card {
        title: "Install from Git"
        note: "Clones a plugin into the plugins folder. It stays off until you turn it on above."

        Row {
            width: parent.width
            spacing: 8

            TextBox {
                id: gitUrl
                width: parent.width - installChip.width - 8
                placeholder: "https://github.com/someone/some-plugin"
            }

            Chip {
                id: installChip
                anchors.verticalCenter: parent.verticalCenter
                text: Plugins.busy ? "Installing…" : "Install"
                glyph: Icons.GLYPHS.web
                onClicked: root.attempt(() => {
                    Plugins.install(gitUrl.text.trim());
                    gitUrl.text = "";
                })
            }
        }

        Text {
            width: parent.width
            visible: text !== ""
            topPadding: 8
            wrapMode: Text.Wrap
            text: root.problem !== "" ? root.problem : Plugins.problem
            color: Theme.danger
            font.family: Tokens.fontUi
            font.pixelSize: Tokens.smallSize
        }

        RowButton {
            icon: Icons.GLYPHS.folder
            label: "Open the plugins folder"
            onClicked: Quickshell.execDetached(["sh", "-c", "mkdir -p \"$0\" && xdg-open \"$0\"", Plugins.dir])
        }
    }
}
