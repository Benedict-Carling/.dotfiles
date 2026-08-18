#!/bin/bash
set -e

echo "🔄 Updating dotfiles..."

# Update Homebrew
echo "Updating Homebrew..."
brew update
brew upgrade

# Update casks with greedy upgrades (checks auto-updating apps)
echo "Updating Homebrew casks..."
brew upgrade --cask --greedy

# Clean up Homebrew
echo "Cleaning up Homebrew..."
brew cleanup
brew bundle --force cleanup --file=~/.dotfiles/Brewfile
brew doctor

# Update antidote plugins
if [ -f /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ]; then
  echo "Updating Zsh plugins via Antidote..."
  zsh -c "source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh && antidote update && antidote bundle < ~/.dotfiles/.zsh_plugins.txt >| ~/.cache/.zsh_plugins.zsh" 2>/dev/null || true
fi

# Clear caches
echo "🗑️  Clearing caches..."
yarn cache clean 2>/dev/null || true
npm cache clean --force 2>/dev/null || true
command -v uv >/dev/null 2>&1 && uv cache clean 2>/dev/null || true
rm -rf ~/Library/Caches/ms-playwright 2>/dev/null || true

echo "✅ Update complete!"
