# Celestial Being

A Gundam 00 themed desktop for Arch Linux: Hyprland 0.57 (Lua config) with a Quickshell bar,
island, control center, dock and lock screen, plus matching terminal, prompt and app colors.

Pilot callsigns, GN green, Trans-Am red, caution tape and a desktop for each Gundam. No rainbow.

## Contents

| Path | Installs to |
| --- | --- |
| `hypr/` | `~/.config/hypr/` |
| `quickshell/` | `~/.config/quickshell/` |
| `fish/` | `~/.config/fish/` (includes `conf.d/hud.fish`, the Ghostty-only boot and prompt HUD, and `hud/reveal.py`, its one-second rain and decode boot animation; `NOANIM=1` turns it off) |
| `zsh/.zshrc` | `~/.zshrc` (same aliases as fish, `upgrade`, and the cockpit HUD in Ghostty and kitty) |
| `fastfetch/` | `~/.config/fastfetch/` |
| `kitty/` | `~/.config/kitty/` |
| `ghostty/` | `~/.config/ghostty/` (`thruster.glsl` and `gn-particles.glsl` are off: an animated shader measured about +15% of a core while Ghostty is focused) |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `starship/{full,mid,min}.toml` | `~/.config/starship/`, picked by `hud.fish` from the pane width |
| `waybar/` | `~/.config/waybar/` (fallback bar, not started by default) |
| `kde/kdeglobals` | `~/.config/kdeglobals` |
| `kde/DapGN.colors` | `~/.local/share/color-schemes/DapGN.colors` |
| `qt6ct/` | `~/.config/qt6ct/` |

## Install

On a fresh Arch Linux with a user that can run `sudo`:

```sh
git clone https://github.com/parikesitad-pm/celestial-being.git
cd celestial-being
./install.sh --dry-run   # prints every step, changes nothing
./install.sh
```

The installer:

1. Installs the packages from the Arch repositories, then `yay` (if missing) and the AUR icon and cursor themes.
2. Moves any existing config it replaces to `~/.config-backup/arch-ark-<time>/`, then copies each path in the table above.
3. Fills in the absolute path in `qt6ct.conf` and makes the Hyprland scripts executable.
4. Enables NetworkManager, Bluetooth and power-profiles-daemon.

It does not apply hardware tuning (zram, GPU drivers, NVIDIA). `--skip-packages` copies configs only.

It asks for a **pilot name** (default: your user name) and an optional site or tagline, and puts them where the author's `dap_`, `DAP-01` and `d-ap.my.id` show on screen: bar, island header, terminal HUD, fastfetch, waybar and lock screens. Pass `--pilot NAME --site TEXT` to skip the questions.

Try it without touching your own setup (no sudo, no packages, everything lands in a throwaway home):

```sh
HOME="$(mktemp -d)" ./install.sh --skip-system --pilot tester
```
After it finishes: add the images listed under "Files not included", set your monitors in the `hl.monitor(...)` lines of `hyprland.lua`, run `chsh -s /usr/bin/fish`, and log in to Hyprland.

## Terminal HUD (fish and zsh, Ghostty and kitty)

Each command decodes out of noise before it runs. `sudo`/`doas`/`run0` get a caution stripe and `WARNING // ELEVATED ACCESS`; `git push` gets `GN DRIVE // EXIA LAUNCH`. After it runs: failures glitch red (`FAULT rc=N`), runs over 2 s print `CLEAR`, and runs over 30 s print `TRANS-AM COMPLETE` and send a notification to the island. TUIs (nvim, btop, ssh, …) are skipped; `NOANIM=1` keeps plain lines.

## Island, control center and notifications

