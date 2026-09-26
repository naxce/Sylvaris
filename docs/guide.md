# Sylvaris guide

Everything the [README](../README.md) leaves out: installing by hand, every part, every command and every setting.

## Install without Nix

1. Install `quickshell` (0.3.1 or newer), `socat`, the fonts **Inter** and **JetBrainsMono Nerd Font**, and the tools below for the parts you keep.
2. Copy `shell/` to `~/.config/quickshell/sylvaris`.
3. Put `bin/sylvaris` on your `PATH`.

| Tool | Needed by |
|---|---|
| `pipewire` (`pw-cli`, `pw-metadata`, `pw-play`) | bar, center, clock, diver, media, settings |
| `python3` with `cryptography` | bar, center, clock, diver, media, settings, sync |
| `notify-send` (libnotify) | bar, capture, center, clock, diver, settings |
| `pactl` | bar, capture, center, media |
| `wlsunset` | center, settings |
| `curl` | clock, settings |
| NetworkManager (`nmcli`) | center |
| `wlr-randr` | center |
| `wl-clipboard` | center, clip, capture |
| `grim`, `slurp`, `wf-recorder` | capture |
| `gdbus` (glib) | lock, only for “lock when the system asks” |
| `git` | plugins, only to install from Git |

`python3`, `notify-send` and `pw-play` serve Diver, which the bar, center, clock and settings show too; `python3` also talks to AirPods in media. Wi-Fi in the bar and center reads NetworkManager over D-Bus, so keep the daemon running for those. `socat` makes the `sylvaris` command fast; without it commands fall back to `qs ipc`, but `sylvaris watch` needs it.

Every part can be excluded, which keeps it from loading along with anything only it uses:

```sh
sylvaris set parts.center false   # exclude SylCenter
sylvaris set parts.center true    # bring it back, no reinstall or reload
```

The parts are `access`, `bar`, `capture`, `center`, `clip`, `clock`, `deck`, `diver`, `lock`, `media`, `notify`, `pad`, `paper`, `plugins`, `polkit`, `power`, `settings`, `switcher`, `sync` and `theme`; SylSettings lists them under General. A tool can be left uninstalled once every part in its row is excluded. This is separate from `bar.left`, `bar.center` and `bar.right`, which only choose what the bar shows. With Nix, `programs.sylvaris.parts = { center = false; };` writes the same key into `config.json` and leaves those tools off the package's `PATH`.

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

SylTheme opens on the focused monitor with the current theme in front. Arrow keys, the mouse wheel, dragging or clicking a side card move the carousel; once it rests for half a second the whole desktop previews that theme, including its `links`. It slides up over everything, including your bar, and hides the cursor until you move the mouse. Start typing to search themes by name or description (`sylvaris theme search <text>` does it from scripts). Enter or **Apply theme** keeps it, Esc or a click on the backdrop brings back the theme you started with. SylCenter's Theme button and `sylvaris view theme` open it too.

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

