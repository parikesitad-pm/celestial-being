#!/usr/bin/env bash
# Prints one frame of the hyprlock clock: a GN light sweeps across the digits and the colon pulses.
# hyprlock cannot tween labels, so the label re-runs this every 200 ms. Uses bash builtins only.
printf -v hm '%(%H%M)T' -1
now=${EPOCHREALTIME/[.,]/}
ms=$(( now / 1000 ))

# Sweep position in hundredths of a character slot, one pass every 5 s, off-screen for most of it.
pos=$(( (ms % 5000) * 700 / 5000 - 100 ))

frame=""
slot=0
emit() {
    local dist=$(( pos - $1 * 100 )) mix r g b
    (( dist < 0 )) && dist=$(( -dist ))
    mix=$(( dist >= 120 ? 0 : 100 - dist * 100 / 120 ))
    r=$(( 255 - (255 - 46) * mix / 100 ))
    g=$(( 255 - (255 - 230) * mix / 100 ))
    b=$(( 255 - (255 - 168) * mix / 100 ))
    printf -v color '#%02x%02x%02x' "$r" "$g" "$b"
    frame+="<span foreground='$color'>$2</span>"
}
emit 0 "${hm:0:1}"
emit 1 "${hm:1:1}"

# Colon alpha follows a triangle wave over 2 s, between 35% and 100%.
phase=$(( ms % 2000 ))
(( phase > 1000 )) && phase=$(( 2000 - phase ))
frame+="<span alpha='$(( 35 + phase * 65 / 1000 ))%'>:</span>"

emit 3 "${hm:2:1}"
emit 4 "${hm:3:1}"
printf '%s\n' "<span font_features='tnum' weight='bold'>$frame</span>"
