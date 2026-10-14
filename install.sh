#!/bin/bash
set -e
DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
status=0

# .gitconfig references ~/.dotfiles paths directly.
if [ "$DOTFILES_DIR" != "$HOME/.dotfiles" ]; then
  echo "Clone this repository to ~/.dotfiles before running install.sh." >&2
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Install the Command Line Tools first: xcode-select --install" >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for prefix in /opt/homebrew /usr/local; do
    if [ -x "$prefix/bin/brew" ]; then
      eval "$("$prefix/bin/brew" shellenv)"
      break
    fi
  done
fi

link() {
  local source="$DOTFILES_DIR/$1" target="$HOME/$1"
  if [ "$(readlink "$target")" = "$source" ]; then
    return
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup="$target.backup.$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup"
    echo "Moved existing $target to $backup"
  fi
  ln -s "$source" "$target"
  echo "Linked $target"
}
link .zshrc
link .gitconfig

echo "Installing packages from Brewfile..."
brew bundle --file "$DOTFILES_DIR/Brewfile" || {
  echo "Some Brewfile entries failed; rerun install.sh or update.sh once resolved." >&2
  status=1
}

if [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
  echo "No ~/.ssh/id_ed25519.pub found; commit signing needs it (ssh-keygen -t ed25519)." >&2
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "Install complete! Open a new terminal to load the shell configuration."
else
  echo "Install finished with errors; see the messages above." >&2
fi
exit "$status"
