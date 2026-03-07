# pi-setup

Opinionated Raspberry Pi (Debian) bootstrap: apt packages + GNU Stow dotfiles + Catppuccin Mocha theming.

## Quick start

```bash
git clone git@github.com:<user>/pi-setup.git ~/Workspace/pi-setup
cd ~/Workspace/pi-setup
./setup.sh
```

Dry run (no changes):

```bash
./setup.sh --dry-run
```

## What it does

1. Installs CLI tools via apt (zsh, neovim, starship, lazygit, ripgrep, fd, fzf, bat, eza, zoxide, git-delta, btop, fastfetch, etc.)
2. Installs Ghostty terminal from debian.griffo.io repo
3. Installs Zellij from GitHub releases (aarch64 binary)
4. Stows dotfiles (zsh, git, starship, bat, eza, lazygit, ripgrep, ghostty, zellij, nvim, claude)
5. Installs LazyVim starter config
6. Sets zsh as default shell
7. Configures Claude Code settings

## Stow packages

```
stow/
  bat/          bat config
  claude/       Claude Code CLAUDE.md, settings, skills
  eza/          eza theme
  ghostty/      Ghostty terminal config
  git/          .gitconfig, .gitignore
  lazygit/      lazygit config
  nvim/         LazyVim plugin overrides
  ripgrep/      .ripgreprc
  starship/     Catppuccin Mocha powerline prompt
  zellij/       Zellij config + layouts + scripts
  zsh/          .zshrc
```

## Re-running

The bootstrap is idempotent. Re-run anytime after changes:

```bash
./setup.sh
```

Backups of existing configs are saved to `~/config-backups/` (timestamped, keeps 3 most recent).
