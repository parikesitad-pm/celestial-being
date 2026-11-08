#!/usr/bin/env bash
# Arch Ark: installs the dap_ Hyprland + Quickshell desktop from this repo onto a fresh Arch Linux.
#
#   git clone https://github.com/parikesitad-pm/celestial-being.git
#   cd celestial-being
#   ./install.sh --dry-run      # show every step, change nothing
#   ./install.sh                # install; asks for your pilot name
#
# Existing configs are moved to ~/.config-backup/arch-ark-<time>/ before anything is copied.
# Hardware-specific tuning (zram, GPU rules, NVIDIA) is not applied; see README.md.
#
# Try it without touching your own setup (no sudo, no packages, a throwaway home):
#   HOME="$(mktemp -d)" ./install.sh --skip-system --pilot tester
set -euo pipefail

ARCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup/arch-ark-$STAMP"
DRY=0
PACKAGES=1
SYSTEM=1      # packages, sudo and services; off with --skip-system
PILOT=""
SITE=""

PACMAN_PKGS=(
  # compositor and shell
  hyprland quickshell hyprpaper hypridle hyprlock hyprpicker hyprsunset hyprlauncher hyprshutdown
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk polkit-kde-agent qt6ct
  # terminals and command line
  ghostty kitty fish zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions starship fastfetch eza bat ripgrep fd fzf zoxide jq btop git curl
  # audio, media, notifications
  pipewire pipewire-pulse wireplumber pavucontrol playerctl cava libnotify sound-theme-freedesktop
  # screenshots, recording, clipboard
  grim slurp wf-recorder ffmpeg wl-clipboard cliphist
  # hardware controls
  brightnessctl power-profiles-daemon networkmanager network-manager-applet bluez bluez-utils blueman
  # apps, fonts, glue
  dolphin xdg-utils glib2 ttf-jetbrains-mono-nerd inter-font noto-fonts-emoji
)
AUR_PKGS=(candy-icons-git bibata-cursor-theme-bin)

# repo path (relative to the repo root)  →  install path
LINKS=(
  "hypr:$HOME/.config/hypr"
  "quickshell:$HOME/.config/quickshell"
  "fish:$HOME/.config/fish"
  "zsh/.zshrc:$HOME/.zshrc"
  "fastfetch:$HOME/.config/fastfetch"
  "ghostty:$HOME/.config/ghostty"
  "kitty:$HOME/.config/kitty"
  "waybar:$HOME/.config/waybar"
  "qt6ct:$HOME/.config/qt6ct"
  "spotify-player:$HOME/.config/spotify-player"
  "icons/GN-Sonar:$HOME/.local/share/icons/GN-Sonar"
  "starship/starship.toml:$HOME/.config/starship.toml"
  "starship/full.toml:$HOME/.config/starship/full.toml"
  "starship/mid.toml:$HOME/.config/starship/mid.toml"
  "starship/min.toml:$HOME/.config/starship/min.toml"
  "kde/kdeglobals:$HOME/.config/kdeglobals"
  "kde/DapGN.colors:$HOME/.local/share/color-schemes/DapGN.colors"
)

say()  { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
run()  {
  if (( DRY )); then printf '    [dry-run] %s\n' "$*"; else "$@"; fi
}

usage() {
  cat <<EOF
Usage: ./install.sh [--dry-run] [--skip-packages] [--skip-system] [--pilot NAME] [--site TEXT]

  --dry-run         print every step without changing anything
  --skip-packages   only copy configs (packages already installed)
  --skip-system     no packages, no sudo, no services: configs only (for testing in a throwaway HOME)
  --pilot NAME      the name shown in the bar, terminal HUD and lock screen (asked if not given)
  --site TEXT       website or tagline shown next to it (optional)
EOF
}

while (( $# )); do
  case "$1" in
    --dry-run) DRY=1 ;;
    --skip-packages) PACKAGES=0 ;;
    --skip-system) SYSTEM=0; PACKAGES=0 ;;
    --pilot) PILOT="${2-}"; shift ;;
    --site) SITE="${2-}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage; die "unknown option: $1" ;;
  esac
  shift
done

[[ -f /etc/arch-release ]] || die "this installer is for Arch Linux"
(( EUID != 0 )) || die "run as your normal user, not root (sudo is asked for when needed)"
(( SYSTEM == 0 )) || command -v sudo >/dev/null || die "sudo is required"
[[ -d "$ARCH_DIR/quickshell/dap" ]] || die "run this from a clone of the repo (quickshell/ is missing)"

# Names go into config files through sed, so only plain characters are accepted.
valid_pilot() { [[ "$1" =~ ^[A-Za-z0-9_.-]{1,20}$ ]]; }
valid_site()  { [[ -z "$1" || "$1" =~ ^[A-Za-z0-9_./:-]{1,40}$ ]]; }
if [[ -z "$PILOT" && -t 0 ]]; then
  while :; do
    read -rp "  pilot name [${USER:-pilot}]: " PILOT
    PILOT="${PILOT:-${USER:-pilot}}"
    valid_pilot "$PILOT" && break
    info "letters, numbers, _ . - only (max 20)"
  done
  while :; do
    read -rp "  site or tagline (optional, e.g. yourname.dev): " SITE
    valid_site "$SITE" && break
    info "letters, numbers, _ . / : - only (max 40)"
  done
