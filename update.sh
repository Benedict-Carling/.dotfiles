# Update git submodules
git submodule update --remote
# Update Brew
brew update
brew upgrade
brew upgrade --cask
brew cleanup
brew doctor
# remove uninstalled libraries
brew bundle --force cleanup