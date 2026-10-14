# .dotfiles

This repository contains my dotfiles for bootstrapping a new Mac for development. It is completely submodule-free, featuring [fnm](https://github.com/Schniz/fnm) for Node.js, [`uv`](https://github.com/astral-sh/uv) for Python, [Starship](https://starship.rs/) for a minimal prompt, [Antidote](https://getantidote.github.io/) for static Zsh plugin bundling, and native SSH Git commit signing.

---

## Repository Structure

### Configuration

- **`.zshrc`** - Zsh shell configuration with history settings, Antidote, Starship, fnm, zoxide, fzf, Cargo and modern aliases. It is the only Zsh startup file; there is no `.zshenv` or `.zprofile`.
- **`.zsh_plugins.txt`** - Antidote plugin manifest (Git plugins, autosuggestions, syntax highlighting)
- **`.gitconfig`** - Git global configuration with SSH commit signing and Delta diff pager
- **`.allowed_signers`** - SSH public keys trusted for verifying signed commits (one per machine)
- **`.gitignore_global`** - Global gitignore preventing accidental OS, editor and secret commits
- **`starship.toml`** - Starship prompt configuration (Pure/minimalist style), loaded via `STARSHIP_CONFIG`
- **`Brewfile`** - Homebrew formulae, casks and Mac App Store apps

### Scripts

- **`install.sh`** - Bootstraps a new Mac: installs Homebrew if missing, symlinks `.zshrc` and `.gitconfig`, and installs the Brewfile
- **`update.sh`** - Updates Homebrew packages, Antidote plugins, uv tools and Rust toolchains
- **`scripts/bundle-plugins.zsh`** - Regenerates the Antidote plugin bundle safely
- **`scripts/benchmark-shell.py`** and **`tests/test_shell.py`** - Shell startup benchmark and integration tests

### Ignore Files

- **`.gitignore`** - Keeps `.tokens.zsh`, macOS metadata, media files and temporary files out of this repository

---

## Getting Started

### Step 1: Install Apple's Command Line Tools

Command Line Tools are prerequisites for Git and Homebrew:

```zsh
xcode-select --install
```

### Step 2: Clone This Repository

The configuration expects the repository at `~/.dotfiles`:

```zsh
git clone git@github.com:Benedict-Carling/.dotfiles.git ~/.dotfiles
```

### Step 3: Run the Installer

```zsh
~/.dotfiles/install.sh
```

The installer is safe to rerun. Existing `~/.zshrc` or `~/.gitconfig` files are moved aside with a `.backup.<timestamp>` suffix before being linked. Mac App Store entries require being signed in to the App Store.

### Step 4: SSH Commit Signing

Commit signing uses `~/.ssh/id_ed25519.pub`. Create one with `ssh-keygen -t ed25519` if needed, then:

1. Add it to GitHub under **Settings > SSH and GPG keys > New SSH Key** with key type **Signing Key**.
2. Add a line for it to `.allowed_signers` so `git log --show-signature` can verify commits made on that machine.

---

## Keeping Up to Date

```zsh
~/.dotfiles/update.sh
```

This updates Homebrew and installs or upgrades everything in the `Brewfile`, then **uninstalls any Homebrew package or cask that is not listed in the `Brewfile`**. Add tools to the `Brewfile` rather than installing them with `brew install` directly. It also updates Antidote plugins, upgrades uv tools and runs `rustup update`. If a step fails, the remaining steps still run and the script exits with an error.

Secrets and API tokens go in `~/.dotfiles/.tokens.zsh`, which is git-ignored and sourced by `.zshrc` when present.

## Shell shortcuts and verification

- **Ctrl-R**: search command history.
- **Ctrl-T**: select files, including hidden files, while respecting `.gitignore` and excluding `.git`. A `bat` preview shows the first 300 lines; **Ctrl-/** toggles it.
- **Alt-C**: select a directory, also respecting `.gitignore`. On macOS, configure Option as Alt/Meta in your terminal if needed.
- **Tab**: case-insensitive completion with selectable menus.

Open a new terminal to pick up configuration changes, or run `exec zsh -l`.

The Git plugin explicitly loads its helper library before its aliases. Syntax highlighting loads after fzf and other widget integrations. Plugin bundles are generated into a temporary file and checked before replacing the working cache; failed rebuilds keep the previous bundle and report an error. `update.sh` uses the same bundle writer.

Run the regression checks after Homebrew packages and Antidote plugins have been installed:

```sh
python3 tests/test_shell.py
python3 scripts/benchmark-shell.py
```

The tests use temporary home directories and installed plugins, exclude your tokens and history, and intercept Git pull operations. They check branch-aware aliases, completion caches, path deduplication, fzf filtering/keybindings, and successful/failed plugin rebuilds. The benchmark measures login/interactive shell initialization over 12 runs and reports the median of the last ten; it excludes prompt rendering and typing latency.

## Additional Resources

- `fnm` (Fast Node Manager) - [GitHub Repo](https://github.com/Schniz/fnm)
- `uv` (Python Package & Version Manager) - [GitHub Repo](https://github.com/astral-sh/uv)
- Antidote Plugin Manager - [GitHub Repo](https://github.com/mattmc3/antidote)
- Starship Prompt - [Website](https://starship.rs/)
- More Dotfiles Inspiration - [Website](https://dotfiles.github.io/)

---
