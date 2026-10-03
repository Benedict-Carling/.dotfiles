#!/bin/bash
set -e
DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "Updating dotfiles & Homebrew packages..."

# Update Homebrew indices
echo "Updating Homebrew..."
brew update

# Install/upgrade all curated tools from Brewfile
echo "Syncing packages with Brewfile..."
brew bundle --file ~/.dotfiles/Brewfile

# Clean up unneeded packages and casks not in Brewfile
echo "Cleaning up unneeded packages..."
brew bundle --force cleanup --file ~/.dotfiles/Brewfile
brew cleanup

# Update Antidote Zsh plugins
export HOMEBREW_PREFIX="$(brew --prefix)"
if [ -f "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh" ]; then
  echo "Updating Zsh plugins via Antidote..."
  /bin/zsh -fc 'source "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh"; antidote update'
  /bin/zsh "$DOTFILES_DIR/scripts/bundle-plugins.zsh" \
    "$DOTFILES_DIR/.zsh_plugins.txt" "${XDG_CACHE_HOME:-$HOME/.cache}/.zsh_plugins.zsh"
fi

# Clear caches
echo "Pruning caches..."
command -v uv >/dev/null 2>&1 && uv cache prune 2>/dev/null || true

echo "Update complete!"
