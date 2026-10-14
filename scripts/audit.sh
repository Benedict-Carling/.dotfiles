#!/bin/bash
# Reports what this Mac has installed and what conflicts with these dotfiles; changes nothing but tool caches.
# Usage: audit.sh [Brewfile]
DOTFILES_DIR="$HOME/.dotfiles"
BREWFILE="${1:-$DOTFILES_DIR/Brewfile}"
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1
# Tools create caches and state on first run; keep those out of HOME so the audit changes nothing.
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
[ -d "$HOME/Library/Caches/Homebrew" ] || export HOMEBREW_CACHE="$scratch/homebrew"
[ -d "$HOME/.cache/uv" ] || export UV_CACHE_DIR="$scratch/uv"
warnings=()

section() { printf '\n== %s\n' "$1"; }
info() { printf '   %s\n' "$*"; }
warn() { printf ' ! %s\n' "$*"; warnings+=("$*"); }
indent() { sed 's/^/     /'; }
join() { tr '\n' ' ' | sed 's/ $//'; }
dirs_in() { ls -1 "$1" 2>/dev/null | join; }

section System
apple_silicon=$([ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = 1 ] && echo 1)
info "macOS $(sw_vers -productVersion), $([ -n "$apple_silicon" ] && echo 'Apple Silicon' || echo Intel), user $(id -un)"
info "Free disk space: $(df -h / | awk 'NR == 2 {print $4}')"
[ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = 1 ] &&
  warn "This terminal runs under Rosetta; turn off \"Open using Rosetta\" in the terminal app's Get Info"
id -Gn | tr ' ' '\n' | grep -qx admin || warn "$(id -un) is not an administrator, which Homebrew needs"
# Without the Command Line Tools, /usr/bin/git opens an install dialog instead of running.
if xcode-select -p >/dev/null 2>&1; then have_clt=1; else warn "Command Line Tools missing: xcode-select --install"; fi
[ -d /Applications/Xcode.app ] && ! xcodebuild -license check >/dev/null 2>&1 &&
  warn "The Xcode license is not accepted, which stops Homebrew and git: sudo xcodebuild -license accept"

section Homebrew
brew=""
found_brew=""
for prefix in /opt/homebrew /usr/local; do
  [ -d "$prefix/Cellar" ] || [ -x "$prefix/bin/brew" ] || continue
  found_brew=1
  info "$prefix: $(ls "$prefix/Cellar" 2>/dev/null | wc -l | tr -d ' ') formulae, $(ls "$prefix/Caskroom" 2>/dev/null | wc -l | tr -d ' ') casks"
  if [ "$prefix" = /usr/local ] && [ -n "$apple_silicon" ]; then
    warn "Intel Homebrew in /usr/local on Apple Silicon; save its package list, then uninstall it"
    info "  formulae: $(dirs_in /usr/local/Cellar)"
    info "  casks: $(dirs_in /usr/local/Caskroom)"
  elif [ -z "$brew" ] && [ -x "$prefix/bin/brew" ]; then
    brew="$prefix/bin/brew"
    if ! leaves=$("$brew" leaves --installed-on-request 2>&1); then
      warn "Homebrew does not run: $(printf '%s\n' "$leaves" | head -1)"
      info "  formulae, including dependencies: $(dirs_in "$prefix/Cellar")"
      info "  casks: $(dirs_in "$prefix/Caskroom")"
      brew=""
    fi
  fi
done
if [ -n "$brew" ]; then
  info "Installed on request: $(printf '%s\n' "$leaves" | join)"
  info "Casks: $("$brew" list --cask 2>/dev/null | join)"
  if [ -f "$BREWFILE" ]; then
    extra=$("$brew" bundle cleanup --file "$BREWFILE" 2>/dev/null | grep -v '^Would\|^Run `brew bundle')
    [ -n "$extra" ] && warn "Not in $BREWFILE, so update.sh would uninstall: $(printf '%s\n' "$extra" | join)"
  fi
fi
[ -z "$found_brew" ] && info "Homebrew is not installed"

section "Shell startup files"
new_layout=$([ -f "$DOTFILES_DIR/.zsh_plugins.txt" ] && echo 1)
for f in .zshenv .zprofile .zshrc .zlogin .bash_profile .bashrc .profile; do
  file="$HOME/$f"
  [ -e "$file" ] || [ -L "$file" ] || continue
  target=$(readlink "$file")
  info "~/$f${target:+ -> $target}"
  [ -e "$file" ] || { warn "~/$f is a broken link"; continue; }
  case $f in
    .bash*|.profile) continue ;;
    .zshrc) [ -n "$new_layout" ] && [ "$target" = "$DOTFILES_DIR/.zshrc" ] && continue ;;
  esac
  matches=$(grep -nE 'nvm|pyenv|conda|p10k|powerlevel10k|oh-my-zsh|ohmyzsh|/usr/local|shellenv|PATH=|volta|asdf|rbenv|jenv|sdkman' "$file")
  if [ -n "$matches" ]; then
    warn "~/$f sets up tools or PATH; move it aside once anything needed is in .zshrc or .tokens.zsh"
    printf '%s\n' "$matches" | indent
  fi
