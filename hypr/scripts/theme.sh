#!/usr/bin/env bash
# usage: theme.sh dark|light|toggle|apply   — switches wallpaper + GTK/Qt colour scheme
S="$HOME/.local/state/dap-theme"; W="$HOME/Pictures/wallpapers"
cur=$(cat "$S" 2>/dev/null || echo dark)
case "$1" in toggle) [ "$cur" = dark ] && m=light || m=dark;; dark|light) m=$1;; apply|"") m=$cur;; esac
echo "$m" > "$S"
if [ "$m" = dark ]; then wp="$W/gundam-dark.jpg"; cs=prefer-dark; gtk=adw-gtk3-dark; else wp="$W/gundam-light.jpg"; cs=prefer-light; gtk=adw-gtk3; fi
hyprctl hyprpaper wallpaper ",$wp" >/dev/null 2>&1
gsettings set org.gnome.desktop.interface color-scheme "$cs"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk"
