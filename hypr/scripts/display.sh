#!/usr/bin/env bash
# usage: display.sh extend|mirror|pc|portrait|left|right|status
# Switches the external monitor between extend / duplicate / off, rotates it, and
# places it left or right of the laptop. Runtime only (hyprctl eval), except the side,
# which is saved for the next start: hyprland.lua reads the same file.
INT="eDP-1"
SIDE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/dap-display-side"
SIDE=$(cat "$SIDE_FILE" 2>/dev/null)
[ "$SIDE" = left ] || SIDE=right
J=$(hyprctl monitors all -j)
EXT=$(python3 -c "import json,sys;print(next((m['name'] for m in json.load(sys.stdin) if m['name']!='$INT'),''))" <<<"$J")
[ -z "$EXT" ] && { [ "$1" = status ] && echo "none 0 $SIDE"; exit 0; }
TR=$(python3 -c "import json,sys;print(next(m['transform'] for m in json.load(sys.stdin) if m['name']=='$EXT'))" <<<"$J")
mon() { hyprctl eval "hl.monitor({ output = \"$EXT\", $1 })" >/dev/null; }

case "$1" in
  extend)   mon "disabled = false, mode = \"preferred\", position = \"auto-$SIDE\", scale = 1, transform = $TR, mirror = \"\"" ;;
  mirror)   mon "disabled = false, mode = \"preferred\", position = \"auto\", scale = 1, transform = 0, mirror = \"$INT\"" ;;
  pc)       mon "disabled = true" ;;
  portrait) [ "$TR" = 0 ] && n=1 || n=0
            mon "disabled = false, mode = \"preferred\", position = \"auto-$SIDE\", scale = 1, transform = $n, mirror = \"\"" ;;
  left|right)
            mkdir -p "$(dirname "$SIDE_FILE")"
            echo "$1" >"$SIDE_FILE"
            mon "disabled = false, mode = \"preferred\", position = \"auto-$1\", scale = 1, transform = $TR, mirror = \"\"" ;;
  status)   python3 -c "
import json,sys
ms=json.load(sys.stdin)
m=next(x for x in ms if x['name']=='$EXT')
i=next(x for x in ms if x['name']=='$INT')
mode='pc' if m['disabled'] else ('mirror' if m.get('mirrorOf') not in (None,'none') else 'extend')
side=('left' if m['x']<i['x'] else 'right') if mode=='extend' else '$SIDE'
print(mode, 1 if m['transform'] in (1,3) else 0, side)" <<<"$J" ;;
esac