done
extra_paths=$(ls /etc/paths.d 2>/dev/null | grep -vx '10-cryptex\|100-rvictl' | join)
[ -n "$extra_paths" ] && info "Installers added to /etc/paths.d: $extra_paths"

git=""
for candidate in /opt/homebrew/bin/git /usr/local/bin/git /usr/bin/git; do
  [ -x "$candidate" ] || continue
  [ "$candidate" = /usr/bin/git ] && [ -z "$have_clt" ] && continue
  "$candidate" --version >/dev/null 2>&1 && { git=$candidate; break; }
done

section "Dotfiles repository"
[ -f "$DOTFILES_DIR/.gitmodules" ] &&
  warn "~/.dotfiles uses the old submodule layout; move it to ~/.dotfiles.old and clone the current version"
if [ -d "$DOTFILES_DIR/.git" ] && [ -n "$git" ]; then
  info "Remote: $(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null)"
  info "Last commit: $(git -C "$DOTFILES_DIR" log -1 --format='%ad %s' --date=short 2>/dev/null)"
  changes=$(git -C "$DOTFILES_DIR" status --short --ignore-submodules 2>/dev/null)
  [ -n "$changes" ] && { warn "~/.dotfiles has local changes worth keeping:"; printf '%s\n' "$changes" | indent; }
elif [ -d "$DOTFILES_DIR" ]; then
  info "~/.dotfiles exists"
else
  info "~/.dotfiles not found"
fi
[ -f "$DOTFILES_DIR/.tokens.zsh" ] && info "~/.dotfiles/.tokens.zsh exists; copy it into any new clone"

section Git
[ -L "$HOME/.gitconfig" ] &&
  warn "~/.gitconfig links to $(readlink "$HOME/.gitconfig"), a shared file; remove the link so setup writes a personal one"
if [ -n "$git" ]; then
  name=$("$git" config --global user.name)
  email=$("$git" config --global user.email)
  info "Commits are authored as: ${name:-<no name>} <${email:-no email}>"
  if [ "$("$git" config --global commit.gpgSign)" = true ] && [ "$("$git" config --global gpg.format)" != ssh ] &&
     ! command -v gpg >/dev/null 2>&1; then
    warn "Git signs commits with GPG, but gpg is not installed, so commits fail"
  fi
fi
keys=$(ls "$HOME"/.ssh/*.pub 2>/dev/null | join)
info "SSH keys: ${keys:-none}"
gh=$(command -v gh || { [ -n "$brew" ] && [ -x "${brew%/brew}/gh" ] && echo "${brew%/brew}/gh"; })
if [ -n "$gh" ]; then
  login=$(XDG_STATE_HOME="$scratch" "$gh" api user --jq .login 2>/dev/null)
  info "GitHub CLI signed in as: ${login:-nobody}"
fi

section "Node, Python and other version managers"
for dir in "$HOME/.nvm" "$DOTFILES_DIR/nvm"; do
  [ -d "$dir/versions/node" ] || continue
  warn "nvm in $dir with Node $(dirs_in "$dir/versions/node"); reinstall the ones in use with fnm"
  for version in "$dir"/versions/node/*; do
    globals=$(ls "$version/lib/node_modules" 2>/dev/null | grep -vx 'npm\|corepack' | join)
    [ -n "$globals" ] && info "  ${version##*/} global npm packages: $globals"
  done
done
for dir in "$HOME/.pyenv" "$DOTFILES_DIR/pyenv"; do
  [ -d "$dir/versions" ] &&
    warn "pyenv in $dir with Python $(dirs_in "$dir/versions"); reinstall the ones in use with uv python install"
done
for dir in .volta .asdf .rbenv .jenv .sdkman .n; do
  [ -d "$HOME/$dir" ] && warn "Another version manager is installed in ~/$dir"
done
[ -d /Library/Frameworks/Python.framework/Versions ] &&
  warn "python.org installer Pythons: $(dirs_in /Library/Frameworks/Python.framework/Versions | sed 's/ *Current//')"
[ -d /usr/local/lib/node_modules/npm ] && [ ! -d /usr/local/Cellar/node ] &&
  warn "Node from the nodejs.org installer in /usr/local"
