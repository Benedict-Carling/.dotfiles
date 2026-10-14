#!/bin/bash
set -e
DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
status=0

echo "Updating dotfiles & Homebrew packages..."

# Update Homebrew indices
echo "Updating Homebrew..."
brew update || status=1

# Install/upgrade all curated tools from Brewfile
echo "Syncing packages with Brewfile..."
brew bundle --file "$DOTFILES_DIR/Brewfile" || {
  echo "Some Brewfile entries failed; continuing with the remaining steps." >&2
  status=1
}

# Clean up unneeded packages and casks not in Brewfile
echo "Cleaning up unneeded packages..."
brew bundle cleanup --force --file "$DOTFILES_DIR/Brewfile" || status=1

echo "Checking Brewfile formulae for known vulnerabilities..."
brew vulns --brewfile="$DOTFILES_DIR/Brewfile" || status=1

# Update Antidote Zsh plugins
export HOMEBREW_PREFIX="$(brew --prefix)"
if [ -f "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh" ]; then
  echo "Updating Zsh plugins via Antidote..."
  /bin/zsh -fc 'source "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh"; antidote update --bundles' ||
    status=1
  /bin/zsh "$DOTFILES_DIR/scripts/bundle-plugins.zsh" \
    "$DOTFILES_DIR/.zsh_plugins.txt" "${XDG_CACHE_HOME:-$HOME/.cache}/.zsh_plugins.zsh" || status=1
fi

if command -v uv >/dev/null 2>&1; then
  echo "Upgrading uv tools..."
  uv tool upgrade --all || status=1
  echo "Upgrading uv-managed Pythons..."
  uv python upgrade || status=1
fi

if command -v rustup >/dev/null 2>&1; then
  echo "Updating Rust toolchains..."
  rustup update || status=1
fi

if command -v espup >/dev/null 2>&1 && [ -d "$HOME/.rustup/toolchains/esp" ]; then
  echo "Updating espup and the ESP32 Rust toolchain..."
  cargo install espup --locked || status=1
  espup update || status=1
fi

# The gcloud cask updates itself, so brew bundle does not upgrade it.
if command -v gcloud >/dev/null 2>&1; then
  echo "Updating Google Cloud CLI components..."
  gcloud components update --quiet || status=1
fi

# Clear caches
echo "Pruning caches..."
command -v uv >/dev/null 2>&1 && uv cache prune 2>/dev/null || true

if [ "$status" -eq 0 ]; then
  echo "Update complete!"
else
  echo "Update finished with errors; see the failures above." >&2
fi
exit "$status"
