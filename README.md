# Sylvaris

A modular desktop shell built on [Quickshell](https://quickshell.org), made for **Hyprland** and **niri** and also working on **sway**. Sylvaris runs as one resident process, SylCore, that hosts parts:

- **SylCenter**: a control center that morphs from a compact panel into living orbits for Wi-Fi and Bluetooth
- **SylClock**: the time, a live sky with the real paths of the sun and moon, the moon's phase, sunrise and sunset, and a month calendar
- **SylNotify**: the notification daemon, with glass toasts and a notification center

SylTheme (theme picker) and SylSettings (full-screen settings) are next.

## Install

### Nix flake with Home Manager

```nix
{
  inputs.sylvaris.url = "github:naxce/Sylvaris";

  outputs = { sylvaris, ... }: {
    homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
      modules = [
        sylvaris.homeManagerModules.sylvaris
        {
          programs.sylvaris = {
            enable = true;
            settings = {
              themeHook = "";
              toggles = [
                { id = "performance"; label = "Performance"; on = "gamemode-on"; off = "gamemode-off"; }
              ];
            };
            themes.midnight = {
              name = "Midnight";
              wallpaper = "~/Pictures/midnight.png";
              colors = { base = "#0f1117"; surface = "#1a1d27"; accent = "#7aa2f7"; accentHi = "#9ab8ff"; accentDeep = "#4c6ab3"; onAccent = "#0f1117"; text = "#e6e9f2"; textDim = "#8d94a8"; danger = "#e06c75"; };
            };
          };
        }
      ];
    };
  };
}
```

### Without Nix

1. Install `quickshell` (0.3.1 or newer), `wlr-randr`, `wlsunset`, NetworkManager (`nmcli`), `pactl`, `wl-clipboard`, and the fonts **Inter** and **JetBrainsMono Nerd Font**.
2. Copy `shell/` to `~/.config/quickshell/sylvaris`.
3. Put `bin/sylvaris` on your `PATH`.

## Start it with your compositor

| Compositor | Autostart | Toggle the control center |
|---|---|---|
| Hyprland (`hyprland.conf`) | `exec-once = sylvaris` | `bind = SUPER, A, exec, sylvaris center` |
| Hyprland (Lua) | `hl.exec_cmd("sylvaris")` inside `hl.on("hyprland.start", ...)` | `hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("sylvaris center"))` |
| niri | `spawn-at-startup "sylvaris"` | `Mod+A { spawn "sylvaris" "center"; }` |
| sway | `exec sylvaris` | `bindsym $mod+a exec sylvaris center` |

Waybar button: `"on-click": "sylvaris center"`.

The panel is translucent, so turn on blur behind the `sylcenter` layer:

```lua
hl.layer_rule({ name = "sylcenter", match = { namespace = "sylcenter" }, blur = true, ignore_alpha = 0.3 })
```

```ini
layerrule = blur, sylcenter
layerrule = ignorealpha 0.3, sylcenter
```

SylTheme animates itself, so turn off Hyprland's own layer animation for it:

```lua
hl.layer_rule({ name = "syltheme", match = { namespace = "syltheme" }, no_anim = true })
```

```ini
layerrule = noanim, syltheme
```

niri needs no rule: Sylvaris asks for blur itself through `ext-background-effect`, shaped exactly like each panel. A `background-effect { blur true }` layer rule would blur the whole layer surface instead, so leave it out.

## Commands (SylIPC)

Everything Sylvaris does is one command away. Every part registers its actions with SylIPC, and the same actions work from the CLI, from compositor keybinds, and over a socket.

```sh
sylvaris                     # start SylCore, the shell
sylvaris center              # toggle SylCenter (also: open, close)
sylvaris view orbit-wifi     # open SylCenter on a view
sylvaris clock               # toggle SylClock (also: open, close)
sylvaris notify              # toggle the notification center (also: clear, dismiss <id>, invoke <id> [action])
sylvaris theme               # toggle SylTheme (also: open, close, next, prev, apply)
sylvaris theme set noir      # apply a theme without the picker (also: cycle, list)
sylvaris audio up 5          # volume (also: down, set 40, mute)
sylvaris media toggle        # play/pause (also: next, previous)
sylvaris dnd on              # nightlight, dnd, wifi, bluetooth: toggle, on, off
sylvaris get center.corner   # read a setting
sylvaris set center.corner top-left   # change a setting, refused if invalid
sylvaris state [topic]       # the whole state, or one topic such as audio, as JSON
sylvaris list                # every part and its actions
sylvaris watch [topic...]    # stream state changes as JSON lines
```

A part with no action runs its default (usually `toggle`). Errors print `error: ...` and exit with 1, so scripts can rely on the exit code.

`sylvaris watch` connects to `$XDG_RUNTIME_DIR/sylvaris/ipc.sock`. It prints every requested topic once, then a line each time one changes: `{"topic":"audio","data":{...}}`. Tools can talk to the socket directly: send one request per line, either plain words (`center toggle`) or a JSON array (`["center","view","orbit-wifi:My Network"]`), and read one JSON reply per line (`{"ok":true,"result":...}`). Sending `["watch","audio"]` turns the connection into a stream.

SylTheme opens on the focused monitor with the current theme in front. Arrow keys, the mouse wheel, dragging or clicking a side card move the carousel; once it rests for half a second the whole desktop previews that theme through your `themeHook`. It slides up over everything, including your bar, and hides the cursor until you move the mouse. Enter or **Apply theme** keeps it, Esc or a click on the backdrop brings back the theme you started with. SylCenter's Theme button and `sylvaris view theme` open it too.

Views: `compact`, `orbit-bluetooth`, `orbit-wifi`, `calendar`, `outputs`, `displays`, `hotspot`. Add `:<key>` to focus a device or network, for example `sylvaris view orbit-bluetooth:AA:BB:CC:DD:EE:FF`.

## SylClock

`sylvaris clock` opens SylClock. The sky card plots today from midnight to midnight: the sun and the moon sit at their real altitude for your location right now, their paths so far are solid and the rest of the day is dashed, and anything below the line is under the horizon. The sky colour follows the sun through night, twilight, golden hour and day, and stars come out as it gets dark. The moon is drawn in its current phase, mirrored in the southern hemisphere.

Your location comes from the `location` key in `config.json`. Without it, Sylvaris uses the coordinates of your system time zone from `zone1970.tab`, which is close enough for sunrise and sunset to be right to within minutes. Nothing is looked up online.

```nix
programs.sylvaris.settings.location = { latitude = 52.23; longitude = 21.01; };
```

## SylNotify

Sylvaris is your notification daemon, so stop swaync, mako or dunst before starting it (only one program can own notifications). Toasts pop up in the corner set by `notifications.corner` (top-right by default), newest on top. Hovering a toast pauses its timer, clicking it runs the app's default action, and action buttons go straight back to the app. Urgent notifications stay until you close them and still pop up during Do Not Disturb.

`sylvaris notify` opens the notification center: everything grouped by app, a Do Not Disturb switch and Clear buttons. Do Not Disturb is also the DND tile in SylCenter and `sylvaris dnd on|off|toggle`.

| Setting (`settings.json`) | Default | Meaning |
|---|---|---|
| `notifications.dnd` | `false` | Do Not Disturb |
| `notifications.timeout` | `5000` | How long a toast stays, in ms (1000–60000), unless the app asks otherwise |
| `notifications.corner` | `top-right` | `top-left`, `top-center` or `top-right` |

In `config.json`, `notifications.server = false` hands notifications back to another daemon (DND then drives swaync or mako), and `notifications.history` caps the center (100).

## Resin Glass

Every Sylvaris surface is drawn in Resin Glass: a translucent body the compositor blurs, the theme's accent suspended in it, a soft light that drifts like liquid and leans toward the pointer, a lit rim and a fine grain. Tune it with a `glass` block in `config.json` (or from Nix) and in `settings.json`; `settings.json` wins, and changes apply live.

| Key | Default | Range | What it does |
|---|---|---|---|
| `enabled` | `true` | | `false` brings back the solid look |
| `opacity` | `0.55` | 0–1 | panel body |
| `layerOpacity` | `0.35` | 0–1 | tiles, rows, nodes and cards on top of a panel |
| `tint` | `0.14` | 0–1 | accent suspended in the glass |
| `sheen` | `0.35` | 0–1 | the drifting light |
| `flow` | `1` | 0–3 | how fast the light drifts, `0` stops it |
| `rim` | `0.5` | 0–1 | brightness of the lit edge |
| `grain` | `0.035` | 0–0.2 | noise that keeps gradients smooth |

```nix
programs.sylvaris.settings.glass = {
  opacity = 0.5;
  sheen = 0.45;
  flow = 0.6;
};
```

Invalid values keep the previous layer's value and show a notice in SylCenter. Blur comes from your compositor (see the layer rules above); sway has no blur, so there the glass is translucency only.

## Configuration

`~/.config/sylvaris/config.json` is yours (or Nix's). Sylvaris never writes to it.

| Key | Default | Meaning |
|---|---|---|
| `themesDir` | `~/.config/sylvaris/themes` | Folder of theme bundles |
| `themeHook` | `""` | Command run with the theme id when a theme is applied. Empty means Sylvaris writes the id to `themeStateFile` itself. |
| `themeStateFile` | `~/.local/state/sylvaris/theme` | File holding the active theme id; Sylvaris watches it |
| `avatar` | `~/.face` | Image shown in the control center header |
| `lockCommand` | `loginctl lock-session` | Used by future parts |
| `terminal` | `kitty` | Used by future parts |
| `location` | time zone | `{ latitude, longitude }` for SylClock's sky |
| `toggles` | `[]` | Custom tiles: `{ id, label, icon?, on, off, status? }`. `status` is a command whose exit code 0 means "on". |

`~/.config/sylvaris/settings.json` belongs to Sylvaris. It stores what you change in the UI (panel corner, night light, saved display layouts, hotspot name) and is re-applied at every start. If it becomes invalid, Sylvaris keeps a copy as `settings.json.bak` and starts on defaults.

### Theme bundles

```json
{
  "id": "midnight",
  "name": "Midnight",
  "description": "Deep blue",
  "wallpaper": "~/Pictures/midnight.png",
  "colors": {
    "base": "#0f1117", "surface": "#1a1d27", "accent": "#7aa2f7", "accentHi": "#9ab8ff",
    "accentDeep": "#4c6ab3", "onAccent": "#0f1117", "text": "#e6e9f2", "textDim": "#8d94a8",
    "textSoft": "#c8cdda", "danger": "#e06c75"
  },
  "alpha": { "surface": 0.9, "glass": 0.62, "line": 0.16, "tint": 0.08 }
}
```

Missing or invalid colors fall back to the built-in theme, one value at a time.

## Development

```sh
nix develop
node --test tests/*.test.mjs
nix flake check
tests/headless/all.sh
tests/headless/run.sh tests/headless/out/compact tests/headless/compact.steps tests/fixtures/seed/warm
```

`tests/headless/run.sh` starts a headless sway with no visible output, runs Sylvaris inside it with `SYLVARIS_DEMO=1` (fixture devices instead of real ones), drives it over IPC and saves screenshots. It never touches your real devices or screens. It renders in software by default; set `HL_RENDERER=gles2 HL_QT_BACKEND=opengl` to render on the GPU, which texture-filled shapes such as album art and theme photos need. `docs/design/reference.html` is the visual source of truth.

## Credits

The constellation idea (devices orbiting a central core, a clicked device becoming the new center with its actions around it) is inspired by [ilyamiro/serpantinum](https://github.com/ilyamiro/serpantinum).

## License

MIT
