# Cockpit HUD: boot decode, command debrief, width-aware prompt.
# Everything is event-driven, so an idle shell costs nothing.
# Set NOANIM=1 to turn the animation off and keep the same text.
# Ghostty and kitty only: fish in any other terminal keeps the default prompt and fastfetch.

status is-interactive; and contains -- "$TERM" xterm-ghostty xterm-kitty; or return

# TUIs own the screen and long-lived sessions, so their runtime says nothing.
set -g __hud_tuis nvim vim vi nano less more man claude agy btop top htop nvtop ssh fzf tmux lazygit yazi watch

# Boot reveal engine: rain, then a decode wipe over the fastfetch sheet.
set -g __hud_reveal (path resolve (status dirname)/../hud/reveal.py)

function __hud_layout --on-variable COLUMNS --on-signal WINCH
    set -l layout ~/.config/starship/full.toml
    if test "$COLUMNS" -lt 60
        set layout ~/.config/starship/min.toml
    else if test "$COLUMNS" -lt 100
        set layout ~/.config/starship/mid.toml
    end
    test "$STARSHIP_CONFIG" = "$layout"; or set -gx STARSHIP_CONFIG $layout
end
__hud_layout

function __hud_animates
    isatty stdout
    and not set -q SSH_CONNECTION
    and not set -q NOANIM
end

# Text locks in left to right behind a band of noise, then settles. 30 fps.
function __hud_decode --argument-names text sgr frames
    set -l text (string sub -l (math "max($COLUMNS - 1, 1)") -- $text)
    if not __hud_animates
        printf '\e[%sm%s\e[0m\n' $sgr $text
        return
    end
    set -l noise ▓ ▒ ░ '#' % '&' @ '$' = + 0 1
    set -l n (string length -- $text)
    printf '\e[?25l'
    for frame in (seq $frames)
        set -l front (math "floor($n * (1 - 2 ^ (-8 * $frame / $frames)))")
        set -l hot_from (math "max($front - 6, 0)")
        set -l hot
        for i in (seq (math $hot_from + 1) $front)
            set -a hot $noise[(math "($i * 7 + $frame * 13) % $(count $noise) + 1")]
        end
        printf '\r\e[K\e[%sm%s\e[90m%s\e[%sm█\e[0m' $sgr (string sub -l $hot_from -- $text) (string join '' -- $hot) $sgr
        sleep 0.033
    end
    printf '\r\e[K\e[%sm%s\e[0m\n\e[?25h' $sgr $text
end

function __hud_hazard_stripe
    set -l width (math "min($COLUMNS - 1, 48)")
    set -l stripe (string sub -l $width -- (string repeat -n $width ◤◢))
    if __hud_animates
        for step in 0.25 0.5 0.75
            printf '\r\e[33m%s\e[0m' (string sub -l (math "floor($width * $step)") -- $stripe)
            sleep 0.033
        end
    end
    printf '\r\e[K\e[33m%s\e[0m\n' $stripe
end

# Red/cyan channel split that jitters over the first characters, then settles red: a fault you notice.
function __hud_glitch --argument-names text
    set -l text (string sub -l (math "max($COLUMNS - 1, 1)") -- $text)
    if not __hud_animates
        printf '\e[31m%s\e[0m\n' $text
        return
    end
    set -l noise ▓ ▒ ░ '#' 0 1
    printf '\e[?25l'
    for frame in 1 2 3 4 5
        set -l head (string sub -l 6 -- $text)
        set -l torn (string replace -ra '[A-Za-z0-9]' $noise[(math "$frame % $(count $noise) + 1")] -- $head)
        if test (math "$frame % 2") -eq 1
            printf '\r\e[K \e[36m%s%s\e[0m' $torn (string sub -s 7 -- $text)
        else
            printf '\r\e[K\e[31m%s%s\e[0m' $torn (string sub -s 7 -- $text)
        end
        sleep 0.033
    end
    printf '\r\e[K\e[1;31m%s\e[0m\n\e[?25h' $text
end

function hud_fetch --description 'fastfetch sized to the current pane; --reveal plays the boot animation'
    argparse r/reveal -- $argv; or return
    set -l args -c ~/.config/fastfetch/hud.jsonc
    if test "$COLUMNS" -lt 56; or test "$LINES" -lt 12
        set -a args --logo none --structure kernel:memory:uptime
    else if test "$COLUMNS" -lt 60; or test "$LINES" -lt 21
        set -a args --logo arch_small --structure kernel:memory:uptime
    else if test "$COLUMNS" -lt 80
        set -a args --logo arch_small
    end
    if set -q _flag_reveal; and __hud_animates; and test -f $__hud_reveal
        fastfetch $args --pipe false | python3 $__hud_reveal
    else
        fastfetch $args
    end
