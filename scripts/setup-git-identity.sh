#!/bin/bash
# Configures the personal ~/.gitconfig (identity and signing) from the signed-in GitHub account.
set -e
personal="$HOME/.gitconfig"
key="$HOME/.ssh/id_ed25519.pub"
signers="$HOME/.config/git/allowed_signers"
scopes="admin:public_key,admin:ssh_signing_key"

# git config --global writes to the shared XDG file unless ~/.gitconfig exists.
touch "$personal"

if ! gh auth status >/dev/null 2>&1; then
  gh auth login --hostname github.com --web --git-protocol ssh --skip-ssh-key --scopes "$scopes"
elif ! gh auth status 2>&1 | grep -q "admin:ssh_signing_key"; then
  gh auth refresh --hostname github.com --scopes "$scopes"
fi
gh auth setup-git

{ read -r login; read -r id; read -r name; } < <(gh api user --jq '.login, .id, (.name // .login)')
git config --file "$personal" user.name >/dev/null || git config --file "$personal" user.name "$name"
git config --file "$personal" user.email >/dev/null ||
  git config --file "$personal" user.email "$id+$login@users.noreply.github.com"
email=$(git config --file "$personal" user.email)

if [ ! -f "$key" ]; then
  mkdir -p "$HOME/.ssh"
  # No passphrase so agents and other non-interactive tools can sign commits; FileVault protects it at rest.
  ssh-keygen -q -t ed25519 -N "" -C "$email" -f "${key%.pub}"
fi
git config --file "$personal" user.signingKey "$key"
git config --file "$personal" commit.gpgSign true

pub=$(awk '{print $1 " " $2}' "$key")
title=$(scutil --get ComputerName 2>/dev/null || hostname)
gh api "users/$login/keys" --jq '.[].key' | grep -qxF "$pub" ||
  gh ssh-key add "$key" --type authentication --title "$title"
gh api "users/$login/ssh_signing_keys" --jq '.[].key' | grep -qxF "$pub" ||
  gh ssh-key add "$key" --type signing --title "$title"

mkdir -p "${signers%/*}"
{ gh api "users/$login/ssh_signing_keys" --jq '.[].key'; echo "$pub"; } | sort -u |
  awk -v email="$email" '{print email " namespaces=\"git\" " $0}' > "$signers"

echo "Git identity: $(git config --file "$personal" user.name) <$email>, signing with $key"
