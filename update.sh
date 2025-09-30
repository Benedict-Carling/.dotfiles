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

# Update casks using buo/cask-upgrade
echo "Updating Homebrew casks..."
brew cu --all -y

# Clean up Homebrew
echo "Cleaning up Homebrew..."
brew cleanup
brew bundle --force cleanup --file=~/.dotfiles/Brewfile
brew doctor

# Clear caches
echo "🗑️  Clearing caches..."
nvm cache clear
yarn cache clean

# Rehash pyenv
echo "🐍 Rehashing pyenv..."
pyenv rehash

echo "✅ Update complete!"
