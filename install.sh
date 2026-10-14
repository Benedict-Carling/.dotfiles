#!/bin/bash
set -e
DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
status=0

# .zshrc and update.sh expect the repository at ~/.dotfiles.
if [ "$DOTFILES_DIR" != "$HOME/.dotfiles" ]; then
  echo "Clone this repository to ~/.dotfiles before running install.sh." >&2
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Install the Command Line Tools first: xcode-select --install" >&2
  exit 1
fi

sudo_local=/etc/pam.d/sudo_local
if grep -qE '^auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so' "$sudo_local" 2>/dev/null; then
  :
elif [ -e "$sudo_local" ]; then
  echo "$sudo_local already exists; add 'auth sufficient pam_tid.so' to it to enable Touch ID for sudo." >&2
elif [ -f "$sudo_local.template" ]; then
  echo "Enabling Touch ID for sudo (password still works as a fallback)..."
  sed -E 's/^#(auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so)/\1/' "$sudo_local.template" |
    sudo tee "$sudo_local" >/dev/null || status=1
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
  local source="$DOTFILES_DIR/$1" target="$HOME/$2"
  if [ "$(readlink "$target")" = "$source" ]; then
    return
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup="$target.backup.$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup" || return 1
    echo "Moved existing $target to $backup"
  fi
  mkdir -p "$(dirname "$target")" && ln -s "$source" "$target" || return 1
  echo "Linked $target"
}
link .zshrc .zshrc || status=1
link git/config .config/git/config || status=1
link git/ignore .config/git/ignore || status=1

# ~/.gitconfig is now personal; drop the link left by the old layout.
case "$(readlink "$HOME/.gitconfig")" in
  "$DOTFILES_DIR"/*) rm "$HOME/.gitconfig" ;;
esac

echo "Installing packages from Brewfile..."
brew bundle --file "$DOTFILES_DIR/Brewfile" || {
  echo "Some Brewfile entries failed; rerun install.sh or update.sh once resolved." >&2
  status=1
}

echo "Installing the latest Python as the default python and python3..."
uv python install --default || status=1

echo "Configuring Git identity and signing from GitHub..."
"$DOTFILES_DIR/scripts/setup-git-identity.sh" || status=1

if [ "$status" -eq 0 ]; then
  echo "Install complete! Open a new terminal to load the shell configuration."
else
  echo "Install finished with errors; see the messages above." >&2
fi
exit "$status"
