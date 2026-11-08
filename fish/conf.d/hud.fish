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

function __hud_before --on-event fish_preexec
    set -l cmd (string trim -- $argv[1])
    contains -- (string split -f1 ' ' -- $cmd) $__hud_tuis clear cls; and return
    printf '\e]9;4;3\a'
    set -l shown (string shorten -m (math "max($COLUMNS - 32, 8)") -- $cmd)
    # Loud only where it matters: elevated access and pushes are rare; everything else stays a quick decode.
    if string match -qr '^(sudo|doas|run0)\b' -- $cmd
        __hud_hazard_stripe
        __hud_decode "WARNING // ELEVATED ACCESS » $shown" "1;33" 6
    else if string match -qr '^git\s+push\b' -- $cmd
        __hud_decode "GN DRIVE // EXIA LAUNCH » $shown" "1;32" 6
    else
        __hud_decode "» "(string shorten -m (math "max($COLUMNS - 4, 8)") -- $cmd) 36 5
    end
end

function __hud_debrief --on-event fish_postexec
    set -l rc $status
    printf '\e]9;4;0\a'
    set -l cmd (string trim -- $argv[1])
    test -n "$cmd"; or return
    contains -- (string split -f1 ' ' -- $cmd) $__hud_tuis; and return

    set -l secs (math -s1 "$CMD_DURATION / 1000")
    set -l took {$secs}s
    test "$CMD_DURATION" -ge 60000; and set took (math -s0 "floor($CMD_DURATION / 60000)")m(math -s0 "floor($CMD_DURATION % 60000 / 1000)")s

    # Faults always show; successes only when they took long enough to be worth a line.
    switch $rc
        case 0
            if test "$CMD_DURATION" -ge 30000
                __hud_decode "TRANS-AM COMPLETE // $took" "1;31" 7
                # Long jobs ping the island, so you can look away while they run.
                command -q notify-send; and notify-send -a Terminal "Trans-Am complete · $took" (string shorten -m 80 -- $cmd)
            else if test "$CMD_DURATION" -ge 2000
                __hud_decode "CLEAR $took" 32 4
            end
        case 130
            test "$CMD_DURATION" -ge 2000; and __hud_decode "ABORT $took" 33 4
        case '*'
            __hud_glitch "FAULT rc=$rc $took"
    end
end
