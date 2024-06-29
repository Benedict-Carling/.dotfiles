# Update git submodules
git submodule update --remote
# Update Brew
brew update
brew upgrade
brew upgrade --cask

brew cu --all -y 
# remove uninstalled libraries
brew bundle --force cleanup

brew cleanup
brew doctor
