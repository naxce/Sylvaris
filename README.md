<p align="center">
  <img src="docs/assets/logo.svg" width="128" alt="Sylvaris logo">
</p>

<h1 align="center">Sylvaris</h1>

<p align="center">
  <b>A glass desktop shell for Hyprland, niri and sway.</b><br>
  One light process, twenty parts, and every one of them optional.
</p>

<p align="center">
  <a href="https://quickshell.org"><img src="https://img.shields.io/badge/Quickshell-0.3-c9702f?style=for-the-badge" alt="Quickshell"></a>
  <a href="https://hyprland.org"><img src="https://img.shields.io/badge/Hyprland-58e1ff?style=for-the-badge&logo=hyprland&logoColor=black" alt="Hyprland"></a>
  <img src="https://img.shields.io/badge/niri-e0955c?style=for-the-badge" alt="niri">
  <img src="https://img.shields.io/badge/sway-68751c?style=for-the-badge&logo=sway&logoColor=white" alt="sway">
  <a href="https://nixos.org"><img src="https://img.shields.io/badge/Nix_flake-5277c3?style=for-the-badge&logo=nixos&logoColor=white" alt="Nix flake"></a>
  <img src="https://img.shields.io/badge/license-MIT-a85c32?style=for-the-badge" alt="MIT">
</p>

<p align="center">
  <img src="docs/demo/center.gif" width="840" alt="SylCenter and SylClock">
</p>

## ✨ What's inside

<table>
  <tr>
    <td width="33%" valign="top">
      <h3>🧭 Everyday</h3>
      <b>SylBar</b> glass bar on any edge<br>
      <b>SylCenter</b> control center with orbits<br>
      <b>SylClock</b> live sky, weather, calendar<br>
      <b>SylNotify</b> notifications that stay out of the way<br>
      <b>SylDeck</b> dock that hides when windows open<br>
      <b>SylPad</b> launcher, grid or list
    </td>
    <td width="33%" valign="top">
      <h3>🛠️ Tools</h3>
      <b>SylSwitch</b> Alt+Tab with previews<br>
      <b>SylClip</b> clipboard history<br>
      <b>SylCapture</b> screenshots and recording<br>
      <b>SylMedia</b> player, equalizer, AirPods<br>
      <b>SylDiver</b> <a href="https://diver.fatum.cc">Diver</a> planner and alarms<br>
      <b>SylPower</b> power menu constellation
    </td>
    <td width="33%" valign="top">
      <h3>🎨 System</h3>
      <b>SylTheme</b> themes with live preview<br>
      <b>SylSync</b> apps follow your theme<br>
      <b>SylLock</b> · <b>SylGreet</b> lock and login<br>
      <b>SylPolkit</b> password prompts<br>
      <b>SylAccessibility</b> zoom and filters<br>
      <b>SylPlugins</b> your own widgets
    </td>
  </tr>
</table>

## 🎬 A closer look

<table>
  <tr>
    <td width="50%"><img src="docs/demo/theme.gif" alt="SylTheme"><br><sub><b>SylTheme</b> previews the whole desktop before you pick</sub></td>
    <td width="50%"><img src="docs/demo/settings.gif" alt="SylSettings"><br><sub><b>SylSettings</b> with a live preview for every look</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/demo/pad.gif" alt="SylPad and SylSwitch"><br><sub><b>SylPad</b> and <b>SylSwitch</b></sub></td>
    <td width="50%"><img src="docs/demo/tools.gif" alt="SylDiver, SylClip, SylCapture, SylPower"><br><sub><b>SylDiver</b>, <b>SylClip</b>, <b>SylCapture</b> and <b>SylPower</b></sub></td>
  </tr>
</table>

<p align="center"><img src="docs/demo/lock.gif" width="560" alt="SylLock"><br><sub><b>SylLock</b>, and SylGreet looks the same at login</sub></p>

## 📦 Install

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
            bar.position = "top";
            deck = { enabled = true; hide = "windows"; };
            keybinds = { "switcher next" = "ALT+Tab"; "clip toggle" = "SUPER+V"; };
            parts.media = false;
          };
        }
      ];
    };
  };
}
```

Every setting is a typed Home Manager option. For the lock screen's PAM service and the SylGreet login screen, also import `sylvaris.nixosModules.sylvaris`. Not on Nix? The [guide](docs/guide.md#install-without-nix) lists what to install.

## 🚀 Start

| Compositor | Add to its config |
|---|---|
| Hyprland (Lua) | `hl.exec_cmd("sylvaris")` in `hl.on("hyprland.start", …)` |
| Hyprland | `exec-once = sylvaris` |
| niri | `spawn-at-startup "sylvaris"` |
| sway | `exec sylvaris` |

Then open **SylSettings** from SylCenter's gear, or run `sylvaris settings`. Every switch is also a command:

```sh
sylvaris center           # control center
sylvaris switcher next    # Alt+Tab
sylvaris capture shot area
sylvaris lock
sylvaris set bar.position left
sylvaris list             # everything else
```

## 🪶 Light by design

Panels are built when you open them and freed shortly after they close, so Sylvaris holds little memory when idle. Everything you leave out with `parts` is never loaded, and its tools stay off your `PATH`.

## 📖 Learn more

The [guide](docs/guide.md) covers every part, command and setting, theme bundles, plugins and development.

## 💛 Credits

The constellation idea is inspired by [ilyamiro/serpantinum](https://github.com/ilyamiro/serpantinum). Weather by [Open-Meteo](https://open-meteo.com). AirPods support follows the protocol documented by LibrePods.

## 📄 License

MIT
