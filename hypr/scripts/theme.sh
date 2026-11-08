#!/usr/bin/env bash
# usage: theme.sh dark|light|toggle|next|apply|<profile>
# Switches the wallpaper profile and the GTK/Qt colour scheme. Profiles live in
# ~/.config/hypr/wallpaper-profiles ("name file mode" per line). dark/light are profiles too.
P="$HOME/.config/hypr/wallpaper-profiles"; W="$HOME/Pictures/wallpapers"
S="$HOME/.local/state/dap-theme"; SP="$HOME/.local/state/dap-wallpaper-profile"
profiles() { grep -v '^\s*#' "$P" 2>/dev/null | awk 'NF >= 3 { print $1 }'; }
field() { grep -v '^\s*#' "$P" 2>/dev/null | awk -v n="$1" -v f="$2" '$1 == n { print $f; exit }'; }

cur=$(cat "$SP" 2>/dev/null); [ -n "$(field "$cur" 1)" ] || cur=$(cat "$S" 2>/dev/null || echo dark)
case "$1" in
  toggle) [ "$(field "$cur" 3)" = light ] && p=dark || p=light ;;
  next)   p=$(profiles | awk -v c="$cur" 'NR == 1 { first = $1 } found { print; exit } $1 == c { found = 1 } END { if (!found || NR == 0) print first }' | head -1)
          [ -n "$p" ] || p=$(profiles | head -1) ;;
  apply|"") p=$cur ;;
  *) p=$1 ;;
esac
file=$(field "$p" 2); mode=$(field "$p" 3)
if [ -z "$file" ]; then   # no profile file yet, or an unknown name: fall back to the old dark/light pair
  [ "$p" = light ] && { file=gundam-light.jpg; mode=light; } || { p=dark; file=gundam-dark.jpg; mode=dark; }
fi
echo "$mode" > "$S"; echo "$p" > "$SP"
if [ "$mode" = light ]; then cs=prefer-light; gtk=adw-gtk3; else cs=prefer-dark; gtk=adw-gtk3-dark; fi
# hyprpaper may still be starting at login; retry briefly.
for _ in 1 2 3 4 5; do hyprctl hyprpaper wallpaper ",$W/$file" >/dev/null 2>&1 && break; sleep 1; done
gsettings set org.gnome.desktop.interface color-scheme "$cs"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk"
