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
- **Git Commit Signing**: Native SSH signing via `~/.ssh/id_ed25519.pub`

### Core Configuration Files

- **`.zshrc`** - Main shell configuration, history settings, Antidote bundle loading, Starship prompt initialization, fnm, zoxide, fzf, and PATH
- **`.zsh_plugins.txt`** - Antidote plugin list
- **`.gitconfig`** - Git global settings with SSH signing, delta pager, and modern merge/rebase defaults
- **`.gitignore_global`** - Global gitignore for OS and editor artifacts
- **`starship.toml`** - Starship prompt configuration (Pure/minimalist style)
- **`Brewfile`** - Homebrew package manifest for automated installation
- **`.tokens.zsh`** - Environment tokens and secrets (excluded from git, optional)

### Shell Configuration Load Order (`.zshrc`)

1. Environment PATHs (`$HOME/.local/bin`, `$HOME/bin`, OpenJDK)
2. History configuration (shared, timestamped, deduplicated)
3. Homebrew environment setup
4. Zsh compinit and Antidote plugin bundle sourcing
5. Starship prompt initialization
6. FNM automatic directory hook (`fnm env --use-on-cd`)
7. Zoxide and FZF shell integrations
8. Custom git aliases, modern CLI aliases (`eza`, `bat`, `dust`), and editor settings

## Development Commands

### Package Management

```bash
# Install all Homebrew packages from Brewfile
brew bundle --file ~/.dotfiles/Brewfile

# Update Homebrew, casks, and Antidote plugins
./update.sh

# Show disk usage (excludes git and node_modules)
dus
```

### Git Aliases (defined in .zshrc)

- `gc` - Commitizen commit (interactive commit message)
- `ga` - Git add
- `gco` - Git checkout
- `gp` - Git push
- `gl` - Git pull with rebase
- `glc` - Copy current commit hash to clipboard

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

Custom git log alias defined in `.gitconfig`:
```bash
git lg  # Pretty graph log with colors and author info
```

Git configuration includes:
- Native SSH commit signing via `~/.ssh/id_ed25519.pub`
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

Configuration files live in `~/.dotfiles/` and are symlinked to home directory:
```bash
ln -s ~/.dotfiles/.zshrc ~/.zshrc
ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
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

## Cursor IDE Rules

This repository uses modern `.mdc` format rules in `.cursor/rules/`:

- **`dotfiles-context.mdc`** - Repository context and structure (always applied)
- **`icloud-calendar-timing.mdc`** - AppleScript calendar event creation best practices
- **`mdc-rule-creation.mdc`** - Guidelines for creating new Cursor rules

## macOS-Specific Notes

- Uses Homebrew for package management (`/opt/homebrew` on Apple Silicon)
- Requires Xcode Command Line Tools
- Git credential helper uses `osxkeychain`
- Default editor set to VS Code with `--wait` flag