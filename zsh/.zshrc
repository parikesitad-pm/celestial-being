# dap_ // d-ap.my.id — zsh without a framework (fast startup)
HISTFILE=~/.zsh_history; HISTSIZE=50000; SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS AUTO_CD INTERACTIVE_COMMENTS
setopt HIST_IGNORE_SPACE EXTENDED_HISTORY AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT NO_CASE_GLOB

typeset -U path PATH   # drop duplicate PATH entries
export PATH="$HOME/.local/bin:$HOME/.composer/vendor/bin:$HOME/.rbenv/bin:$PATH"

# colored man pages / less
export LESS_TERMCAP_mb=$'\E[1;31m' LESS_TERMCAP_md=$'\E[1;36m' LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m' LESS_TERMCAP_so=$'\E[1;44;33m' LESS_TERMCAP_ue=$'\E[0m' LESS_TERMCAP_us=$'\E[1;32m'
export EDITOR=nvim; command -v nvim >/dev/null || export EDITOR=vim
export BROWSER=zen-browser

# completion
fpath=(/usr/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# plugins (pacman packages)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#5b4a86'
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_HIGHLIGHT_STYLES[command]='fg=#00f0ff'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#00f0ff'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#39ff14'
ZSH_HIGHLIGHT_STYLES[path]='fg=#fcee0a,underline'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ff2e97'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#fcee0a'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#fcee0a'

# fzf in neon
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border=rounded
 --color=bg+:#1a1033,fg:#d6f7ff,fg+:#ffffff,hl:#ff2e97,hl+:#ff2e97,pointer:#00f0ff,prompt:#00f0ff,info:#9d4edd,border:#9d4edd,marker:#39ff14,spinner:#fcee0a'
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ]   && source /usr/share/fzf/completion.zsh

# modern replacements
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --git --group-directories-first'
alias la='eza -la --icons --git'
alias tree='eza --tree --icons'
alias cat='bat --paging=never --theme=ansi'
alias grep='rg'
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -15'
alias gpu='nvtop'
alias top='btop'
alias dgpu='prime-run'      # run an app on the NVIDIA GPU: dgpu <app>
alias rm='rm -i' cp='cp -i' mv='mv -i'
alias cls='clear'

# packages (pacman + AUR via yay; flatpak only if installed)
update() { yay -Syu && { command -v flatpak >/dev/null && flatpak update -y; return 0; }; }
# Unattended: --noconfirm takes the default answer on every prompt, including package replacements.
upgrade() { yay -Syu --noconfirm && { command -v flatpak >/dev/null && flatpak update -y; return 0; }; }
alias install='yay -S --needed'
alias remove='yay -Rns'
alias search='yay -Ss'
pacclean() {
  local orphans; orphans=(${(f)"$(pacman -Qtdq 2>/dev/null)"})
  (( $#orphans )) && sudo pacman -Rns "${orphans[@]}" || echo "no orphaned packages"
}
alias autoremove='pacclean'

# session (Hyprland / Wayland)
alias ribut='systemctl reboot'
alias matikan='systemctl poweroff'
alias keluar='hyprctl dispatch exit'
alias lock='loginctl lock-session'
alias copy='wl-copy' paste='wl-paste' open='xdg-open'
alias c='code' .c='code .'
alias clone='git clone'
alias dev='cd ~/Lab'
alias owl='agy' sonic='claude'

# JS / Rails / Laravel shortcuts
alias ys='yarn start' yd='yarn dev' yb='yarn build' pd='pnpm dev' pb='pnpm build'
alias allahuakbar='npm run dev'
alias rs='bin/rails server' rc='bin/rails console' rd='bin/dev' tuttut='bin/dev'
alias dbm='bin/rails db:migrate' dbr='bin/rails db:rollback' b='bundle exec'
alias pa='php artisan' pas='php artisan serve' pam='php artisan migrate'
alias fresh='php artisan migrate:fresh --seed' tinker='php artisan tinker'

command -v direnv >/dev/null && eval "$(direnv hook zsh)"
# nvm only if installed; lazy so it costs nothing at startup
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  export NVM_DIR="$HOME/.nvm"
  nvm() { unset -f nvm; . "$NVM_DIR/nvm.sh"; nvm "$@"; }
fi

eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"

# Cockpit HUD, same as the fish one: each command decodes out of noise before it runs, and
# finished commands get a debrief. Ghostty and kitty only; NOANIM=1 keeps plain lines.
if [[ -o interactive && ( $TERM == xterm-ghostty || $TERM == xterm-kitty ) ]]; then
  zmodload zsh/datetime
  _hud_tuis=(nvim vim vi nano less more man claude agy btop top htop nvtop ssh fzf tmux lazygit yazi watch clear cls)
  _hud_animates() { [[ -z $NOANIM && -z $SSH_CONNECTION && -t 1 ]] }
  _hud_decode() {  # text sgr frames
    local text=${1[1,$((COLUMNS - 1))]} sgr=$2 frames=$3
    if ! _hud_animates; then printf '\e[%sm%s\e[0m\n' $sgr "$text"; return; fi
    local noise=(▓ ▒ ░ '#' % '&' @ '$' = + 0 1) n=${#text} f i front hot_from hot
    printf '\e[?25l'
    for (( f = 1; f <= frames; f++ )); do
      front=$(( n * (1 - 2 ** (-8.0 * f / frames)) )); front=${front%.*}
      hot_from=$(( front > 6 ? front - 6 : 0 )); hot=
      for (( i = hot_from + 1; i <= front; i++ )); do hot+=${noise[(i * 7 + f * 13) % ${#noise} + 1]}; done
      printf '\r\e[K\e[%sm%s\e[90m%s\e[%sm█\e[0m' $sgr "${text[1,hot_from]}" "$hot" $sgr
      sleep 0.033
    done
    printf '\r\e[K\e[%sm%s\e[0m\n\e[?25h' $sgr "$text"
  }
  # Red/cyan channel split that jitters, then settles red: a fault you notice.
  _hud_glitch() {
    local text=${1[1,$((COLUMNS - 1))]} noise=(▓ ▒ ░ '#' 0 1) f torn
    if ! _hud_animates; then printf '\e[31m%s\e[0m\n' "$text"; return; fi
    printf '\e[?25l'
    for (( f = 1; f <= 5; f++ )); do
      torn=${${text[1,6]}//[A-Za-z0-9]/${noise[f % ${#noise} + 1]}}
      if (( f % 2 )); then printf '\r\e[K \e[36m%s%s\e[0m' "$torn" "${text[7,-1]}"
      else printf '\r\e[K\e[31m%s%s\e[0m' "$torn" "${text[7,-1]}"; fi
      sleep 0.033
    done
    printf '\r\e[K\e[1;31m%s\e[0m\n\e[?25h' "$text"
  }
  _hud_stripe() {
    local width=$(( COLUMNS - 1 < 48 ? COLUMNS - 1 : 48 )) stripe=${(l:48::◤◢:)}
    stripe=${stripe[1,width]}
    if _hud_animates; then
      local s; for s in 4 2; do printf '\r\e[33m%s\e[0m' "${stripe[1,$((width / s))]}"; sleep 0.033; done
    fi
    printf '\r\e[K\e[33m%s\e[0m\n' "$stripe"
  }
  _hud_launch() {
    emulate -L zsh -o extendedglob
    local cmd=${1##[[:space:]]#}
    _hud_cmd=$cmd; _hud_t0=$EPOCHREALTIME
    [[ -z $cmd || ${_hud_tuis[(Ie)${cmd%% *}]} -ne 0 ]] && { _hud_cmd=; return }
    local shown=${cmd[1,$((COLUMNS > 40 ? COLUMNS - 32 : 8))]}
    # Loud only where it matters: elevated access and pushes are rare; everything else stays quick.
    if [[ $cmd == (sudo|doas|run0)(| *) ]]; then
      _hud_stripe; _hud_decode "WARNING // ELEVATED ACCESS » $shown" "1;33" 6
    elif [[ $cmd == git[[:space:]]##push(| *) ]]; then
      _hud_decode "GN DRIVE // EXIA LAUNCH » $shown" "1;32" 6
    else
      _hud_decode "» ${cmd[1,$((COLUMNS - 4))]}" 36 5
    fi
  }
  _hud_debrief() {
    local rc=$?
    [[ -z $_hud_cmd ]] && return
    local ms=$(( int((EPOCHREALTIME - _hud_t0) * 1000) )) cmd=$_hud_cmd took
    _hud_cmd=
    took="$(( ms / 1000 )).$(( ms % 1000 / 100 ))s"
    (( ms >= 60000 )) && took="$(( ms / 60000 ))m$(( ms % 60000 / 1000 ))s"
    case $rc in
      0)
        if (( ms >= 30000 )); then
          _hud_decode "TRANS-AM COMPLETE // $took" "1;31" 7
          # Long jobs ping the island, so you can look away while they run.
          (( $+commands[notify-send] )) && notify-send -a Terminal "Trans-Am complete · $took" "${cmd[1,80]}"
        elif (( ms >= 2000 )); then
          _hud_decode "CLEAR $took" 32 4
        fi ;;
      130) (( ms >= 2000 )) && _hud_decode "ABORT $took" 33 4 ;;
      *) _hud_glitch "FAULT rc=$rc $took" ;;
    esac
  }
  zmodload zsh/mathfunc
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec _hud_launch
  # First in line: later precmd hooks (starship) would overwrite $? before we read it.
  precmd_functions=(_hud_debrief ${precmd_functions[@]})
fi

# flex on shell start
[[ -o interactive && -z "$NOFETCH" ]] && fastfetch


# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"

# dev runtimes (node, ruby) managed by mise
command -v mise >/dev/null && eval "$(mise activate zsh)"

# agy: auto-approve every tool permission (pilot's call)
alias agy='agy --dangerously-skip-permissions'
