#!/bin/bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Workspace/pi-setup}"
STOW_DIR="$DOTFILES_DIR/stow"
BACKUP_DIR="${BACKUP_DIR:-$HOME/config-backups/dotfiles-$(date +%Y%m%d-%H%M%S)}"
DRY_RUN=0

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

log()  { printf '\n\033[36m==>\033[0m %s\n' "$1"; }
ok()   { printf '\033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '\033[33m⚠\033[0m %s\n' "$1"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[33mdry-run:\033[0m %s\n' "$*"
    return 0
  fi
  "$@"
}

backup_path() {
  local p="$1"
  if [[ -e "$p" || -L "$p" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '\033[33mdry-run:\033[0m backup %s -> %s/\n' "$p" "$BACKUP_DIR"
    else
      mkdir -p "$BACKUP_DIR"
      cp -a "$p" "$BACKUP_DIR/" 2>/dev/null || true
      ok "Backed up: $p -> $BACKUP_DIR/"
    fi
  fi
}

move_conflict_target() {
  local rel="$1"
  local target="$HOME/$rel"
  local dest="$BACKUP_DIR/$rel"

  if [[ -L "$target" || ! -e "$target" ]]; then
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[33mdry-run:\033[0m move conflict %s -> %s\n' "$target" "$dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  mv "$target" "$dest"
  ok "Moved conflict: $target -> $dest"
}

install_apt_packages() {
  log "Installing packages via apt"

  local -a packages=(
    zsh
    stow
    neovim
    git-delta
    starship
    lazygit
    ripgrep
    fd-find
    fzf
    bat
    jq
    zoxide
    eza
    btop
    wget
    fastfetch
    zsh-autosuggestions
    zsh-syntax-highlighting
  )

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[33mdry-run:\033[0m sudo apt install %s\n' "${packages[*]}"
    return
  fi

  sudo apt update
  sudo apt install -y "${packages[@]}"
  ok "apt packages installed"
}

install_kitty() {
  log "Installing Kitty terminal"

  if need_cmd kitty; then
    ok "Kitty already installed"
  else
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '\033[33mdry-run:\033[0m sudo apt install kitty\n'
    else
      sudo apt install -y kitty
      ok "Kitty installed"
    fi
  fi

  # Set Kitty as the default terminal emulator
  if command -v update-alternatives >/dev/null 2>&1 && [[ -x /usr/bin/kitty ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '\033[33mdry-run:\033[0m set kitty as default terminal\n'
    else
      sudo update-alternatives --set x-terminal-emulator /usr/bin/kitty
      ok "Kitty set as default terminal"
    fi
  fi
}

install_zellij() {
  log "Installing Zellij"

  if need_cmd zellij; then
    ok "Zellij already installed"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[33mdry-run:\033[0m download zellij aarch64 binary to ~/.local/bin\n'
    return
  fi

  mkdir -p "$HOME/.local/bin"
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/zellij.tar.gz" \
    "https://github.com/zellij-org/zellij/releases/latest/download/zellij-aarch64-unknown-linux-musl.tar.gz"
  tar -xzf "$tmp/zellij.tar.gz" -C "$tmp"
  install -m 755 "$tmp/zellij" "$HOME/.local/bin/zellij"
  rm -rf "$tmp"
  ok "Zellij installed to ~/.local/bin/zellij"
}

install_zjstatus() {
  log "Installing zjstatus (Zellij status bar plugin)"

  local plugins_dir="$HOME/.config/zellij/plugins"
  local wasm_path="$plugins_dir/zjstatus.wasm"

  if [[ -f "$wasm_path" ]]; then
    ok "zjstatus already installed"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[33mdry-run:\033[0m download zjstatus.wasm -> %s\n' "$wasm_path"
    return
  fi

  mkdir -p "$plugins_dir"
  if curl -fsSL -o "$wasm_path" \
    "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm"; then
    ok "zjstatus installed at $wasm_path"
  else
    warn "Failed to download zjstatus.wasm"
  fi
}

ensure_config_dir() {
  log "Ensuring ~/.config exists"
  run_cmd mkdir -p "$HOME/.config"
  ok "~/.config ready"
}

stow_dotfiles() {
  log "Backing up pre-existing configs"
  backup_path "$HOME/.zshrc"
  backup_path "$HOME/.zprofile"
  backup_path "$HOME/.gitconfig"
  backup_path "$HOME/.gitignore"
  backup_path "$HOME/.ripgreprc"
  backup_path "$HOME/.config/bat"
  backup_path "$HOME/.config/lazygit"
  backup_path "$HOME/.config/nvim"
  backup_path "$HOME/.config/starship.toml"
  backup_path "$HOME/.config/eza"
  backup_path "$HOME/.claude/settings.json"
  backup_path "$HOME/.config/kitty"
  backup_path "$HOME/.config/zellij"

  log "Moving stow conflicts into backup"
  move_conflict_target ".zshrc"
  move_conflict_target ".zprofile"
  move_conflict_target ".gitconfig"
  move_conflict_target ".gitignore"
  move_conflict_target ".ripgreprc"
  move_conflict_target ".config/bat/config"
  move_conflict_target ".config/lazygit/config.yml"
  move_conflict_target ".config/starship.toml"
  move_conflict_target ".config/eza/theme.yml"
  move_conflict_target ".claude/settings.json"
  move_conflict_target ".config/kitty/kitty.conf"
  move_conflict_target ".config/zellij/config.kdl"

  log "Stowing dotfiles"
  if [[ ! -d "$STOW_DIR" ]]; then
    warn "Missing stow dir at: $STOW_DIR"
    return
  fi

  # nvim is stowed separately after LazyVim install
  if ! need_cmd stow; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '\033[33mdry-run:\033[0m stow all packages (stow not yet installed)\n'
      ok "Dotfiles stowed"
      return
    fi
    warn "stow not found; cannot stow dotfiles"
    return
  fi

  local -a stow_args=(--target="$HOME" --restow)
  [[ "$DRY_RUN" -eq 1 ]] && stow_args+=(-n)

  (cd "$STOW_DIR" && for pkg in */; do
    [[ "$pkg" == "nvim/" ]] && continue
    stow "${stow_args[@]}" "$pkg" || true
  done)

  ok "Dotfiles stowed"
}

configure_claude_settings() {
  log "Configuring Claude Code settings"

  local settings="$HOME/.claude/settings.json"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[33mdry-run:\033[0m merge statusLine into %s\n' "$settings"
    return
  fi

  mkdir -p "$HOME/.claude"
  [[ -f "$settings" ]] || echo '{}' > "$settings"

  local tmp
  tmp=$(mktemp)
  jq '.statusLine = {"type": "command", "command": "~/.claude/statusline.sh"}' "$settings" > "$tmp" \
    && mv "$tmp" "$settings"

  ok "Claude Code statusLine configured"
}

stow_nvim_plugins() {
  log "Stowing Neovim plugin configs"

  if [[ ! -d "$STOW_DIR/nvim" ]]; then
    warn "No nvim stow package found; skipping"
    return
  fi

  move_conflict_target ".config/nvim/lua/config/keymaps.lua"

  if ! need_cmd stow; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '\033[33mdry-run:\033[0m stow nvim package (stow not yet installed)\n'
      ok "Neovim plugins stowed"
      return
    fi
    warn "stow not found; cannot stow nvim"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    if ! (cd "$STOW_DIR" && stow --target="$HOME" --restow -n nvim); then
      warn "Neovim stow check found unresolved conflicts"
      return
    fi
  else
    if ! (cd "$STOW_DIR" && stow --target="$HOME" --restow nvim); then
      warn "Neovim plugin stow failed due to unresolved conflicts"
      return
    fi
  fi

  ok "Neovim plugins stowed"
}

install_lazyvim() {
  log "Installing LazyVim (if not already installed)"

  local nvim_dir="$HOME/.config/nvim"
  if [[ -d "$nvim_dir/.git" ]]; then
    ok "Neovim config already looks like a git repo: $nvim_dir"
    return
  fi

  if [[ -e "$nvim_dir" && ! -L "$nvim_dir" ]]; then
    warn "$nvim_dir exists and is not a symlink. Leaving it alone."
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[33mdry-run:\033[0m git clone LazyVim starter -> %s\n' "$nvim_dir"
  else
    git clone https://github.com/LazyVim/starter "$nvim_dir"
    rm -rf "$nvim_dir/.git"
    ok "LazyVim starter installed at ~/.config/nvim"
  fi

  warn "Open nvim once to let plugins install: nvim"
}

ensure_lazyvim_local_options_hook() {
  log "Ensuring LazyVim local options hook"

  local options_file="$HOME/.config/nvim/lua/config/options.lua"
  local hook='pcall(require, "config.local")'

  if [[ ! -f "$options_file" ]]; then
    warn "LazyVim options file not found; skipping local options hook"
    return
  fi

  if grep -Fq "$hook" "$options_file"; then
    ok "LazyVim local options hook already configured"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[33mdry-run:\033[0m append local options hook to %s\n' "$options_file"
    return
  fi

  cat >> "$options_file" <<'EOF'

-- Load local/repo-managed options if present.
pcall(require, "config.local")
EOF

  ok "Added LazyVim local options hook"
}

ensure_lazyvim_extras() {
  local lazyvim_json="$HOME/.config/nvim/lazyvim.json"
  if [[ ! -f "$lazyvim_json" ]]; then
    return
  fi

  log "Ensuring LazyVim extras"

  local -a desired_extras=(
    "lazyvim.plugins.extras.ai.claudecode"
  )

  local changed=0
  for extra in "${desired_extras[@]}"; do
    if ! grep -q "\"$extra\"" "$lazyvim_json"; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '\033[33mdry-run:\033[0m add %s to lazyvim.json\n' "$extra"
      else
        sed -i "s|\"extras\": \[|\"extras\": [\n    \"$extra\",|" "$lazyvim_json"
        changed=1
      fi
    fi
  done

  if [[ "$changed" -eq 1 ]]; then
    ok "LazyVim extras updated"
  else
    ok "LazyVim extras already configured"
  fi
}

ensure_git_identity() {
  log "Checking git user identity"

  local local_config="$HOME/.gitconfig.local"
  local current_name=""
  local current_email=""
  current_name="$(git config user.name 2>/dev/null || true)"
  current_email="$(git config user.email 2>/dev/null || true)"

  if [[ -n "$current_name" && -n "$current_email" ]]; then
    ok "git identity already set: $current_name <$current_email>"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    [[ -z "$current_name" ]]  && printf '\033[33mdry-run:\033[0m would prompt for git user.name\n'
    [[ -z "$current_email" ]] && printf '\033[33mdry-run:\033[0m would prompt for git user.email\n'
    return
  fi

  if [[ -z "$current_name" ]]; then
    printf '\033[36mNo git user.name configured.\033[0m\n'
    printf 'Enter your git name (or press Enter to skip): '
    local name=""
    read -r name
    if [[ -n "$name" ]]; then
      if [[ ! -f "$local_config" ]]; then
        printf '[user]\n  name = %s\n' "$name" > "$local_config"
      else
        git config --file "$local_config" user.name "$name"
      fi
      ok "git user.name set to $name (in ~/.gitconfig.local)"
    else
      warn "Skipped git user.name"
    fi
  fi

  if [[ -z "$current_email" ]]; then
    printf '\033[36mNo git user.email configured.\033[0m\n'
    printf 'Enter your git email (or press Enter to skip): '
    local email=""
    read -r email
    if [[ -n "$email" ]]; then
      if [[ ! -f "$local_config" ]]; then
        printf '[user]\n  email = %s\n' "$email" > "$local_config"
      else
        git config --file "$local_config" user.email "$email"
      fi
      ok "git user.email set to $email (in ~/.gitconfig.local)"
    else
      warn "Skipped git user.email"
    fi
  fi
}

set_default_shell() {
  log "Setting default shell to zsh"

  if [[ "$SHELL" == */zsh ]]; then
    ok "Default shell is already zsh"
    return
  fi

  local zsh_path
  zsh_path="$(command -v zsh || true)"

  if [[ -z "$zsh_path" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '\033[33mdry-run:\033[0m chsh -s /usr/bin/zsh (zsh not yet installed)\n'
      return
    fi
    warn "zsh not found; skipping shell change"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[33mdry-run:\033[0m chsh -s %s\n' "$zsh_path"
    return
  fi

  sudo chsh -s "$zsh_path" "$USER"
  ok "Default shell set to $zsh_path (takes effect on next login)"
}

prune_old_backups() {
  local backup_parent="$HOME/config-backups"
  local keep=3

  [[ -d "$backup_parent" ]] || return 0

  local -a all_backups=()
  while IFS= read -r -d '' dir; do
    all_backups+=("$dir")
  done < <(find "$backup_parent" -maxdepth 1 -name 'dotfiles-*' -type d -print0 | sort -rz)

  (( ${#all_backups[@]} <= keep )) && return 0

  log "Pruning old backups (keeping $keep most recent)"

  local i
  for (( i=keep; i<${#all_backups[@]}; i++ )); do
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '\033[33mdry-run:\033[0m rm -rf %s\n' "${all_backups[$i]}"
    else
      rm -rf "${all_backups[$i]}"
      ok "Removed ${all_backups[$i]}"
    fi
  done
}

post_notes() {
  log "Next steps"
  cat <<'EOF'

- Log out and back in (or run: exec zsh) to use zsh as your shell.
- Open nvim once to let plugins install.
- Re-run this script anytime; it's safe and idempotent.
- Backups are in ~/config-backups/ (timestamped).

EOF
}

main() {
  log "Bootstrap starting"
  ok "Repo: $DOTFILES_DIR"

  install_apt_packages
  install_kitty
  install_zellij
  ensure_config_dir

  stow_dotfiles
  configure_claude_settings
  install_zjstatus
  ensure_git_identity
  install_lazyvim
  ensure_lazyvim_local_options_hook
  stow_nvim_plugins
  ensure_lazyvim_extras
  set_default_shell
  prune_old_backups
  post_notes

  ok "Bootstrap finished"
}

main "$@"
