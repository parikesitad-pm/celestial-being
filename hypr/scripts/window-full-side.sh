#!/usr/bin/env bash
# Gives the focused tiled window a whole side of the workspace.
# movetoroot refuses a window already at the root, so pressing again flips
# between a full-width row and a full-height column.
hyprctl dispatch 'hl.dsp.layout("movetoroot")' >/dev/null
hyprctl dispatch 'hl.dsp.layout("togglesplit")' >/dev/null

# With two other windows, lay them out across the remaining space:
# side by side next to a full-width row, stacked next to a full-height column.
win=$(hyprctl activewindow -j)
addr=$(jq -r .address <<<"$win")
others=$(hyprctl clients -j | jq -c --argjson w "$win" \
  '[.[] | select(.workspace.id == $w.workspace.id and .mapped and (.floating | not) and .address != $w.address)]')
[[ $(jq length <<<"$others") == 2 ]] || exit 0

flip=$(jq -r --argjson w "$win" '
  ($w.at[0] <= .[0].at[0] and $w.at[0] <= .[1].at[0] and
   $w.at[0] + $w.size[0] >= .[0].at[0] + .[0].size[0] and
   $w.at[0] + $w.size[0] >= .[1].at[0] + .[1].size[0]) as $row
  | if $row then .[0].at[0] == .[1].at[0] else .[0].at[1] == .[1].at[1] end' <<<"$others")
[[ $flip == true ]] || exit 0

hyprctl dispatch "hl.dsp.focus({ window = \"address:$(jq -r '.[0].address' <<<"$others")\" })" >/dev/null
hyprctl dispatch 'hl.dsp.layout("togglesplit")' >/dev/null
hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >/dev/null