Modules: `pad`, `workspaces`, `window`, `clock`, `media`, `tray`, `audio`, `network`, `bluetooth`, `battery`, `notifications`, `center`, `power` (SylPower), `diver` (what's next in Diver, with a countdown) and `plugin:<id>` for a bar plugin.

Workspaces show as numbers, dots or a glyph set (`bar.workspaceIcons`: `numbers`, `dots`, `paw`, `bone`, `heart`, `star`, `leaf`, `flower`, `fire`, `diamond`, `tree`, `ghost`, `moon`, `cat`, `fish`, `music`). The default, `auto`, uses the theme's `workspaceIcon` and numbers when it has none. Panels such as SylCenter and SylClock open next to the bar wherever it sits, so a bar on the left opens them along the left edge. On a computer without a battery the battery module hides itself and the rest close the gap. `floating: false` makes the bar span the edge; `enabled: false` turns it off.

## SylDeck

Turn the deck on with `sylvaris set deck.enabled true` (or `"deck": { "enabled": true }` in `settings.json`). Pinned apps come first, then running apps after a divider, with a dot per open window. Click an app to open it or cycle its windows, middle-click for a new window, right-click for its windows, Keep in Deck and Close. Right-click an app in SylPad to pin it too.

| Key (`deck.`) | Default | Meaning |
|---|---|---|
| `enabled` | `false` | show the deck |
| `pinned` | `[]` | desktop file ids, e.g. `["firefox", "kitty"]` |
| `pad` | `start` | where the SylPad button goes: `start`, `end` or `none` |
| `power` | `none` | where the SylPower button goes: `start`, `end` or `none` |
| `effect` | `bloom` | `bloom` lifts the icon under the pointer with a glow, `magnify` grows it and its neighbours, `none` |
| `hide` | `never` | `always` slides away until the pointer touches the bottom edge; `windows` shows the deck on an empty desktop and hides it while windows are open on that screen |
| `peek` | `true` | a thin line in the accent colour stays while the deck is hidden |
| `peekSize` | `4` | thickness of that line, 2–12 px |
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

`sylvaris diver` opens the planner: Today (overdue, today, the next 7 days), Calendar (month with busy days and a day agenda) and Lists (categories › sections › lists, each addable, renamable and removable). Clicking a task opens its sheet with everything Diver stores: title, notes, date, start and end, repeats (presets or every N days, weeks, months or years on chosen weekdays, ending never, on a date or after N times), reminders, alarm, list, priority, energy, estimate and steps. Unsaved changes are never dropped: Esc or Cancel asks first. Ctrl+Enter saves, Ctrl+1/2/3 switch views, Ctrl+N starts a new task. The target button on a task starts a focus session with a countdown and a notification at the end.

SylClock and SylCenter hand off to it: in a day's plan, clicking a task opens its sheet, the pencil beside "Add to this day" opens a new one for that day with what you typed, and **Diver ›** opens the calendar on that day. `sylvaris clock day <yyyy-mm-dd|today>` opens SylClock on a day.

From scripts: `diver view <today|calendar|lists>`, `diver day <yyyy-mm-dd|today>`, `diver new [text]`, `diver edit <id>`, `diver set <id> <field> <value>` (fields: title, notes, due, time, end, repeat, until, remind, alarm, priority, energy, estimate, done), `diver move <id> <list>`, `diver delete <id>`, `diver lists`, `diver list add|rename|remove <path> [name]` (paths are positions such as `0`, `0-1`, `0-1-2`, so check `diver lists` first; `-` adds a category), `diver focus <id> [minutes]` and `diver unfocus`.

`sylvaris diver add <text>` captures a task into the inbox (dates like "tomorrow 9:00" or "in 20 min" are understood), `diver done <id>`, `diver snooze <id> <minutes>`, `diver today`, `diver next`, `diver sync` and `diver test` (rings a test alarm). `diver.notify`, `diver.alarms`, `diver.sound`, `diver.calendar` and `diver.refresh` (minutes between syncs) are in SylSettings.

## SylSwitch

Alt+Tab for every compositor. Bind `sylvaris switcher next` to Alt+Tab and `sylvaris switcher prev` to Alt+Shift+Tab: the first press opens a row of your windows, most recent first, with live previews on Hyprland and app icons elsewhere. Keep Alt held and tap Tab to move; let go of Alt to jump to the window. Arrows, Enter, a click or Esc work too. `switcher.previews` and `switcher.titles` turn the previews and titles off.

## SylLock

`sylvaris lock` locks the screen with the session-lock protocol, so nothing can draw over it and the compositor keeps it locked even if Sylvaris stops. It looks like the rest of Sylvaris: your wallpaper, a large clock and a password field that shakes on a wrong password. Passwords are checked by PAM with the first of the `sylvaris`, `hyprlock`, `swaylock` or `login` services that exists (`lock.pam` picks one). The NixOS module adds the `sylvaris` service. Point `lockCommand` at `sylvaris lock` to use it from SylPower, and turn on `lock.logind` to lock whenever something runs `loginctl lock-session`, such as hypridle.

## SylGreet

A login screen for greetd in the same style: pick a user with ↑ ↓ and a session with F2, type the password, and it starts your session and remembers both for next time. Turn it on in NixOS:

```nix
imports = [ sylvaris.nixosModules.sylvaris ];
programs.sylvaris.greeter = {
  enable = true;
  user = "you";
  session = "hyprland";
  settings.glass.opacity = 0.6;
};
```

It runs in cage with its own theme and config under `/etc/sylvaris-greet`, and reboot and shutdown are one click away.

## SylPolkit

When an app asks for extra rights, SylPolkit shows a Sylvaris password prompt with what is being asked and why. Only one polkit agent can run, so stop hyprpolkitagent or polkit-gnome for it to take over. `sylvaris polkit preview` shows a sample request (the password `right` completes it).

## SylClip

A clipboard history: `sylvaris clip toggle` opens it with a search field. Arrows and Enter paste an item back into the clipboard, Delete removes one, and the pin keeps an item at the top for good. Text and images are kept; anything a password manager marks as secret never is. `clip.limit` (50), `clip.images` and `clip.persist` (keep it across restarts) are in SylSettings.

## SylCapture

`sylvaris capture toggle` opens a small panel for screenshots and recordings. Shots can be an area, a window (click it) or the whole screen, with an optional delay; they are copied and saved to `~/Pictures/Screenshots`. Recordings of an area or a screen, optionally with desktop sound, go to `~/Videos/Recordings`, and a red pill with the time lets you stop them. For keys: `capture shot area|window|screen`, `capture record area|screen`, `capture stop`.

## SylAccessibility

`sylvaris access toggle` opens zoom (up to 5×, `access zoom in|out` for keys), colour filters (grayscale, invert, and corrections for red-, green- and blue-weak colour vision), the text size of every Sylvaris panel, the pointer size, reduce motion and reduce transparency. Zoom and filters use Hyprland; the rest works everywhere. If Orca or wvkbd are installed, the screen reader and the on-screen keyboard are one click away.

## Key bindings

SylSettings › Features › Key bindings lists every action worth a key. Click one and press the keys: Sylvaris adds the binding to Hyprland or sway right away and again after the compositor reloads its config. The same map lives in `keybinds`:

```nix
programs.sylvaris.keybinds = {
  "switcher next" = "ALT+Tab";
  "clip toggle" = "SUPER+V";
  "capture shot area" = "SUPER+SHIFT+S";
  "lock now" = "SUPER+L";
};
```

niri cannot take bindings at runtime, so there the page shows lines to copy into its config.

## SylPlugins

Plugins live in `~/.config/sylvaris/plugins/<id>/`: a `plugin.json` and a QML file.

```json
{ "id": "uptime", "name": "Uptime", "version": "1.0.0", "kind": "bar", "entry": "Plugin.qml", "description": "How long this computer has been on" }
```

`kind` is `bar` (a widget; add `plugin:<id>` to a bar group), `panel` (opens with `sylvaris plugins open <id>`) or `service` (runs in the background). Plugin QML can `import qs`, `qs.services` and `qs.components` to use the theme and the glass, and gets an `api` object with its own settings (`api.config`, `api.set(key, value)`) and `api.run(["center", "open"])`. `sylvaris plugins new <id> [kind]` makes a working starter, `plugins install <https git address>` clones one, and every plugin stays off until you turn it on in SylSettings › Plugins. Plugins run with the same rights as Sylvaris, so install only ones you trust. [`examples/plugins/uptime`](../examples/plugins/uptime) is a complete bar plugin.

## SylSync

Turn on SylSettings › Features › App colours and your theme's colours flow into other apps every time you switch themes: GTK 3 and 4 (and Chromium, Brave or Vivaldi set to use the GTK theme), Qt through qt5ct and qt6ct, kitty (open terminals update at once), foot, VS Code, VSCodium and Cursor, Zed, Neovim and Vim, and optionally Firefox, LibreWolf, Zen and Mullvad Browser through `userChrome.css`. Sylvaris writes its own theme files and at most one include line; VS Code and its forks get `workbench.colorCustomizations` in their `settings.json` instead, which they apply at once, and Firefox picks up the new colours on its next start. Each app is a switch, and apps that are not installed are skipped.

## Home Manager

Every setting has its own option, generated from the shell's defaults, so you can write `programs.sylvaris.bar.position = "left";` or `programs.sylvaris.deck.hide = "windows";` and get type checking. `programs.sylvaris.settings` still takes any JSON, and `programs.sylvaris.parts` leaves out parts and their tools.

## Motion and performance

Every panel opens, moves and closes with one set of curves. Full-screen backgrounds (SylSettings, SylPad, SylPower) spread in from the edges or out from the center, or simply fade (`motion.reveal`: `edges`, `center`, `fade`). `motion.scale` stretches or shortens all of it (1 is the default, 0.5 twice as fast), `motion.reduced = true` makes panels appear without moving. `performance = true`, or the Performance tile in SylCenter, drops the blurred backdrops, grain, sheen and ambient movement and shortens every animation. On Hyprland and sway it also turns off the compositor's animations, blur, shadows and gaps, and turning it off reloads the compositor config to bring them back; nothing else needs to be installed. A custom toggle with the id `performance` replaces the built-in tile.

## SylSettings

The gear in SylCenter, `sylvaris settings` or `sylvaris settings open <section>` opens SylSettings over a starfield. Tabs above it split the sections into Settings (general, appearance, motion, wallpaper, sound, displays), Apps (every Sylvaris panel) and Features (lock, authentication, accessibility, key bindings, app colours, plugins, commands); Tab and Shift+Tab switch between them. Every section is a star around the core, and picking one shrinks the constellation to the top and opens the section below it. On the left you tune the constellation itself (drift speed, ring, silk links, labels, starfield), which also changes SylCenter's orbits; on the right are statistics (uptime, the shell's memory, apps, themes, windows, workspaces, screens, notifications) and About. Every switch is also a `sylvaris set` away, and values that come from `config.json` are shown with where to change them.

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
| `themeHook` | `""` | Optional command run with the theme id when a theme is applied. Empty means Sylvaris writes the id to `themeStateFile` itself; theme `links` apply either way. |
| `themeStateFile` | `~/.local/state/sylvaris/theme` | File holding the active theme id; Sylvaris watches it |
| `avatar` | `~/.face` | Image shown in the control center header |
| `lockCommand` | `loginctl lock-session` | What SylPower's Lock runs; set it to `sylvaris lock` to use SylLock |
| `terminal` | `kitty` | Terminal for terminal apps launched from SylPad and SylDeck |
| `location` | time zone | `{ latitude, longitude }` for SylClock's sky |
| `notifications` | `{ server = true; history = 100; }` | Whether Sylvaris is the notification daemon, and how many notifications the center keeps |
| `toggles` | `[]` | Custom tiles: `{ id, label, icon?, on, off, status? }`. `status` is a command whose exit code 0 means "on". |

