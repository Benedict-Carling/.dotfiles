# .dotfiles

This repository contains my dotfiles for bootstrapping a new Mac for development. It is completely submodule-free, featuring [fnm](https://github.com/Schniz/fnm) for Node.js, [`uv`](https://github.com/astral-sh/uv) for Python, [Starship](https://starship.rs/) for a minimal prompt, [Antidote](https://getantidote.github.io/) for static Zsh plugin bundling, and native SSH Git commit signing.

---

## Repository Structure

This dotfiles repository is organized as follows:

### Core Configuration Files

- **`.zshrc`** - Zsh shell configuration with history settings, Antidote, Starship, FNM, Zoxide, FZF, and modern aliases
- **`.zsh_plugins.txt`** - Antidote plugin manifest (Git plugins, autosuggestions, syntax highlighting)
- **`.gitconfig`** - Git global configuration with SSH commit signing and Delta diff pager
- **`.gitignore_global`** - Global gitignore preventing accidental OS and IDE commits
- **`starship.toml`** - Starship prompt configuration (Pure/minimalist style)
- **`Brewfile`** - Homebrew package manifest with modern CLI tools (`uv`, `fnm`, `eza`, `fzf`, `zoxide`, `ripgrep`, `fd`, `dust`, `delta`)

### Ignore Files

- **`.gitignore`** - Excludes sensitive files, build outputs, and binary files from git
- **`.cursorignore`** - Excludes caches and binary files from Cursor's index for better performance

---


## Getting Started

### Step 1: Install Apple's Command Line Tools

Command Line Tools are prerequisites for Git and Homebrew. Run the following command to install them:

```zsh
xcode-select --install
```

### Step 2: Clone This Repository

Clone this repository into your home directory:

```zsh
git clone git@github.com:Benedict-Carling/.dotfiles.git ~/.dotfiles
```

### Step 3: Create Symbolic Links

Create symlinks in your Home directory to point to the actual files in this repo.

```zsh
ln -s ~/.dotfiles/.zshrc ~/.zshrc
ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
```

### Step 4: Install Homebrew and Software Packages

Run the following commands to install [Homebrew](https://brew.sh/) and the software listed in the `Brewfile`.

```zsh
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install packages from Brewfile
brew bundle --file ~/.dotfiles/Brewfile
```

### Step 5: SSH Commit Signing (Automatic)

Commit signing is pre-configured to use your standard SSH key at `~/.ssh/id_ed25519.pub`. Simply add your SSH signing key to GitHub under **Settings > SSH and GPG keys > New SSH Key** (Select key type: **Signing Key**).

---

## Additional Resources

- `fnm` (Fast Node Manager) - [GitHub Repo](https://github.com/Schniz/fnm)
- `uv` (Python Package & Version Manager) - [GitHub Repo](https://github.com/astral-sh/uv)
- Antidote Plugin Manager - [GitHub Repo](https://github.com/mattmc3/antidote)
- Starship Prompt - [Website](https://starship.rs/)
- More Dotfiles Inspiration - [Website](https://dotfiles.github.io/)

---
