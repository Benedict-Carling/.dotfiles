# .dotfiles

This repository contains my dotfiles for bootstrapping a new Mac for development. It is completely submodule-free, featuring [fnm](https://github.com/Schniz/fnm) for Node.js, [`uv`](https://github.com/astral-sh/uv) for Python, [Starship](https://starship.rs/) for a minimal prompt, [Antidote](https://getantidote.github.io/) for static Zsh plugin bundling, and native SSH Git commit signing.

---

## Repository Structure

### Configuration

- **`.zshrc`** - Zsh shell configuration with history settings, Antidote, Starship, fnm, conda, zoxide, fzf, Cargo and modern aliases. It is the only Zsh startup file; there is no `.zshenv` or `.zprofile`.
- **`.zsh_plugins.txt`** - Antidote plugin manifest (Git plugins, autosuggestions, syntax highlighting)
- **`git/config`** - Shared Git settings (Delta pager, SSH signing format, rebase and diff defaults), linked to `~/.config/git/config`
- **`git/ignore`** - Global gitignore preventing accidental OS, editor and secret commits, linked to `~/.config/git/ignore`
- **`starship.toml`** - Starship prompt configuration (Pure/minimalist style), loaded via `STARSHIP_CONFIG`
- **`Brewfile`** - Homebrew formulae, casks and Mac App Store apps

### Scripts

- **`install.sh`** - Bootstraps a new Mac: installs Homebrew if missing, symlinks the shell and Git configuration, installs the Brewfile, and sets up Git identity and signing from your GitHub account
- **`update.sh`** - Updates Homebrew packages, Antidote plugins, uv tools and Pythons, and Rust toolchains
- **`scripts/audit.sh`** - Report of what a Mac has installed and what conflicts with these dotfiles
- **`scripts/setup-git-identity.sh`** - Signs in with `gh`, writes your name, email and signing key to your personal `~/.gitconfig`, and registers the key with GitHub
- **`scripts/bundle-plugins.zsh`** - Regenerates the Antidote plugin bundle safely
- **`scripts/benchmark-shell.py`** and **`tests/test_shell.py`** - Shell startup benchmark and integration tests

### Ignore Files

- **`.gitignore`** - Keeps `.tokens.zsh`, macOS metadata, media files and temporary files out of this repository

---

## Getting Started

### Step 0: Audit an Existing Mac

On a Mac that already has development tools, see what conflicts first. The audit changes no settings or installs (tools may refresh their caches) and works before anything else is installed:

```zsh
curl -fsSL https://raw.githubusercontent.com/Benedict-Carling/.dotfiles/main/scripts/audit.sh | bash | tee ~/mac-audit.txt
```

It reports Intel Homebrew on Apple Silicon, other Zsh startup files, nvm, pyenv, conda and installer-based Node or Python, global packages to reinstall, an old copy of this repository, the Git identity commits use, and apps that Homebrew casks would collide with. Pass a Brewfile path to also list the Homebrew packages `update.sh` would uninstall.

### Step 1: Install Apple's Command Line Tools

Command Line Tools are prerequisites for Git and Homebrew:

```zsh
xcode-select --install
```

### Step 2: Fork and Clone

Fork this repository on GitHub so you can keep your own changes, then clone your fork to `~/.dotfiles` (the path is required). HTTPS works before any SSH key exists:

```zsh
git clone https://github.com/<your-username>/.dotfiles.git ~/.dotfiles
```

### Step 3: Trim the Brewfile

Remove anything from `Brewfile` that you do not want installed, and add your own tools. `update.sh` uninstalls Homebrew packages that are not listed, so the Brewfile should describe exactly what you use.

### Step 4: Run the Installer

```zsh
~/.dotfiles/install.sh
```

The installer is safe to rerun. Existing files at the linked paths are moved aside with a `.backup.<timestamp>` suffix. Mac App Store entries require being signed in to the App Store.

It enables Touch ID for `sudo` using Apple's `/etc/pam.d/sudo_local` template, which survives macOS updates. Your password still works whenever Touch ID is unavailable, for example over SSH or with the lid closed.

It then signs you in to GitHub with `gh` (a browser window opens) and sets up Git for you:

- Your name and private `ID+username@users.noreply.github.com` email come from your GitHub account and are written to `~/.gitconfig`, which is personal and not part of this repository.
- `~/.ssh/id_ed25519` is created if missing (without a passphrase, so agents and other tools can sign commits non-interactively; FileVault protects it at rest) and registered with GitHub for both authentication and commit signing, so your commits show as **Verified**.
- `~/.config/git/allowed_signers` is generated from your GitHub signing keys so `git log --show-signature` works locally.

Settings written with `git config --global` go to your personal `~/.gitconfig`, never into this repository.

---

## Keeping Up to Date

```zsh
~/.dotfiles/update.sh
```

This updates Homebrew and installs or upgrades everything in the `Brewfile`, then **uninstalls any Homebrew package or cask that is not listed in the `Brewfile`**. Add tools to the `Brewfile` rather than installing them with `brew install` directly. It also checks Brewfile formulae for known vulnerabilities, updates Antidote plugins, upgrades uv tools and uv-managed Pythons, runs `rustup update`, updates espup and its toolchain when the ESP32 toolchain is installed, and updates Google Cloud CLI components. If a step fails, the remaining steps still run and the script exits with an error.

`.zshrc` points `HOMEBREW_BUNDLE_FILE_GLOBAL` at this `Brewfile`, so the `-g` flag works from any directory:

```zsh
brew bundle add -g ripgrep        # add a formula to the Brewfile (--cask for apps)
brew bundle -g                    # install everything listed
brew bundle remove -g ripgrep     # remove an entry
brew bundle check -g              # report anything missing
```

Secrets and API tokens go in `~/.dotfiles/.tokens.zsh`, which is git-ignored and sourced by `.zshrc` when present.

## Conda

Python projects normally use `uv`. For repositories that need conda (for example, ones that ship an `environment.yml`), the Brewfile installs Miniconda:

```zsh
conda tos accept                        # once, to use Anaconda's default channels
conda env create -f environment.yml     # in the repository
conda activate <env-name>
```

The conda shell hook loads on the first `conda` command, so it adds nothing to shell startup. The base environment is never activated automatically, so conda's Python only appears on `PATH` once you activate an environment. The prompt shows the active environment as `conda:<name>`. To update conda itself, run `conda update -n base conda`.

## Shell shortcuts and verification

- **Ctrl-R**: search command history.
- **Ctrl-T**: select files, including hidden files, while respecting `.gitignore` and excluding `.git`. A `bat` preview shows the first 300 lines; **Ctrl-/** toggles it.
- **Alt-C**: select a directory, also respecting `.gitignore`. On macOS, configure Option as Alt/Meta in your terminal if needed.
- **Tab**: case-insensitive completion with selectable menus. `**<Tab>` opens fzf for paths, also respecting `.gitignore`.

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
