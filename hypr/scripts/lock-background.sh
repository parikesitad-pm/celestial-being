#!/usr/bin/env bash
# Picks the hyprlock background frame for this moment. Frames come from lock-frames.sh.
printf -v t '%(%s)T' -1
printf '%s\n' "$HOME/.local/share/hyprlock-frames/frame-$(( t / 4 % 4 )).jpg"