- **Island** (`Island.qml`): the center of the bar. Collapsed it shows the date, time, CPU, RAM and GPU; click it to open tabs for Music, Calendar, Focus, Todo and Notif. Every tab change replays the header decode.
- **Control center** (`ControlCenter.qml`): the right end of the bar. The status pill opens into the panel with a sonar ping and a glitch header.
- **Gundam states:** Trans-Am (performance profile) turns the accent red and the window borders and open island red, green and yellow; Standby and Cruise use the current desktop's color. The closed island is a still GN green ring. NT-D (Do Not Disturb) turns the island ring solid red. The Wi-Fi and Bluetooth pages sweep a Zaku mono-eye while they load. On battery, the shell raises a critical "GN particles low" alarm at 15% and 5%.
- **GN Sense** (optional, [gn-sense](https://github.com/parikesitad-pm/gn-sense)): power profile and keyboard RGB panel for Acer Nitro and Predator laptops. `hyprland.lua` starts it and binds the keyboard's N key (keycode 433); the control center tile opens it. Without gn-sense installed, both do nothing.
- **Notifications:** the shell is the notification server (`NotificationServer` in `Ui.qml`); swaync is not started. `Super+N` opens the Notif tab. Action buttons (for example Answer and Decline) are passed back to the sending app.
- **Calendar and alarms** (`Agenda.qml`, `Ics.js`): alarms are saved in `~/.local/state/dap-shell-alarms.json`. To show Google Calendar events, paste the calendar's "Secret address in iCal format" into `~/.config/dap-shell/gcal-ics-url` (mode 600). That address gives read access to the calendar, so keep it out of the repo.

## Displays and desktops

Four desktops always exist: Exia, Dynames, Kyrios and Virtue. **New desktop** in the Overview adds Freedom, Zaku, Unicorn, 00 Raiser, RX-78-2, Strike, Wing and Barbatos, in that order; an empty added desktop shows a close button on hover. Added desktops are gone after a restart. Each desktop has its own color on the window border, the bar and the Overview. Control Center > Arrange displays places the external monitor left or right of the laptop. The side is saved to `~/.local/state/dap-display-side`. Set your own monitors in the `hl.monitor(...)` lines of `hyprland.lua`.

## Dock, app menu and Quick Look

- **Dock:** hidden until the pointer reaches the bottom screen edge. `Dock.qml` maps its window only while open; a 2 px strip window is the trigger, so windows keep the full height.
- **App menu:** `Launcher.qml`, a searchable grid. It opens from the dock's Apps button, the bar, or `Super+Space`.
- **Quick Look:** `Alt+Space` in Dolphin runs `hypr/scripts/preview.sh`. Images and text open in `Preview.qml`; other file types open in their default app. Other apps still receive the key.

Dolphin has no D-Bus call for the selection, so `preview.sh` triggers its Copy Location action, then restores the clipboard and removes the path from the cliphist history. Only one clipboard format is restored, so formatted text can paste as plain text.

## Dolphin theme

Dolphin needs all three of these to render dark with readable file names:

- `qt6ct/` sets the palette used for file names. `QT_QPA_PLATFORMTHEME=qt6ct` is set in `hyprland.lua`.
- `kde/kdeglobals` holds the color groups and `[UiSettings] ColorScheme=DapGN`.
- `kde/DapGN.colors` is the scheme that key points to.

These settings also change Ark and any other app that follows `qt6ct` or KDE color schemes. VLC does not follow them.

## Files not included

Images are left out for copyright and privacy. Add your own or the matching image will be blank:

- `~/Pictures/wallpapers/gundam-dark.jpg` (wallpaper, path in `hypr/hyprpaper.conf`)
- `~/.config/quickshell/dap-lock/assets/avatar.jpg`
- `~/.config/quickshell/dap-lock/assets/gundam-lock.png`
- `~/.local/share/dap-shell/cb-32.png`, `cb-64.png`, `cb-128.png`

## Related

- [gn-sense](https://github.com/parikesitad-pm/gn-sense): power profile and keyboard RGB panel for
  Acer Nitro and Predator laptops, in the same theme.

## Status

Exported from the author's daily setup on an Acer Nitro AN515-56. The installer has been run with
`--dry-run` and in a throwaway home, not yet on a clean install. Reports are welcome.

## License

MIT, copyright Dausan Adam Parikesit (dap_). See [LICENSE](LICENSE). Gundam and Celestial Being are
trademarks of Sunrise/Bandai Namco; this is an unofficial fan theme.