for dir in "$HOME/anaconda3" "$HOME/miniconda3" "$HOME/miniforge3" "$HOME/opt/anaconda3" "$HOME/opt/miniconda3" \
           /opt/anaconda3 /opt/miniconda3 /usr/local/Caskroom/miniconda/base /usr/local/Caskroom/anaconda/base \
           /opt/homebrew/Caskroom/anaconda/base /opt/homebrew/Caskroom/miniconda/base; do
  [ -x "$dir/bin/conda" ] || continue
  envs=$(dirs_in "$dir/envs")
  if [ "$dir" = /opt/homebrew/Caskroom/miniconda/base ]; then
    info "Miniconda from the Brewfile, environments: ${envs:-none}"
  else
    warn "conda in $dir, environments: ${envs:-none}; export the ones in use with conda env export -n <name>"
  fi
done
[ -f "$HOME/.condarc" ] && grep -q 'auto_activate' "$HOME/.condarc" &&
  info "~/.condarc sets auto_activate; .zshrc already prevents base activating"
fnm=$(command -v fnm || { [ -n "$brew" ] && [ -x "${brew%/brew}/fnm" ] && echo "${brew%/brew}/fnm"; })
[ -n "$fnm" ] && [ -d "${FNM_DIR:-$HOME/.local/share/fnm}" ] && info "fnm Node versions: $("$fnm" list 2>/dev/null | sed 's/^\* //' | join)"
uv=$(command -v uv || { [ -n "$brew" ] && [ -x "${brew%/brew}/uv" ] && echo "${brew%/brew}/uv"; })
if [ -n "$uv" ]; then
  info "uv Pythons: $("$uv" python list --only-installed 2>/dev/null | awk '!seen[$1]++ {print $1}' | join)"
  info "uv tools: $("$uv" tool list 2>/dev/null | grep -v '^-' | awk '{print $1}' | join)"
fi
pipx=$(command -v pipx)
[ -n "$pipx" ] && warn "pipx tools (reinstall with uv tool install): $("$pipx" list --short 2>/dev/null | awk '{print $1}' | join)"
user_pip=$(ls -d "$HOME"/Library/Python/*/bin 2>/dev/null | join)
[ -n "$user_pip" ] && info "pip --user scripts in: $user_pip"
[ -d "$HOME/.cargo/bin" ] && info "Cargo binaries: $(dirs_in "$HOME/.cargo/bin")"

section "Commands a new login shell finds"
login_path=$(env -i HOME="$HOME" USER="$USER" LOGNAME="$LOGNAME" TERM=xterm-256color /bin/zsh -lic 'print -r -- "AUDIT_PATH=$PATH"' 2>/dev/null </dev/null | grep '^AUDIT_PATH=' | tail -1)
login_path=${login_path#AUDIT_PATH=}
if [ -z "$login_path" ]; then
  warn "A new zsh login shell failed to start"
else
  for cmd in brew git python python3 pip pip3 node npm conda; do
    found=$(PATH="$login_path" /usr/bin/which -a "$cmd" 2>/dev/null | awk '!seen[$0]++' | join)
    info "$cmd: ${found:-not found}"
  done
  dupes=$(printf '%s\n' "$login_path" | tr ':' '\n' | sort | uniq -d | join)
  [ -n "$dupes" ] && warn "PATH lists these more than once: $dupes"
  foreign=$(printf '%s\n' "$login_path" | tr ':' '\n' | grep '^/Users/' | grep -v "^$HOME\(/\|$\)" | awk '!seen[$0]++' | join)
  [ -n "$foreign" ] && warn "PATH includes another user's folders: $foreign"
fi

section "Apps not installed by Homebrew or the App Store"
if [ -n "$found_brew" ] && [ -z "$brew" ]; then
  info "Skipped until Homebrew runs again"
else
  cask_apps=""
  [ -n "$brew" ] && cask_apps=$("$brew" info --cask --installed --json=v2 2>/dev/null | grep -o '[^"/]*\.app"' | tr -d '"')
  for app in /Applications/*.app; do
    [ -d "$app/Contents/_MASReceipt" ] && continue
    case $(defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null) in com.apple.*) continue ;; esac
    printf '%s\n' "$cask_apps" | grep -qxF "${app##*/}" || info "${app##*/}"
  done
  info "(A cask install fails while these exist; take one over with brew install --cask --adopt <cask>)"
fi

section Summary
if [ "${#warnings[@]}" -eq 0 ]; then
  info "Nothing found that conflicts with these dotfiles."
else
  info "Things to deal with (marked ! above): ${#warnings[@]}"
fi