end

function hud_boot --description 'cockpit start sequence, then the spec sheet'
    # This shell was opened by `veda dock`: it is the dock, not a cockpit.
    if set -q __veda_dock_pane
        __veda_dock_pane_start
        return
    end
    # A burst of new tabs or splits shares one animated boot.
    set -l stamp $XDG_RUNTIME_DIR/hud-boot-stamp
    set -l age (path mtime --relative $stamp 2>/dev/null)
    touch $stamp 2>/dev/null
    if test -n "$age"; and test "$age" -lt 20
        set -lx NOANIM 1
        __hud_boot_sequence
    else
        __hud_boot_sequence
    end
end

function __hud_boot_sequence
    if test "$COLUMNS" -ge 40
        __hud_hazard_stripe
        __hud_decode 'CELESTIAL BEING // PILOT dap_' 36 5
    end
    hud_fetch --reveal
end

# ───────── VEDA LOG: last commands, threat badge, error card, notch ping ─────────
# Veda records every sortie as "epoch|rc|took|command" in a file shared by all tabs (last 500 kept);
# __veda_log holds the newest five for this shell, newest first.
set -q VEDA_FILE; and set -g __veda_file $VEDA_FILE; or set -g __veda_file ~/.local/state/veda/log
set -g __veda_log
function __veda_load --description 'newest five commands from the shared log, newest first'
    set -g __veda_log
    test -f $__veda_file; or return
    for e in (tail -n 5 $__veda_file)
        set -p __veda_log (string split -m1 '|' -- $e)[2]
    end
end
__veda_load

# `veda dock` leaves this marker and asks Ghostty for a split; the shell that starts in the new split
# within 5 s finds it and becomes the dock instead of a normal prompt.
set -g __veda_req $XDG_RUNTIME_DIR/veda-dock-request
# While a command runs, its text sits in veda-active/<pid> (the dock shows it as ACTIVE).
set -g __veda_active $XDG_RUNTIME_DIR/veda-active
mkdir -p $__veda_active (path dirname $__veda_file)
if test -f $__veda_req; and test (path mtime --relative $__veda_req) -le 5
    rm -f $__veda_req
    set -g __veda_dock_pane 1
end
set -g __veda_scan
set -gx VEDA_OK NOMINAL   # starship shows ◆ NOMINAL or ◆ HIGH · rc from these two

function __veda_record --argument-names rc took cmd
    set -g __veda_log "$rc|$took|$cmd" $__veda_log[1..4]
    echo (date +%s)"|$rc|$took|"(string replace -a \n ' ' -- $cmd) >> $__veda_file
    test (count < $__veda_file) -gt 1000; and tail -n 500 $__veda_file > $__veda_file.tmp; and mv $__veda_file.tmp $__veda_file
    if test $rc -eq 0; or test $rc -eq 130
        set -gx VEDA_OK NOMINAL; set -e VEDA_HIGH
    else
        set -gx VEDA_HIGH "HIGH · $rc"; set -e VEDA_OK
    end
end

function __veda_card --argument-names rc
    set -l w (math "min($COLUMNS, 76) - 2")
    set -l label "FAULT rc=$rc"
    test $rc -eq 127; and set label "UNKNOWN UNIT // command not found"
    test $rc -eq 126; and set label "ACCESS DENIED // not executable"
    test $rc -eq 130; and set label "ABORTED WITH ERRORS IN OUTPUT"
    set -l head "╭─ VEDA LOG ── THREAT: HIGH ── $label "
    printf '\e[1;31m%s%s╮\e[0m\n' $head (string repeat -n (math "max($w - 1 - "(string length -- $head)", 1)") ─)
    __veda_rows $w 31
    for line in $__veda_scan
        __veda_line $w 31 (printf '\e[33m▸ %s\e[0m' (string shorten -m (math "max($w - 6, 10)") -- $line))
    end
    printf '\e[1;31m╰%s╯\e[0m\n' (string repeat -n (math "max($w - 2, 1)") ─)
end

# One boxed line: dim left edge, text padded to the box width, right edge in the frame color.
function __veda_line --argument-names w c text
    set -l pad (math "max($w - 3 - "(string length -V -- "$text")", 0)")
    printf '\e[90m│\e[0m %s%s\e[1;%sm│\e[0m\n' "$text" (string repeat -n $pad ' ') $c
end

