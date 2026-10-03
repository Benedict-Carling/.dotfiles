#!/bin/zsh
# Generate beside the destination so a successful rename is atomic.
set -e
setopt PIPE_FAIL

if (( $# != 2 )); then
  print -u2 -- "Usage: $0 MANIFEST CACHE"
  exit 2
fi
manifest=$1
cache=$2
prefix=${HOMEBREW_PREFIX:-$(brew --prefix)}
source "$prefix/opt/antidote/share/antidote/antidote.zsh"
mkdir -p -- "${cache:h}"
temporary=$(mktemp "${cache}.XXXXXX")
trap 'rm -f -- "$temporary"' EXIT
trap 'exit 1' INT TERM

if antidote bundle < "$manifest" > "$temporary" &&
   [[ -s "$temporary" ]] && /bin/zsh -n "$temporary"; then
  mv -f -- "$temporary" "$cache"
else
  print -u2 -- 'Could not generate a valid plugin bundle.'
  exit 1
fi
