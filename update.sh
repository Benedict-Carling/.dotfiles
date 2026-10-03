#!/bin/bash
set -e

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
if [ -f /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ]; then
  echo "Updating Zsh plugins via Antidote..."
  zsh -c "source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh && antidote update && antidote bundle < ~/.dotfiles/.zsh_plugins.txt >| ~/.cache/.zsh_plugins.zsh" 2>/dev/null || true
fi

# Clear caches
echo "Pruning caches..."
command -v uv >/dev/null 2>&1 && uv cache prune 2>/dev/null || true

echo "Update complete!"
