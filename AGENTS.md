# AGENTS.md

macOS dotfiles, forked per person. Lives at `~/.dotfiles` (the path is required). `install.sh` bootstraps a Mac and is safe to rerun; `update.sh` syncs everything.

## Rules

- **Brewfile is the source of truth.** `update.sh` uninstalls any Homebrew package not listed. Add tools with `brew bundle add -g <name>` (`--cask` for apps), then `brew bundle -g`.
- **Shared vs personal Git config.** `git/config` (linked to `~/.config/git/config`) holds shared settings only. Identity, signing key and `commit.gpgSign` live in the untracked personal `~/.gitconfig`, written by `scripts/setup-git-identity.sh` from the GitHub account.
- **`.zshrc` is the only Zsh startup file.** Put environment setup there. Secrets go in the git-ignored `.tokens.zsh`.
- **Plugin cache safety.** `scripts/bundle-plugins.zsh` builds the Antidote bundle for both startup and `update.sh`. A failed, empty or invalid build keeps the previous cache and reports the failure.
- **Plugin load order.** The bundle is sourced last in `.zshrc`, after fzf and other widget integrations. Inside it, the OMZ git library loads before the git plugin, and syntax highlighting loads last.
- **Scripts keep going.** `install.sh` and `update.sh` record failures in `status`, run every remaining step, then exit non-zero.

## Verify

- `python3 tests/test_shell.py`: isolated integration tests (temporary HOME, no secrets or history). Run after any change to `.zshrc`, `.zsh_plugins.txt` or `scripts/`.
- Scripts that call `brew`, `gh` or `sudo`: test in a temporary HOME with stub commands first on PATH, so the real machine and GitHub account stay untouched.
- `python3 scripts/benchmark-shell.py` measures startup. It aborts inside Apple Terminal, because session-restore messages print to stderr.
