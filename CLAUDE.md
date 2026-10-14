# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **macOS dotfiles repository** for bootstrapping development environments. The repository is completely **submodule-free**, using **fnm** for fast Node.js management, **uv** for fast Python management, **Antidote** for static Zsh plugin bundling, and **Starship** for the prompt.

**Key Purpose**: Automate macOS development setup with reproducible configuration for shell, prompt, plugin management, and development tools via Homebrew.

## Architecture

### Package & Runtime Architecture

- **Node.js**: Managed via `fnm` (Fast Node Manager in Rust)
- **Python**: Managed via `uv` (Astral's fast Python manager)
- **Zsh Plugins**: Managed statically via `antidote` from `.zsh_plugins.txt`
- **Prompt**: Managed via `starship` from `starship.toml`
- **Git Identity & Signing**: Per-user `~/.gitconfig` generated from the GitHub account by `scripts/setup-git-identity.sh`; SSH signing with `~/.ssh/id_ed25519.pub`

### Core Configuration Files

- **`.zshrc`** - Main shell configuration, history settings, Antidote bundle loading, Starship prompt initialization, fnm, zoxide, fzf, and PATH
- **`.zsh_plugins.txt`** - Antidote plugin list
- **`git/config`** - Shared Git settings (delta pager, SSH signing format, merge/rebase/diff defaults), linked to `~/.config/git/config`. Never put identity here.
- **`git/ignore`** - Global gitignore for OS and editor artifacts, linked to `~/.config/git/ignore`
- **`starship.toml`** - Starship prompt configuration (Pure/minimalist style)
- **`Brewfile`** - Homebrew package manifest for automated installation
- **`.tokens.zsh`** - Environment tokens and secrets (excluded from git, optional)

### Shell Configuration Load Order (`.zshrc`)

1. Unique PATH/fpath arrays and Homebrew environment (Apple Silicon or Intel)
2. History configuration (shared, timestamped, deduplicated)
3. Completion cache directory, compinit, and completion styles
4. Atomic Antidote bundle regeneration when the manifest changes
5. Starship, fnm, Cargo/espup, zoxide, and fzf integrations
6. Tokens, aliases, and editor settings
7. Antidote bundle sourcing: Git helper library, Git aliases, autosuggestions, then syntax highlighting

Plugin bundle generation lives in `scripts/bundle-plugins.zsh`; both startup and `update.sh` use it. Failed, empty, or syntactically invalid output must preserve the previous cache and report failure. Use `python3 tests/test_shell.py` for isolated integration checks and `python3 scripts/benchmark-shell.py` to measure initialization (not prompt rendering).

## Development Commands

### Package Management

```bash
# Install all Homebrew packages from Brewfile
brew bundle -g    # HOMEBREW_BUNDLE_FILE_GLOBAL points at ~/.dotfiles/Brewfile

# Add a package to the Brewfile, then install it
brew bundle add -g <name> && brew bundle -g

# Bootstrap a new Mac (Homebrew, symlinks, Brewfile); safe to rerun
./install.sh

# Sync Homebrew with Brewfile (install/upgrade/cleanup), update Antidote plugins, uv tools and rustup
./update.sh

# Show disk usage (excludes git and node_modules)
dus
```

### Git Aliases

Standard aliases (`gc`, `ga`, `gco`, `gp`, `gl`, ...) come from the Oh My Zsh git plugin loaded via Antidote. `gl` rebases because `pull.rebase = true`.

- `glc` - Copy current commit hash to clipboard (defined in .zshrc)

### Version Management

**Node.js (fnm)**:
- Install Node version: `fnm install 22` or `fnm install --lts`
- Set default: `fnm default 22`
- Auto-switches Node version when `.nvmrc` or `.node-version` present in directory

**Python (uv)**:
- Install Python versions: `uv python install 3.12`
- Run scripts: `uv run <script.py>`
- Create virtual environments: `uv venv`
- Pin directory version: `uv python pin <version>` (writes `.python-version`)

### Git Configuration

Custom git log alias defined in `git/config`:
```bash
git lg  # Pretty graph log with colors and author info
```

Git configuration includes:
- `user.useConfigOnly = true`: commits fail until a personal identity exists
- Native SSH commit signing; key, `commit.gpgSign` and identity live in the untracked personal `~/.gitconfig`, which overrides `git/config`
- Delta syntax-highlighting pager
- Auto-setup remote on push
- Sort branches by commit date
- `rerere.enabled = true` (Reuse Recorded Resolution)
- `merge.conflictstyle = zdiff3`
- `rebase.autoStash = true`
- `fetch.prune = true`
- Git LFS support

## Important Patterns

### Symlink Structure

Configuration files live in `~/.dotfiles/` (the path is required) and `install.sh` symlinks them into place. `.zshrc` is the only Zsh startup file. The repository is meant to be forked per person:
```bash
ln -s ~/.dotfiles/.zshrc ~/.zshrc
ln -s ~/.dotfiles/git/config ~/.config/git/config
ln -s ~/.dotfiles/git/ignore ~/.config/git/ignore
```

### Environment-Specific Files

- `.tokens.zsh` - Contains environment tokens and API keys (git-ignored)

## AppleScript Calendar Integration

When creating iCloud Calendar events via AppleScript:

**Always use explicit date format**: `DD/MM/YYYY HH:MM:SS`

```applescript
# Correct approach
osascript -e 'tell application "Calendar" to tell calendar "CalendarName" to make new event with properties {summary:"Title", start date:date "31/05/2025 09:00:00", end date:date "31/05/2025 10:00:00"}'
```

**Never use relative time calculations** like `(current date) + (2 * days)` - these cause timezone and timing issues.

## macOS-Specific Notes

- Uses Homebrew for package management (`/opt/homebrew` on Apple Silicon)
- Requires Xcode Command Line Tools
- Git credential helper uses `osxkeychain`
- Default editor (shell and Git) set to `code --wait --reuse-window`
- Anything installed outside the Brewfile is removed by `update.sh`, so add new tools with `brew bundle add -g`