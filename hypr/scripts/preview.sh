#!/bin/bash
# Quick Look for Dolphin: previews the selected file in the shell panel (Preview.qml).
# Dolphin has no D-Bus call for the selection, so this triggers "Copy Location" and puts
# the clipboard back afterwards, including the cliphist history.
set -u

[ "$(qs -c dap ipc call shell previewClose)" = "true" ] && exit 0

read -r pid class < <(hyprctl activewindow -j | jq -r '"\(.pid) \(.class)"')
[ "$class" = "org.kde.dolphin" ] || exit 0

service="org.kde.dolphin-$pid"
action="/dolphin/Dolphin_1/actions/copy_location"
qaction="org.qtproject.Qt.QAction"

saved=$(mktemp -p "${XDG_RUNTIME_DIR:-/tmp}")
trap 'rm -f "$saved"' EXIT

types=$(wl-paste -l 2>/dev/null)
type=""
for wanted in text/uri-list image/png "text/plain;charset=utf-8" text/plain; do
    if grep -qxF "$wanted" <<<"$types"; then type=$wanted; break; fi
done
[ -n "$type" ] || type=$(head -n 1 <<<"$types")
[ -n "$type" ] && wl-paste -n -t "$type" >"$saved" 2>/dev/null

# With no selection Dolphin writes nothing, so a path already on the clipboard must not survive.
wl-copy --clear
busctl --user call "$service" "$action" "$qaction" trigger || exit 1
sleep 0.05
path=$(wl-paste -n 2>/dev/null)

if [ -s "$saved" ]; then wl-copy -t "$type" <"$saved"; else wl-copy --clear; fi

# The history watcher stores the path asynchronously.
sleep 0.2
cliphist list | P="$path" awk -F'\t' '$2 == ENVIRON["P"] { print; exit }' | cliphist delete

[ -e "$path" ] || exit 0

case "$(file -Lb --mime-type -- "$path")" in
    inode/directory) exit 0 ;;
    image/*) kind=image ;;
    text/* | inode/x-empty | application/json | application/xml | application/javascript | application/x-shellscript | application/x-yaml | application/toml) kind=text ;;
    *) exec xdg-open "$path" ;;
esac

qs -c dap ipc call shell preview "$kind" "$path" "$(stat -Lc %s -- "$path")"