# One line per logged command: ✓/✗, exit code, duration, command.
function __veda_rows --argument-names w c
    for e in $__veda_log
        set -l f (string split -m2 '|' -- $e)
        set -l mark '\e[32m✓\e[0m'
        test $f[1] -ne 0; and set mark '\e[31m✗\e[0m'
        set -l code (string pad -w 4 -- $f[1])
        __veda_line $w $c (printf $mark' \e[90m%s %6s\e[0m  %s' $code $f[2] (string shorten -m (math "max($w - 20, 10)") -- $f[3]))
    end
end

# The dock: threat level, today's sorties, the last five commands. Shown when Ghostty opens; run `veda` any time.
function veda --description 'VEDA LOG: threat level and the last five commands (veda dock | veda watch)'
    switch "$argv[1]"
        case dock
            __veda_open_dock; return
        case watch
            __veda_watch; return
    end
    __veda_load
    set -l w (math "min($COLUMNS, 76) - 2")
    set -l last (string split -f1 '|' -- $__veda_log[1])
    set -l threat NOMINAL; set -l c 36
    if test -n "$last"; and test $last -ne 0; and test $last -ne 130
        set threat "HIGH · $last"; set c 31
    end
    set -l today 0; set -l faults 0
    if test -f $__veda_file
        set -l since (date -d 'today 00:00' +%s)
        for e in (cat $__veda_file)
            set -l f (string split '|' -- $e)
            test "$f[1]" -ge $since 2>/dev/null; or continue
            set today (math $today + 1)
            test "$f[2]" -ne 0 2>/dev/null; and test "$f[2]" -ne 130; and set faults (math $faults + 1)
        end
    end
    set -l head "╭─ VEDA LOG "
    set -l tail " ● ENGAGED ─╮"
    printf '\e[1;%sm%s%s%s\e[0m\n' $c $head (string repeat -n (math "max($w - "(string length -- "$head$tail")", 1)") ─) $tail
    __veda_line $w $c (printf 'Threat   \e[1;%sm%s\e[0m' $c $threat)
    __veda_line $w $c "Sorties  $today today · $faults faults"
    if set -q __veda_log[1]
        __veda_rows $w $c
    else
        __veda_line $w $c (printf '\e[90mno sorties recorded yet\e[0m')
    end
    printf '\e[1;%sm╰%s╯\e[0m\n' $c (string repeat -n (math "max($w - 2, 1)") ─)
end

# Ghostty cannot run a command in a new split, so Hyprland presses Ghostty's own split key (Ctrl+Shift+E)
# on this window; the new shell sees the marker above.
function __veda_open_dock
    set -l win (hyprctl activewindow -j 2>/dev/null | string match -rg '"address": "(0x[0-9a-f]+)"')
    test -n "$win"; or begin; echo "veda dock: no Hyprland window found"; return 1; end
    touch $__veda_req
    hyprctl dispatch "hl.dsp.send_shortcut({ mods = \"CTRL SHIFT\", key = \"E\", window = \"address:$win\" })" >/dev/null
end

# Runs in the dock split: shrink to 20 lines, give focus back to the pane above, then redraw on every log change.
function __veda_dock_pane_start
    set -l win (hyprctl activewindow -j 2>/dev/null | string match -rg '"address": "(0x[0-9a-f]+)"')
    set -l start $LINES
    for i in (seq 40)
        test "$LINES" -le 20; and break
        # Ghostty without the Ctrl+Shift+F11 keybind types the key as text instead: stop after 3 tries.
        if test $i -gt 3; and test "$LINES" -eq $start
            printf '\e[2K\rVEDA dock: reload the Ghostty config (Ctrl+Shift+,) so the dock can resize itself.\n'
            break
        end
        hyprctl dispatch "hl.dsp.send_shortcut({ mods = \"CTRL SHIFT\", key = \"F11\", window = \"address:$win\" })" >/dev/null
        sleep 0.08
    end
    hyprctl dispatch "hl.dsp.send_shortcut({ mods = \"CTRL ALT\", key = \"up\", window = \"address:$win\" })" >/dev/null
    __veda_watch
end

function __veda_watch
    # The animated sonar needs python3; without it the dock falls back to the plain card below.
    set -l sonar (path dirname (status filename))/../hud/veda_dock.py
    if command -q python3; and test -f $sonar
        python3 -I $sonar $__veda_file
        return
    end
    printf '\e[?25l'
    set -l seen ''
    while true
        set -l now (path mtime $__veda_file 2>/dev/null)"$COLUMNS"
        if test "$now" != "$seen"
            set seen $now
            printf '\e[H\e[2J'
            veda
        end
        sleep 1
    end
end

