# Sylvaris

A modular desktop shell built on [Quickshell](https://quickshell.org), made for Hyprland and niri and also working on sway. Sylvaris runs as one resident process and hosts parts:

- **SylvarisCC**: the control center

More parts (SylvarisTP, SylvarisSettings) are on the way.

## Usage

```sh
sylvaris              # start the shell (put this in your compositor's autostart)
sylvaris cc           # toggle the control center
sylvaris state        # print the shell state as JSON
```

## Credits

The constellation idea (devices orbiting a central core, a clicked device becoming the new center with its actions around it) is inspired by [ilyamiro/serpantinum](https://github.com/ilyamiro/serpantinum).

## License

MIT
