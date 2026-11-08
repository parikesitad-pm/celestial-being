#!/bin/bash
# macOS-style screenshots. Usage: screenshot.sh full|region|window|record|record-region [GEOMETRY]
# GEOMETRY ("X,Y WxH") skips slurp; the shell's region picker (RegionSelect.qml) passes it.
# Saves to ~/Pictures/Screenshots/"Screenshot YYYY-MM-DD at HH.MM.SS.png", copies to clipboard, shows a thumbnail notification.
dir="$HOME/Pictures/Screenshots"; mkdir -p "$dir"
mode="$1"; given="$2"
stamp="$(date '+%Y-%m-%d at %H.%M.%S')"
file="$dir/Screenshot $stamp.png"

notify() { # title body icon
  gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.Notify "Screenshot" 0 "$3" "$1" "$2" "[]" "{}" 4000 >/dev/null 2>&1
}
windows() { hyprctl clients -j | jq -r '.[] | select(.mapped and (.hidden|not) and .workspace.id == (env.WS|tonumber)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'; }

case "$mode" in
  full)   grim "$file" ;;
  region) geo="${given:-$(slurp -d)}" || exit 0; [ -n "$geo" ] || exit 0; grim -g "$geo" "$file" ;;
  window) export WS="$(hyprctl activeworkspace -j | jq .id)"
          geo="$(windows | slurp -r)" || exit 0; grim -g "$geo" "$file" ;;
  record|record-region)
    command -v wf-recorder >/dev/null || { notify "Screen recording" "Install wf-recorder first" "dialog-warning"; exit 1; }
    if pgrep -x wf-recorder >/dev/null; then pkill -INT -x wf-recorder; exit 0; fi
    out="$dir/Screen Recording $stamp.mp4"
    if [ "$mode" = record-region ]; then geo="${given:-$(slurp -d)}" || exit 0; [ -n "$geo" ] || exit 0; notify "Recording" "Press the shortcut again to stop" "media-record"; wf-recorder -g "$geo" -f "$out"
    else notify "Recording" "Press the shortcut again to stop" "media-record"; wf-recorder -f "$out"; fi
    notify "Recording saved" "$(basename "$out")" "video-x-generic"; exit 0 ;;
  *) exit 1 ;;
esac
[ -s "$file" ] || exit 1
wl-copy < "$file"
notify "Screenshot saved" "$(basename "$file")" "$file"
