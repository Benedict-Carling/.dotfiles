# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **macOS dotfiles repository** for bootstrapping development environments. The repository uses **git submodules** extensively to manage external dependencies like shell enhancements and version managers.

**Key Purpose**: Automate macOS development setup with reproducible configuration for shell, version managers (Node.js/Python), and development tools via Homebrew.

## Architecture

### Git Submodules Structure

This repository heavily relies on git submodules for external dependencies. These are **not custom code** but external tools:

- `nvm/` - Node Version Manager for Node.js version management
- `pyenv/` - Python version management tool
- `ohmyzsh/` - Oh My Zsh framework for zsh configuration
- `powerlevel10k/` - Fast zsh theme with git integration
- `zsh-autosuggestions/` - Fish-like command suggestions for zsh
- `zsh-syntax-highlighting/` - Syntax highlighting for zsh commands

### Core Configuration Files

- **`.zshrc`** - Main shell configuration, sources all submodules and sets up PATH
- **`.gitconfig`** - Git global settings with custom aliases and GPG configuration
- **`.p10k.zsh`** - Powerlevel10k theme configuration
- **`Brewfile`** - Homebrew package manifest for automated installation
- **`.signingkey.gitconfig`** - GPG signing key (excluded from git, user-created)
- **`.tokens.zsh`** - Environment tokens and secrets (excluded from git, optional)

### Shell Configuration Load Order (`.zshrc`)

1. Poetry and Java added to PATH
2. NVM initialization from submodule
3. GPG_TTY export for commit signing
4. Powerlevel10k instant prompt
5. Homebrew environment setup
6. Oh My Zsh initialization with plugins
7. zsh-autosuggestions and zsh-syntax-highlighting
8. PYENV initialization
9. NVM auto-switch on directory change
10. Custom git aliases and editor settings

## Development Commands

### Package Management

```bash
# Install all Homebrew packages from Brewfile
brew bundle --file ~/.dotfiles/Brewfile

# Update Homebrew casks
brew cu

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

**Node.js (nvm)**:
- Managed via submodule at `~/.dotfiles/nvm`
- Auto-switches Node version when `.nvmrc` present in directory
- Load manually: `nvm use`

**Python (pyenv)**:
- Managed via submodule at `~/.dotfiles/pyenv`
- Set version: `pyenv local <version>` or `pyenv global <version>`
- List versions: `pyenv versions`

### Git Configuration

Custom git log alias defined in `.gitconfig`:
```bash
git lg  # Pretty graph log with colors and author info
```

Git configuration includes:
- Auto-setup remote on push
- Pull without rebase by default
- Sort branches by commit date
- GPG signing (requires `.signingkey.gitconfig` setup)
- Git LFS support

## Important Patterns

### Symlink Structure

Configuration files live in `~/.dotfiles/` and are symlinked to home directory:
```bash
ln -s ~/.dotfiles/.zshrc ~/.zshrc
ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
```

### Submodule Management

When updating submodules:
```bash
# Update all submodules to latest
git submodule update --remote --merge

# Clone with submodules
git clone --recurse-submodules <repo-url>
```

### Environment-Specific Files

Two files are git-ignored but may be present:
- `.signingkey.gitconfig` - Contains GPG signing key ID (see `.example.signingkey.gitconfig`)
- `.tokens.zsh` - Contains environment tokens and API keys

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

When creating new Cursor rules, always use `.mdc` format in `.cursor/rules/` directory, never `.cursorrules` in project root (deprecated).

## macOS-Specific Notes

- Uses Homebrew for package management (`/opt/homebrew` on Apple Silicon)
- Requires Xcode Command Line Tools
- GPG key storage uses macOS keychain via `pinentry-mac`
- Git credential helper uses `osxkeychain`
- Default editor set to VS Code with `--wait` flag