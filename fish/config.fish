# dap_ // d-ap.my.id — fish, ported from ~/.zshrc (neon palette, same aliases)
# fish already ships autosuggestions, syntax highlighting, and prefix history search
# on Up/Down, so there are no plugins and no plugin manager here on purpose.

set -g fish_greeting
fish_add_path -g ~/.local/bin ~/.composer/vendor/bin ~/.rbenv/bin

set -gx EDITOR vim
type -q nvim; and set -gx EDITOR nvim
set -gx BROWSER zen-browser

if status is-interactive
    # neon palette: cyan is the accent, pink only ever means an error
    set -g fish_color_command 00f0ff
    set -g fish_color_builtin 00f0ff
    set -g fish_color_keyword --bold 00f0ff
    set -g fish_color_param d6f7ff
    set -g fish_color_quote 7ffbff
    set -g fish_color_error ff2e97
    set -g fish_color_redirection 8a78b8
    set -g fish_color_operator 8a78b8
    set -g fish_color_comment 8a78b8
    set -g fish_color_autosuggestion 8a78b8
    set -g fish_color_valid_path --underline d6f7ff
    set -g fish_color_end 8a78b8
    set -g fish_pager_color_selection --background=1a1033
    set -g fish_pager_color_progress 8a78b8
    set -g fish_pager_color_prefix 00f0ff

    set -gx FZF_DEFAULT_OPTS '--height=40% --layout=reverse --border=rounded
 --color=bg+:#1a1033,fg:#d6f7ff,fg+:#ffffff,hl:#00f0ff,hl+:#00f0ff,pointer:#00f0ff,prompt:#00f0ff,info:#8a78b8,border:#8a78b8,marker:#39ff14,spinner:#fcee0a'
    type -q fzf; and fzf --fish | source

    # colored man pages
    set -gx LESS_TERMCAP_md (printf '\e[1;36m')
    set -gx LESS_TERMCAP_us (printf '\e[1;32m')
    set -gx LESS_TERMCAP_so (printf '\e[1;44;33m')
    set -gx LESS_TERMCAP_me (printf '\e[0m')
    set -gx LESS_TERMCAP_ue (printf '\e[0m')
    set -gx LESS_TERMCAP_se (printf '\e[0m')

    # replacements stay aliases: they must work inside scripts' muscle memory and pipes
    alias ls 'eza --icons --group-directories-first'
    alias ll 'eza -l --icons --git --group-directories-first'
    alias la 'eza -la --icons --git'
    alias tree 'eza --tree --icons'
    alias cat 'bat --paging=never --theme=ansi'
    alias grep rg
    alias top btop
    alias gpu nvtop
    alias dgpu prime-run
    alias agy 'agy --dangerously-skip-permissions'
    alias rm 'rm -i'
    alias cp 'cp -i'
    alias mv 'mv -i'

    # everything else is an abbreviation: it expands on screen, so history and
    # copy-paste keep the real command and you learn what you are running
    abbr -a gs git status -sb
    abbr -a gl git log --oneline --graph --decorate -15
    abbr -a clone git clone
    abbr -a install yay -S --needed
    abbr -a remove yay -Rns
    abbr -a search yay -Ss
    abbr -a ribut systemctl reboot
    abbr -a matikan systemctl poweroff
    abbr -a keluar hyprctl dispatch exit
    abbr -a lock loginctl lock-session
    abbr -a copy wl-copy
    abbr -a paste wl-paste
    abbr -a open xdg-open
    abbr -a c code
    abbr -a .c code .
    abbr -a cls clear
    abbr -a dev cd ~/lab
    abbr -a owl agy
    abbr -a sonic claude
    abbr -a ys yarn start
    abbr -a yd yarn dev
    abbr -a yb yarn build
    abbr -a pd pnpm dev
    abbr -a pb pnpm build
    abbr -a allahuakbar npm run dev
    abbr -a rs bin/rails server
    abbr -a rc bin/rails console
    abbr -a rd bin/dev
    abbr -a tuttut bin/dev
    abbr -a dbm bin/rails db:migrate
    abbr -a dbr bin/rails db:rollback
    abbr -a b bundle exec
    abbr -a pa php artisan
    abbr -a pas php artisan serve
    abbr -a pam php artisan migrate
    abbr -a fresh php artisan migrate:fresh --seed
    abbr -a tinker php artisan tinker

    type -q zoxide; and zoxide init fish --cmd cd | source
    type -q starship; and starship init fish | source
    type -q direnv; and direnv hook fish | source
    type -q mise; and mise activate fish | source

    # new terminal opened in $HOME starts in ~/lab; any other start dir is kept
    test "$PWD" = "$HOME"; and builtin cd ~/lab

    # flex on shell start (same as zsh)
    if not set -q NOFETCH
        if functions -q hud_boot
            hud_boot
        else
            fastfetch
        end
    end
end

function update --description 'yay -Syu, then flatpak if installed'
    yay -Syu; or return
    type -q flatpak; and flatpak update -y
end

# Unattended: --noconfirm takes the default answer on every prompt, including package replacements.
function upgrade --description 'yay -Syu --noconfirm (repos + AUR), then flatpak if installed'
    yay -Syu --noconfirm; or return
    type -q flatpak; and flatpak update -y
end

function pacclean --description 'remove orphaned packages'
    set -l orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -gt 0
        sudo pacman -Rns $orphans
    else
        echo "no orphaned packages"
    end
end
abbr -a autoremove pacclean
