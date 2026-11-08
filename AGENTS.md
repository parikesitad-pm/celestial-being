# AGENTS.md — celestial-being

> Read `PILOT.md` first: the pilot's briefing, current phase, and decisions already made.

Public repo. A Gundam 00 themed Arch Linux desktop: Hyprland (Lua config) + Quickshell, with
terminal, prompt and app colors. Exported from the author's private dotfiles; changes made here
are merged back there by hand, so keep commits small and focused.

## Commands
| Goal | Command |
|---|---|
| Dry run the installer | `./install.sh --dry-run` |
| Install into a throwaway home | `HOME="$(mktemp -d)" ./install.sh --skip-system --pilot tester` |
| Check a shell script | `bash -n install.sh` |
| Check the live Hyprland config | `hyprctl configerrors` (empty output means clean) |
| Shell logs | `qs -c dap log` |

## Stack
- Hyprland 0.57 with Lua config.
- Quickshell (QML): left side bar with the apps, island with tabs (control center, system, apps, session), launcher, Overview, notification server (`quickshell/dap/`), lock screen (`quickshell/dap-lock/`).
- fish/zsh with a terminal HUD, Ghostty/kitty, starship, fastfetch, qt6ct and KDE color scheme.

## Structure
| Path | Purpose |
|---|---|
| `hypr/hyprland.lua` | Compositor config, desktops, binds, `dap_add_desktop` / `dap_remove_desktop` |
| `hypr/scripts/` | Helpers called by binds and the shell |
| `quickshell/dap/` | Shell components; new files need a `qmldir` entry |
| `quickshell/dap-lock/` | Lock screen |
| `install.sh` | Installer: packages, config copy with backup, services, pilot name |

## Conventions
- Workspace IDs stay numeric; names are display only (`deskNames` in `quickshell/dap/Ui.qml`).
- Colors and fonts: `quickshell/dap/Theme.qml`. No rainbow gradients.
- New QML types need a `qmldir` entry and a full Quickshell restart; hot reload does not pick them up.
- When `install.sh` gains a config path, add it to the Contents table in `README.md`.

## Definition of done
- `bash -n` passes on changed scripts and `hyprctl configerrors` is empty.
- `qs -c dap log` shows "Configuration Loaded" with no QML errors.

## Don't
- No personal data: names, addresses, monitor serials, calendar URLs, Wi-Fi names, home paths.
- No copyrighted images; the README lists the images users add themselves.
