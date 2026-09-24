# Sylvaris

A modular desktop shell built on [Quickshell](https://quickshell.org), made for **Hyprland** and **niri** and also working on **sway**. Sylvaris runs as one resident process, SylCore, that hosts parts:

- **SylCenter**: a control center that morphs from a compact panel into living orbits for Wi-Fi and Bluetooth
- **SylClock**: the time, a live sky with the real paths of the sun and moon, the moon's phase, sunrise and sunset, and a month calendar
- **SylNotify**: the notification daemon, with glass toasts and a notification center
- **SylPad**: a full-screen app launcher in the spirit of Launchpad and the GNOME app grid
- **SylCompositor**: one set of commands and one state model for Hyprland, niri and sway
- **SylBar**: a floating glass bar with workspaces, the focused window, the clock, media, tray and status
- **SylDeck**: an optional dock for pinned and running apps along the bottom of the screen
- **SylMedia**: what's playing, a system-wide equalizer with spatial audio for headphones, AirPods controls and every device's battery
- **SylTheme**: a full-screen theme picker with live previews and search
- **SylPower**: a power menu laid out as a constellation around you
- **SylPaper**: the wallpaper, drawn by Sylvaris, following the theme with smooth transitions
- **SylDiver**: your [Diver](https://diver.fatum.cc) plans on the desktop: calendar, reminders and alarms
- **SylSettings**: one screen for everything above, built around a constellation


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

1. Install `quickshell` (0.3.1 or newer), `wlr-randr`, `wlsunset`, NetworkManager (`nmcli`), `pactl`, `pipewire`, `python3`, `socat`, `wl-clipboard`, and the fonts **Inter** and **JetBrainsMono Nerd Font**.
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

Sylvaris asks for blur itself through `ext-background-effect`, shaped exactly like each panel with its rounded corners, and animates every panel on its own. Hyprland 0.56+ and niri support it, so the only rule you want turns off the compositor's own layer animation:

```lua
hl.layer_rule({ name = "sylvaris", match = { namespace = "^syl" }, no_anim = true })
```

```ini
layerrule = noanim, ^syl
```

Do not add `blur` or `ignore_alpha` layer rules: they blur by transparency instead of by shape, which leaves jagged edges around the rounded corners. On niri leave out `background-effect { blur true }` for the same reason. sway has no blur, so there the glass is translucency only.

## Commands (SylIPC)

Everything Sylvaris does is one command away. Every part registers its actions with SylIPC, and the same actions work from the CLI, from compositor keybinds, and over a socket.

```sh
sylvaris                     # start SylCore, the shell
sylvaris center              # toggle SylCenter (also: open, close)
sylvaris view orbit-wifi     # open SylCenter on a view
sylvaris clock               # toggle SylClock (also: open, close)
sylvaris notify              # toggle the notification center (also: clear, dismiss <id>, invoke <id> [action])
sylvaris pad                 # toggle SylPad, the app launcher (also: open, close)
sylvaris wm workspace 3      # the same compositor commands everywhere (see SylCompositor)
sylvaris settings            # open SylSettings (also: open <section>)
sylvaris config              # where the configuration lives
sylvaris reload              # reload the shell
sylvaris media open [tab]    # SylMedia on playing, sound or devices (media toggle/next/previous/seek control playback)
sylvaris eq preset rock      # equalizer (also: on, off, toggle, band <1-10> <dB>, spatial on|off)
sylvaris headphones noise anc   # AirPods listening mode: off, transparency, adaptive, anc (also: awareness on|off)
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

SylTheme opens on the focused monitor with the current theme in front. Arrow keys, the mouse wheel, dragging or clicking a side card move the carousel; once it rests for half a second the whole desktop previews that theme through your `themeHook`. It slides up over everything, including your bar, and hides the cursor until you move the mouse. Start typing to search themes by name or description (`sylvaris theme search <text>` does it from scripts). Enter or **Apply theme** keeps it, Esc or a click on the backdrop brings back the theme you started with. SylCenter's Theme button and `sylvaris view theme` open it too.

Views: `compact`, `orbit-bluetooth`, `orbit-wifi`, `calendar`, `outputs`, `displays`, `hotspot`. Add `:<key>` to focus a device or network, for example `sylvaris view orbit-bluetooth:AA:BB:CC:DD:EE:FF`.

## SylClock

`sylvaris clock` opens SylClock. The sky card plots today from midnight to midnight: the sun and the moon sit at their real altitude for your location right now, their paths so far are solid and the rest of the day is dashed, and anything below the line is under the horizon. The sky colour follows the sun through night, twilight, golden hour and day, and stars come out as it gets dark. The moon is drawn in its current phase, mirrored in the southern hemisphere.

Below the sky sits the weather from [Open-Meteo](https://open-meteo.com): now, the next hours as a temperature curve with the chance of rain, and six days ahead. It refreshes every `weather.refresh` minutes (30), in `weather.units` (`metric` or `imperial`); `weather.enabled = false` turns it off. This is the only part that talks to the internet, and it only sends your coordinates. Click a day in the calendar to see and add your Diver plans for it.

Your location comes from the `location` key in `config.json`. Without it, Sylvaris uses the coordinates of your system time zone from `zone1970.tab`, which is close enough for sunrise and sunset to be right to within minutes. Nothing but the weather is looked up online.

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

## SylPad

`sylvaris pad` fills the screen with your apps over a blurred copy of the wallpaper, alphabetically, a page at a time. Start typing to search names, descriptions and keywords; arrows move the selection, Enter launches, PageUp/PageDown or the mouse wheel turn pages, Esc clears the search and then closes. Terminal apps open in `terminal` from `config.json`. `pad.columns` (7) and `pad.rows` (5) in `settings.json` set the grid. The apps ripple in from the middle when it opens and settle again while you type.

`pad.mode = "list"` turns SylPad into a compact launcher in the middle of the screen, like rofi: a search field and a list you drive with the arrow keys.

## SylCompositor

`sylvaris wm` speaks one language to Hyprland (Lua or classic config), niri and sway, so keybinds, scripts and the rest of Sylvaris never care which one is running.

| Command | What it does |
|---|---|
| `wm workspace <n\|next\|prev>` | go to a workspace |
| `wm move-to <n\|next\|prev>` | send the focused window to a workspace |
| `wm focus <left\|right\|up\|down>` | move focus |
| `wm move <left\|right\|up\|down>` | move the focused window |
| `wm close`, `wm fullscreen`, `wm float` | act on the focused window |
| `wm exec <command>` | run a command |
| `wm reload`, `wm quit` | reload the compositor's config, or leave the session |
| `wm` or `sylvaris state compositor` | workspaces, windows and the focused window as JSON |

The state is the same shape everywhere: each workspace has `index`, `name`, `output`, `active`, `focused`, `urgent` and a window count, read live from Hyprland's and sway's IPC and from niri's event stream. Windows come from the Wayland foreign-toplevel protocol, which all three support.

## SylBar

The bar runs on every screen and reserves its space. It can sit on any edge (`bar.position`: `top`, `bottom`, `left` or `right`; the side ones are vertical) and comes as separate glass islands for each side or as one slab (`bar.style`: `islands` or `slab`). Tray apps live in a drawer behind an arrow that points where it opens, so the bar stays calm. Everything opens where you clicked: the clock opens SylClock, the options button (󰘮) opens SylCenter, the bell opens SylNotify (middle-click toggles Do Not Disturb), the apps button opens SylPad, and the Wi-Fi, Bluetooth and volume items open their SylCenter views. Scroll over the workspaces to switch, over the volume to change it, over the media title to skip tracks. Right-click tray icons for their menus.

Choose the modules and their order in `settings.json`; each module appears once:

```json
"bar": {
  "floating": true,
  "left": ["pad", "workspaces", "window"],
  "center": ["clock"],
  "right": ["media", "tray", "audio", "network", "bluetooth", "battery", "notifications", "center"]
}
```

Modules: `pad`, `workspaces`, `window`, `clock`, `media`, `tray`, `audio`, `network`, `bluetooth`, `battery`, `notifications`, `center`, `power` (SylPower) and `diver` (what's next in Diver, with a countdown). On a computer without a battery the battery module hides itself and the rest close the gap. `floating: false` makes the bar span the edge; `enabled: false` turns it off.

## SylDeck

Turn the deck on with `sylvaris set deck.enabled true` (or `"deck": { "enabled": true }` in `settings.json`). Pinned apps come first, then running apps after a divider, with a dot per open window. Click an app to open it or cycle its windows, middle-click for a new window, right-click for its windows, Keep in Deck and Close. Right-click an app in SylPad to pin it too.

| Key (`deck.`) | Default | Meaning |
|---|---|---|
| `enabled` | `false` | show the deck |
| `pinned` | `[]` | desktop file ids, e.g. `["firefox", "kitty"]` |
| `pad` | `start` | where the SylPad button goes: `start`, `end` or `none` |
| `power` | `none` | where the SylPower button goes: `start`, `end` or `none` |
| `effect` | `bloom` | `bloom` lifts the icon under the pointer with a glow, `magnify` grows it and its neighbours, `none` |
| `autohide` | `false` | slide away until the pointer touches the bottom edge |
| `reserve` | `true` | keep windows clear of the deck; `false` lets them go underneath |
| `size` | `56` | icon size, 36–96 |

## SylMedia

Right-click the media item in SylBar, click the media card in SylCenter, or run `sylvaris media open`.

**Playing** shows the artwork, a seek bar, previous/play/next, shuffle and repeat when the player supports them, the player's own volume and a switch between players. Everything comes from MPRIS, so it works with Spotify, browsers, mpv and the rest.

**Sound** is a 10-band equalizer (31 Hz to 16 kHz, ±12 dB) with presets, for everything you hear. Sylvaris runs it as a small PipeWire filter, makes it the default output and sends it on to the device you picked; choosing another output in SylCenter moves the equalizer with it, and turning it off brings your normal output back. Changes apply a moment after you let go of a slider. **Spatial audio** is headphone crossfeed: a little of each channel, low-passed and delayed by a fraction of a millisecond, reaches the other ear so music sounds like speakers in front of you rather than inside your head. (Apple's own Spatial Audio with head tracking is rendered by Apple devices, not by the AirPods, so no Linux shell can switch it on; this is the local equivalent.)

**Devices** controls AirPods and Beats while they are connected: battery for each bud and the case, listening mode (off, transparency, adaptive, noise cancellation) and conversation awareness. Sylvaris talks to them directly over Apple's accessory protocol, as documented by the LibrePods project, and finds them by name; set `media.airpods` in `settings.json` to an address to pick a device yourself. Below that is the battery of every device that reports one (mice, keyboards, controllers, headsets, the laptop battery).

## SylPower

`sylvaris power`, the `power` bar module or the deck's power button opens SylPower: your avatar and uptime in the middle and the actions orbiting around it. Arrows or the mouse choose, Enter confirms, and each action has a letter (L lock, S suspend, H hibernate, O log out, R restart, F firmware, P shut down). Anything that closes your session counts down first; press again to do it now, Esc to stay.

| Key (`power.`) | Default | Meaning |
|---|---|---|
| `actions` | `["lock", "suspend", "logout", "reboot", "shutdown"]` | which actions show, from `lock`, `suspend`, `hibernate`, `logout`, `reboot`, `firmware`, `shutdown` |
| `confirm` | `true` | count down before log out, restart, shut down and hibernate |
| `countdown` | `3` | seconds |
| `commands` | `{}` | replace a command, e.g. `{ "lock": "hyprlock" }` |

## SylPaper

Sylvaris draws the wallpaper itself on every screen and changes it with the theme, with a zoom, fade or slide (`paper.transition`, `paper.duration`). `sylvaris paper` opens a picker for the images in `paper.folder` (`~/Pictures/wallpapers`): pick one for the current theme or only for this screen, and add blur, dim or an accent tint. `sylvaris paper next|prev|set <path>|reset` do the same from scripts. Stop hyprpaper, swaybg or swww first, or set `paper.enabled = false` to keep them.

## SylDiver

SylDiver brings [Diver](https://diver.fatum.cc) to the desktop. In Diver open settings → connected devices → connect sylvaris, enter your password and run the line it gives you (`sylvaris diver pair <code>`) or paste it into SylSettings → Diver. Your list stays end-to-end encrypted: Sylvaris gets a key for the list and a token you can revoke, never your password.

Then days with plans get dots in SylClock's and SylCenter's calendars, clicking a day shows its plan with a field to add to it ("call Ana 18:00" works), reminders become notifications, and tasks marked as alarms take over the screen with a sound until you snooze (5, 10 or 30 minutes), finish or dismiss them. The `diver` bar module counts down to what's next.

`sylvaris diver add <text>` captures a task into the inbox (dates like "tomorrow 9:00" or "in 20 min" are understood), `diver done <id>`, `diver snooze <id> <minutes>`, `diver today`, `diver next`, `diver sync` and `diver test` (rings a test alarm). `diver.notify`, `diver.alarms`, `diver.sound`, `diver.calendar` and `diver.refresh` (minutes between syncs) are in SylSettings.

## Motion and performance

Every panel opens, moves and closes with one set of curves. `motion.scale` stretches or shortens all of it (1 is the default, 0.5 twice as fast), `motion.reduced = true` makes panels appear without moving. `performance = true`, or the Performance toggle in SylCenter, drops the blurred backdrops, grain, sheen and ambient movement and shortens every animation.

## SylSettings

The gear in SylCenter, `sylvaris settings` or `sylvaris settings open <section>` opens SylSettings over a starfield: every section is a star around the core, and picking one shrinks the constellation to the top and opens the section below it. On the left you tune the constellation itself (drift speed, ring, silk links, labels, starfield), which also changes SylCenter's orbits; on the right are statistics (uptime, the shell's memory, apps, themes, windows, workspaces, screens, notifications) and About. Every switch is also a `sylvaris set` away, and values that come from `config.json` are shown with where to change them.

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

Everything lives in one folder, `~/.config/sylvaris/` (`sylvaris config` prints it):

- `config.json` is yours, or Nix's through `programs.sylvaris.settings`. Sylvaris never writes to it.
- `settings.json` belongs to Sylvaris: it holds only what you change in SylSettings, SylCenter or with `sylvaris set`.
- `themes/` holds theme bundles.

Every key of `settings.json` can also be written in `config.json`, where it becomes the default: declare your bar, deck, equalizer or panel positions in Nix, and anything you change in the UI is saved as an override in `settings.json` and wins. Remove a key from `settings.json` to fall back to your declared value. Both files are watched, so changes apply live.

```nix
programs.sylvaris.settings = {
  bar.right = [ "tray" "audio" "network" "notifications" "center" ];
  deck = { enabled = true; pinned = [ "firefox" "kitty" ]; };
  notifications.corner = "top-right";
  media.eq = { enabled = true; preset = "bass"; };
};
```

| Key (`config.json` only) | Default | Meaning |
|---|---|---|
| `themesDir` | `~/.config/sylvaris/themes` | Folder of theme bundles |
| `themeHook` | `""` | Command run with the theme id when a theme is applied. Empty means Sylvaris writes the id to `themeStateFile` itself. |
| `themeStateFile` | `~/.local/state/sylvaris/theme` | File holding the active theme id; Sylvaris watches it |
| `avatar` | `~/.face` | Image shown in the control center header |
| `lockCommand` | `loginctl lock-session` | Used by future parts |
| `terminal` | `kitty` | Terminal for terminal apps launched from SylPad and SylDeck |
| `location` | time zone | `{ latitude, longitude }` for SylClock's sky |
| `notifications` | `{ server = true; history = 100; }` | Whether Sylvaris is the notification daemon, and how many notifications the center keeps |
| `toggles` | `[]` | Custom tiles: `{ id, label, icon?, on, off, status? }`. `status` is a command whose exit code 0 means "on". |

The settings keys are `center`, `clock`, `notifications`, `nightLight`, `displays`, `hotspot`, `glass`, `pad`, `bar`, `deck` and `media`; each part's section above lists its own. If `settings.json` becomes invalid, Sylvaris keeps a copy as `settings.json.bak` and starts on your declared defaults.

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