fi
PILOT="${PILOT:-${USER:-pilot}}"
valid_pilot "$PILOT" || die "pilot name: letters, numbers, _ . - only (max 20)"
valid_site "$SITE" || die "site: letters, numbers, _ . / : - only (max 40)"
SITE="${SITE:-arch-ark}"
CALLSIGN="$(printf '%s' "${PILOT//[^A-Za-z0-9]/}" | cut -c1-3 | tr '[:lower:]' '[:upper:]')-01"

printf '\033[1;33m'
cat <<'EOF'
  ◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢
   ARCH ARK // dap_ desktop installer
  ◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢
EOF
printf '\033[0m'
(( DRY )) && info "dry run: nothing will be changed"
info "pilot: $PILOT   callsign: $CALLSIGN   site: $SITE"

if (( PACKAGES )); then
  say "1/5 Packages from the Arch repositories"
  (( DRY )) || sudo -v
  run sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

  say "2/5 AUR helper and AUR packages"
  if ! command -v yay >/dev/null; then
    info "yay not found: building yay-bin from the AUR"
    run sudo pacman -S --needed --noconfirm base-devel
    tmp="$(mktemp -d)"
    run git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    if (( DRY )); then info "[dry-run] (cd $tmp/yay-bin && makepkg -si --noconfirm)"
    else (cd "$tmp/yay-bin" && makepkg -si --noconfirm); fi
    run rm -rf "$tmp"
  fi
  run yay -S --needed --noconfirm "${AUR_PKGS[@]}" || info "AUR step failed; rerun later: yay -S ${AUR_PKGS[*]}"
else
  say "1-2/5 Packages skipped"
fi

say "3/5 Configs (old ones go to ${BACKUP/#$HOME/\~})"
for pair in "${LINKS[@]}"; do
  src="$ARCH_DIR/${pair%%:*}"
  dst="${pair#*:}"
  [[ -e "$src" ]] || { info "skip ${pair%%:*} (not in repo)"; continue; }
  if [[ -e "$dst" || -L "$dst" ]]; then
    rel="${dst#$HOME/}"
    run mkdir -p "$BACKUP/$(dirname "$rel")"
    run mv "$dst" "$BACKUP/$rel"
  fi
  run mkdir -p "$(dirname "$dst")"
  run cp -a "$src" "$dst"
  info "${pair%%:*}  →  ${dst/#$HOME/\~}"
done
# qt6ct needs an absolute path to its colour file.
run sed -i "s|@HOME@|$HOME|" "$HOME/.config/qt6ct/qt6ct.conf"
# Scripts called by Hyprland binds and the shell must stay executable.
run chmod +x "$HOME"/.config/hypr/scripts/*.sh

# Swap the author's name, callsign and site for the pilot's, only in the strings that show on screen.
personalize() {  # file sed-expression...
  local file="$1"; shift
  [[ -f "$file" || $DRY -eq 1 ]] || return 0
  local args=()
  for e in "$@"; do args+=(-e "$e"); done
  run sed -i "${args[@]}" "$file"
}
C="$HOME/.config"
personalize "$C/fish/conf.d/hud.fish"               "s|PILOT dap_|PILOT $PILOT|"
personalize "$C/quickshell/dap/Island.qml"          "s|PILOT dap_|PILOT $PILOT|"
personalize "$C/quickshell/dap/IslandHeader.qml"    "s|PILOT dap_|PILOT $PILOT|"
personalize "$C/quickshell/dap/Bar.qml"             "s|text: \"dap_\"|text: \"$PILOT\"|"
personalize "$C/fastfetch/hud.jsonc"                "s|DAP-01|$CALLSIGN|" "s|mdap_|m$PILOT|" "s|d-ap\.my\.id|$SITE|"
personalize "$C/fastfetch/config.jsonc"             "s|  dap_|  $PILOT|" "s|d-ap\.my\.id|$SITE|"
personalize "$C/waybar/config.jsonc"                "s|  dap_\"|  $PILOT\"|" "s|d-ap\.my\.id|$SITE|"
personalize "$C/hypr/hyprlock.conf"                 "s|<i>dap_</i>|<i>$PILOT</i>|" "s|text = d-ap\.my\.id|text = $SITE|"
personalize "$C/quickshell/dap-lock/components/organisms/LockStack.qml" "s|text: \"d-ap\.my\.id\"|text: \"$SITE\"|"
info "name on screen: $PILOT ($CALLSIGN)"

say "4/5 State folders and services"
run mkdir -p "$HOME/.local/state" "$HOME/.local/share/dap-shell" "$HOME/Pictures/wallpapers" "$HOME/.config/dap-shell"
# Google Calendar link for the island: you paste your calendar's secret iCal address here later.
if [[ ! -e "$HOME/.config/dap-shell/gcal-ics-url" ]]; then
  run install -m 600 /dev/null "$HOME/.config/dap-shell/gcal-ics-url"
fi
if (( SYSTEM )); then
  run sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon
else
  info "services skipped (--skip-system)"
fi

say "5/5 Done. Before you log in:"
cat <<EOF
    • Images are not in the repo (copyright and personal photos). Add your own:
        wallpaper         ~/Pictures/wallpapers/gundam-dark.jpg   (path set in ~/.config/hypr/hyprpaper.conf)
        bar emblem        ~/.local/share/dap-shell/cb-64.png      (also cb-32.png, cb-128.png)
        lock screen       ~/.config/quickshell/dap-lock/assets/avatar.jpg and gundam-lock.png
    • Make fish your shell:      chsh -s /usr/bin/fish
    • Google Calendar (optional): paste the calendar's "Secret address in iCal format" into
        ~/.config/dap-shell/gcal-ics-url
    • Monitors: edit hl.monitor(...) at the top of ~/.config/hypr/hyprland.lua for your screens.
    • Log out, pick Hyprland at the login screen. The bar starts with: quickshell -c dap
EOF
(( DRY )) && info "dry run finished: nothing was changed"
exit 0