The settings keys are listed in [`nix/schema.json`](../nix/schema.json) with their defaults, and each part's section above describes its own. If `settings.json` becomes invalid, Sylvaris keeps a copy as `settings.json.bak` and starts on your declared defaults.

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
  "alpha": { "surface": 0.9, "glass": 0.62, "line": 0.16, "tint": 0.08 },
  "links": {
    "kitty/theme.conf": "~/dotfiles/kitty/midnight.conf",
    "hypr/looknfeel.lua": "~/dotfiles/hypr/looknfeel-midnight.lua"
  }
}
```

Missing or invalid colors fall back to the built-in theme, one value at a time.

`links` themes the rest of your desktop without a hook. Each key is a path under `~/.config`, each value the file it should point to for this theme. When the theme is applied, Sylvaris symlinks every entry that changed, then reloads the compositor and signals kitty and waybar. Sources that do not exist are skipped and reported in `sylvaris state theme`.

## Development

```sh
bin/install-hooks
nix develop
node --test tests/*.test.mjs
nix flake check
tests/headless/all.sh
tests/headless/run.sh tests/headless/out/compact tests/headless/compact.steps tests/fixtures/seed/warm
```

`tests/headless/run.sh` starts a headless sway with no visible output, runs Sylvaris inside it with `SYLVARIS_DEMO=1` (fixture devices instead of real ones), drives it over IPC and saves screenshots. It never touches your real devices or screens. It renders in software by default; set `HL_RENDERER=gles2 HL_QT_BACKEND=rhi` to render with OpenGL, which texture-filled shapes such as album art and theme photos need. `docs/design/reference.html` is the visual source of truth.

`bin/install-hooks` copies the git hooks from `bin/hooks` into `.git/hooks`. Run it once after cloning and again whenever they change. They reject comments in staged code, commits whose author or committer is not the repository owner, and trailers, emoji or "Generated with" lines in commit messages.
