# 🛠 .dotfiles

This repository contains my dotfiles for bootstrapping a new Mac for development. It includes setup for version management using [`nvm`](https://github.com/nvm-sh/nvm) for Node.js, [`uv`](https://github.com/astral-sh/uv) for fast Python management, [Starship](https://starship.rs/) for a minimal prompt, and [Antidote](https://getantidote.github.io/) for static Zsh plugin bundling.

---

## 📁 Repository Structure

This dotfiles repository is organized as follows:

### Core Configuration Files

- **`.zshrc`** - Zsh shell configuration with history settings, Antidote, Starship, Zoxide, FZF, and modern aliases
- **`.zsh_plugins.txt`** - Antidote plugin manifest (Git plugins, autosuggestions, syntax highlighting)
- **`.gitconfig`** - Git global configuration
- **`starship.toml`** - Starship prompt configuration (Pure/minimalist style)
- **`Brewfile`** - Homebrew package list with modern CLI tools (`uv`, `eza`, `fzf`, `zoxide`, `ripgrep`, `fd`, `dust`, `delta`)

### Git Submodules (External Dependencies)

The repository includes a single git submodule for Node version management:

- **`nvm/`** - Node Version Manager for Node.js version management

### Ignore Files

- **`.gitignore`** - Excludes sensitive files, build outputs, and binary files from git
- **`.cursorignore`** - Excludes submodules, caches, and binary files from Cursor's index for better performance

---

## 🎯 Cursor IDE Setup

This repository is optimized for use with Cursor IDE:

### What's Indexed by Cursor

- Core dotfiles (`.zshrc`, `.gitconfig`, etc.)
- Configuration files (`starship.toml`, `.zsh_plugins.txt`)
- Package definitions (`Brewfile`)
- Documentation (`README.md`)

### What's Excluded from Cursor Index

- **Git submodules** - These are external dependencies with their own repositories
- **Binary files** - Wallpapers, images, and other non-text files
- **Build outputs** - Generated lock files and caches
- **Sensitive files** - GPG keys and tokens

---

## 🚀 Getting Started

### Step 1: Install Apple's Command Line Tools

Command Line Tools are prerequisites for Git and Homebrew. Run the following command to install them:

```zsh
xcode-select --install
```

### Step 2: Clone This Repository

You can clone this repository into a new hidden directory using SSH or HTTPS. Make sure you recursively install the submodules to avoid only installing the root repository.

- **SSH:**

  ```zsh
  git clone --recurse-submodules git@github.com:Benedict-Carling/.dotfiles.git ~/.dotfiles
  ```

- **HTTPS:**
  ```zsh
  git clone --recurse-submodules https://github.com/Benedict-Carling/.dotfiles.git ~/.dotfiles
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

### Step 5: Create and Register GPG Keys

1. Follow [GitHub's guide](https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key) for generating a new GPG key.
2. Save the signing key in a new file at the root of this repository called `.signingkey.gitconfig`. An example configuration file called [`.example.signingkey.gitconfig`](./.example.signingkey.gitconfig) is provided for your reference.
3. Add the GPG key to GitHub's recognized GPG keys.
4. You may need to add the path to pinentry-mac to the `.gnupg/gpg-agent.conf`, e.g. `pinentry-program /opt/homebrew/bin/pinentry-mac`

### Step 6: Essential mac settings

Warning: Your terminal does not have App Management permissions, so Homebrew will delete and reinstall the app.
This may result in some configurations (like notification settings or location in the Dock/Launchpad) being lost.
To fix this, go to System Settings > Privacy & Security > App Management and add or enable your terminal.

---

## 📚 Additional Resources

- uv (Python Package & Version Manager) - [GitHub Repo](https://github.com/astral-sh/uv)
- Antidote Plugin Manager - [GitHub Repo](https://github.com/mattmc3/antidote)
- Starship Prompt - [Website](https://starship.rs/)
- `nvm` for Node.js Version Management - [GitHub Repo](https://github.com/nvm-sh/nvm)
- More Dotfiles Inspiration - [Website](https://dotfiles.github.io/)

---
