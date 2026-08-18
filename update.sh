#!/bin/bash
set -e

echo "🔄 Updating dotfiles..."

# Update git submodules
echo "Updating git submodules..."
git submodule update --remote --merge

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

# Clear caches
echo "🗑️  Clearing caches..."
nvm cache clear
yarn cache clean
npm cache clean --force
pip cache purge 2>/dev/null || true
rm -rf ~/Library/Caches/ms-playwright 2>/dev/null || true

# Rehash pyenv
echo "🐍 Rehashing pyenv..."
pyenv rehash

echo "✅ Update complete!"
