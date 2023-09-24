# 🛠 .dotfiles

This repository contains my dotfiles for bootstrapping a new Mac for development. It includes setup for version management using [`nvm`](https://github.com/nvm-sh/nvm) for Node.js and [`pyenv`](https://github.com/pyenv/pyenv) for Python. Feel free to explore, learn and copy parts for your own dotfiles. Enjoy!

---

## 🚀 Getting Started

### Step 1: Install Apple's Command Line Tools

Command Line Tools are prerequisites for Git and Homebrew. Run the following command to install them:

```zsh
xcode-select --install
```

### Step 2: Clone This Repository

You can clone this repository into a new hidden directory using SSH or HTTPS. Make sure you recursivly install the sub modules to avoid only installing the root repository.

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
4. You may need to add the path to pinentry-mac to the ".gpugp/gpg-agent.conf", e.g. pinentry-program /usr/local/bin/pinentry-mac

---

## 📚 Additional Resources

- macOS Defaults - [Website](https://macos-defaults.com/#%F0%9F%99%8B-what-s-a-defaults-command)
- Dotbot for Automating Symlinks - [GitHub Repo](https://github.com/anishathalye/dotbot)
- `nvm` for Node.js Version Management - [GitHub Repo](https://github.com/nvm-sh/nvm)
- `pyenv` for Python Version Management - [GitHub Repo](https://github.com/pyenv/pyenv)
- Bootable USB installer for macOS - [Apple Support Guide](https://support.apple.com/en-us/HT201372)
- More Dotfiles Inspiration - [Website](https://dotfiles.github.io/)

---
