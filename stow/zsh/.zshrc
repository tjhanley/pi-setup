# History
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "$(dirname "$HISTFILE")" ]] || mkdir -p "$(dirname "$HISTFILE")"
HISTSIZE=50000
SAVEHIST=50000
setopt append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks

# Shell options
setopt auto_cd
setopt extended_glob
setopt correct

path_prepend_unique() {
  local dir="$1"
  [[ -n "$dir" && -d "$dir" ]] || return 0
  if [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
  fi
}

# CLI completions — dump to fpath before compinit so they lazy-load correctly
_comp_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$_comp_cache"

if command -v docker >/dev/null 2>&1; then
  [[ -f "$_comp_cache/_docker" ]] || docker completion zsh > "$_comp_cache/_docker"
fi
if command -v gh >/dev/null 2>&1; then
  [[ -f "$_comp_cache/_gh" ]] || gh completion -s zsh > "$_comp_cache/_gh"
fi

fpath=("$_comp_cache" $fpath)
unset _comp_cache

# zsh completion core
autoload -Uz compinit
zmodload zsh/complist
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"

# Better completion UX
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Local bin (user scripts, etc.)
path_prepend_unique "$HOME/.local/bin"

# Tool config paths
export ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# Auto-start zellij for interactive kitty shells.
# Opt out per-shell with: NO_AUTO_ZELLIJ=1 zsh
if command -v zellij >/dev/null 2>&1; then
  if [[ $- == *i* ]] && [[ -t 1 ]] && [[ "${TERM:-}" == "xterm-kitty" ]] && [[ -z "${ZELLIJ:-}" ]] && [[ -z "${TMUX:-}" ]] && [[ "${NO_AUTO_ZELLIJ:-0}" != "1" ]]; then
    exec zellij
  fi
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# zoxide smart cd
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# FZF
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
  export FZF_DEFAULT_OPTS=" \
    --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
    --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
    --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
    --color=selected-bg:#45475A \
    --color=border:#6C7086,label:#CDD6F4"
fi

# Git aliases (OMZ-style)
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch --all'
alias gc='git commit'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch'
alias gl='git pull'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias glog='git log --oneline --graph --decorate'
alias gloga='git log --oneline --graph --decorate --all'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gst='git status'
alias gsw='git switch'
alias gswc='git switch -c'

# Prefer bat over cat when available (Debian names the binary "bat")
if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat'
  alias bat='batcat'
fi

# Debian names fd-find binary "fdfind"
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi

# Dot navigation (.., ..., ....)
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias l='ls -lah'

# Editor defaults
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL="nvim"
  alias vim='nvim'
  alias vi='nvim'
fi

# eza replaces ls (if installed)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -la --group-directories-first --icons=auto --git --header --time-style=relative'
  alias la='eza -a --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto --git --git-ignore'
fi

# Common tool aliases
if command -v lazygit >/dev/null 2>&1; then
  alias lg='lazygit'
fi

if command -v zellij >/dev/null 2>&1; then
  alias zj='zellij'
  alias zja='zellij attach -c main'
fi

if command -v docker >/dev/null 2>&1; then
  alias d='docker'
fi

if command -v claude >/dev/null 2>&1; then
  alias cc='claude'
fi

# zsh plugins loaded last
for _zsh_auto in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  if [[ -f "$_zsh_auto" ]]; then
    source "$_zsh_auto"
    break
  fi
done
unset _zsh_auto

for _zsh_syntax in \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [[ -f "$_zsh_syntax" ]]; then
    source "$_zsh_syntax"
    break
  fi
done
unset _zsh_syntax
unset -f path_prepend_unique

# Machine-specific secrets and overrides (not tracked in git)
if [[ -f "$HOME/.secrets" ]]; then
  source "$HOME/.secrets"
fi
export PATH="$HOME/.npm-global/bin:$PATH"
