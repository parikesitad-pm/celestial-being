#!/usr/bin/env bash
# Bakes the hyprlock background frames from the lock wallpaper: a soft bottom scrim (shape widgets
# only take a flat color) plus one flare per beam. Re-run after changing the wallpaper.
set -euo pipefail
src="${1:-$HOME/Pictures/wallpapers/gundam-lock.png}"
out="$HOME/.local/share/hyprlock-frames"
mkdir -p "$out"

# Beam positions are measured from the art: fractions of its width, scaled to 1920.
bake() {
    local i=$1 r=$2 g=$3 b=$4; shift 4
    local glow="" x
    for x in "$@"; do
        glow+="+0.60*exp(-pow((X-$x)/34\,2))+0.18*exp(-pow((X-$x)/170\,2))"
    done
    local v="min(1\,0${glow})*clip((780-Y)/260\,0\,1)"
    ffmpeg -v error -y \
        -i "$src" \
        -f lavfi -i "color=black:s=1920x1080:d=1,format=gbrp,geq=r='$r*$v':g='$g*$v':b='$b*$v'" \
        -f lavfi -i "color=0x070b14:s=1920x1080:d=1,format=rgba,geq=r='r(X\,Y)':g='g(X\,Y)':b='b(X\,Y)':a='160*clip((Y-740)/119\,0\,1)'" \
        -filter_complex "[0:v]scale=1920:1080:flags=lanczos,format=gbrp[art];[art][1:v]blend=all_mode=screen[lit];[lit][2:v]overlay=format=auto,format=yuv420p" \
        -frames:v 1 -q:v 3 "$out/frame-$i.jpg"
}
bake 0 46 230 168 2
bake 1 255 159 28 369 737
bake 2 59 130 246 1169
bake 3 168 85 247 1538
ls -la "$out"