# npm, yay and pacman run inside `script`, so they keep a real terminal (colors, prompts) while their
# output is saved and scanned for error lines afterwards. One log per shell, overwritten on every run.
function __veda_capture
    set -g __veda_scan
    # In a pipe or with piped input the program must not see a terminal (no colors in piped output).
    if not isatty stdin; or not isatty stdout
        command $argv
        return $status
    end
    set -l log $XDG_RUNTIME_DIR/veda-last-$fish_pid.log
    # sh-safe quoting: wrap every argument in single quotes and escape the quotes inside.
    set -l quoted
    for a in $argv
        set -a quoted "'"(string replace -a "'" "'\\''" -- $a)"'"
    end
    env SHELL=/bin/sh script -qefc "command $quoted" $log
    set -l rc $status
    test -f $log; and set -g __veda_scan (string replace -ra '\e\[[0-9;?]*[A-Za-z]|\r' '' < $log \
        | string match -rv -- '^Script (started|done) on' \
        | string match -ri -- '.*(?:npm ERR!|\berror\b|\bfailed\b|\bfatal\b|exception).*' \
        | string match -rvi -- '\b0 (errors?|failed)\b|without errors' | string trim)[-3..-1]
    return $rc
end
function npm --wraps npm; __veda_capture npm $argv; end
function yay --wraps yay; __veda_capture yay $argv; end
function pacman --wraps pacman; __veda_capture pacman $argv; end

# Long sorties ping the island only when Ghostty is not the focused window.
function __veda_ping --argument-names rc took cmd
    hyprctl activewindow -j 2>/dev/null | string match -q '*"com.mitchellh.ghostty"*'; and return
    set -l result fail
    test $rc -eq 0; and set result ok
    qs -c dap ipc call shell sortie $result (string shorten -m 60 -- $cmd) $took >/dev/null 2>&1 &
    disown 2>/dev/null
end

function __hud_before --on-event fish_preexec
    set -l cmd (string trim -- $argv[1])
    set -g __veda_scan
    echo $cmd > $__veda_active/$fish_pid
    contains -- (string split -f1 ' ' -- $cmd) $__hud_tuis clear cls; and return
    printf '\e]9;4;3\a'
    set -l shown (string shorten -m (math "max($COLUMNS - 32, 8)") -- $cmd)
    # Loud only where it matters: elevated access, destructive commands and pushes are rare;
    # everything else stays a quick decode.
    if string match -qr '^(sudo|doas|run0)\b' -- $cmd
        __hud_hazard_stripe
        __hud_decode "WARNING // ELEVATED ACCESS » $shown" "1;33" 6
    else if string match -qr '(^|\s)(rm\s+-\S*[rR]|chmod\s+-R|chown\s+-R|dd\s|mkfs|git\s+push\s.*(-f\b|--force))' -- $cmd
        __hud_hazard_stripe
        __hud_decode "WARNING // DESTRUCTIVE » $shown" "1;33" 6
    else if string match -qr '^git\s+push\b' -- $cmd
        __hud_decode "GN DRIVE // EXIA LAUNCH » $shown" "1;32" 6
    else
        __hud_decode "» "(string shorten -m (math "max($COLUMNS - 4, 8)") -- $cmd) 36 5
    end
end

function __hud_debrief --on-event fish_postexec
    set -l rc $status
    echo -n > $__veda_active/$fish_pid
    printf '\e]9;4;0\a'
    set -l cmd (string trim -- $argv[1])
    test -n "$cmd"; or return

    set -l secs (math -s1 "$CMD_DURATION / 1000")
    set -l took {$secs}s
    test "$CMD_DURATION" -ge 60000; and set took (math -s0 "floor($CMD_DURATION / 60000)")m(math -s0 "floor($CMD_DURATION % 60000 / 1000)")s
    __veda_record $rc $took $cmd
    test "$CMD_DURATION" -ge 10000; and __veda_ping $rc $took $cmd
    contains -- (string split -f1 ' ' -- $cmd) $__hud_tuis; and return

    # Faults always show the VEDA LOG card; successes only a line when they took long enough.
    switch $rc
        case 0
            if test "$CMD_DURATION" -ge 30000
                __hud_decode "TRANS-AM COMPLETE // $took" "1;31" 7
            else if test "$CMD_DURATION" -ge 2000
                __hud_decode "CLEAR $took" 32 4
            end
        case 130
            if set -q __veda_scan[1]
                __veda_card $rc
            else if test "$CMD_DURATION" -ge 2000
                __hud_decode "ABORT $took" 33 4
            end
        case '*'
            __hud_glitch "FAULT rc=$rc $took"
            __veda_card $rc
    end
end
