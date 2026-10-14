# Keep paths unique, including paths inherited from a parent shell.
typeset -U path fpath
typeset -g DOTFILES_DIR="${${(%):-%N}:A:h}"

# Initialise Homebrew once; support Apple Silicon and Intel Macs.
if [[ -z $HOMEBREW_PREFIX ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
if [[ -n $HOMEBREW_PREFIX ]]; then
  path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
  [[ -d "$HOMEBREW_PREFIX/opt/openjdk@25/bin" ]] && path=("$HOMEBREW_PREFIX/opt/openjdk@25/bin" $path)
fi
path=("$HOME/.local/bin" "$HOME/bin" $path)
export HOMEBREW_BUNDLE_FILE_GLOBAL="$DOTFILES_DIR/Brewfile"

# History Configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY          # Record timestamps in history
setopt HIST_IGNORE_ALL_DUPS      # Delete old duplicate entry if a new duplicate is added
setopt HIST_IGNORE_SPACE         # Don't record entries starting with a space (for secrets)
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries to the history file
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording
setopt SHARE_HISTORY             # Share history across all active terminal sessions

# Zsh Completion & Antidote Plugin Manager
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/.zcompdump-${ZSH_VERSION}"
mkdir -p -- "${ZSH_COMPDUMP:h}"
zmodload zsh/complist
autoload -Uz compinit
_stale_dump=($ZSH_COMPDUMP(N.mh+24))
if [[ -f $ZSH_COMPDUMP && -z $_stale_dump ]]; then
  compinit -C -d "$ZSH_COMPDUMP"
else
  compinit -i -d "$ZSH_COMPDUMP"
  # compinit only rewrites the dump when completions change; refresh it so -C is used again.
  touch "$ZSH_COMPDUMP"
fi
unset _stale_dump

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select

_zsh_plugins="$DOTFILES_DIR/.zsh_plugins.txt"
_zsh_plugins_cache="${XDG_CACHE_HOME:-$HOME/.cache}/.zsh_plugins.zsh"

# The marker disappears with the plugin clones, which forces a rebuild (as antidote load does).
if [[ ! -f "$_zsh_plugins_cache" || "$_zsh_plugins" -nt "$_zsh_plugins_cache" ||
      ! -e "${ANTIDOTE_HOME:-$HOME/Library/Caches/antidote}/.antidote.load" ]]; then
  if [[ -f "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh" ]]; then
    /bin/zsh "$DOTFILES_DIR/scripts/bundle-plugins.zsh" "$_zsh_plugins" "$_zsh_plugins_cache" ||
      print -u2 -- 'Plugin rebuild failed; retaining the previous bundle.'
  fi
fi
# Load plugins at the end, after all integrations have registered their widgets.

# Starship Prompt
export STARSHIP_CONFIG="$DOTFILES_DIR/starship.toml"
if [[ $TERM != dumb ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# FNM (Fast Node Manager - automatic version switching on cd)
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
fi

# Conda (Miniconda); the shell hook is slow, so it loads on first use and never auto-activates base.
if command -v conda >/dev/null 2>&1; then
  export CONDA_AUTO_ACTIVATE=false CONDA_CHANGEPS1=false
  conda() {
    unfunction conda
    eval "$(command conda shell.zsh hook)"
    conda "$@"
  }
fi

# Cargo (Rust) Setup
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Espup (ESP32 Rust toolchain) Setup; the export file outlives an uninstalled toolchain.
[[ -f "$HOME/export-esp.sh" && -d "$HOME/.rustup/toolchains/esp" ]] && . "$HOME/export-esp.sh"

# Zoxide (Smart directory jumping)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# FZF (Fuzzy finder keybindings: Ctrl+R for history, Ctrl+T for files)
if command -v fzf >/dev/null 2>&1; then
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --strip-cwd-prefix --exclude .git'
    _fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
    _fzf_compgen_dir() { fd --type d --hidden --exclude .git . "$1"; }
  fi
  export FZF_DEFAULT_OPTS='--height=60% --layout=reverse --border'
  if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 -- {}' --preview-window=right:60% --bind 'ctrl-/:toggle-preview'"
  fi
  source <(fzf --zsh)
fi

# Custom tokens
if [[ -f "$DOTFILES_DIR/.tokens.zsh" ]]; then
    source "$DOTFILES_DIR/.tokens.zsh"
fi

# Git Aliases (gc, ga, gco, gp, gl etc. come from the ohmyzsh git plugin)
alias glc="git rev-parse HEAD | pbcopy"

# Modern CLI Aliases (Claude Code sets CLAUDECODE; its shell needs the real ls and cat flags)
if command -v eza >/dev/null 2>&1; then
  [[ -n $CLAUDECODE ]] || alias ls="eza --icons=auto"
  alias ll="eza -la --icons=auto --git"
  alias tree="eza --tree --icons=auto"
fi
if [[ -z $CLAUDECODE ]] && command -v bat >/dev/null 2>&1; then
  alias cat="bat --paging=never"
fi
if command -v dust >/dev/null 2>&1; then
  alias dus="dust -X .git -X node_modules"
else
  alias dus="ncdu --color dark -rr -x --exclude .git --exclude node_modules"
fi

export EDITOR="code --wait --reuse-window"
export VISUAL="code --wait --reuse-window"
export STM32CubeMX_PATH=/Applications/STMicroelectronics/STM32CubeMX.app/Contents/Resources

# Starship owns the prompt; only load OMZ's Git helpers, without its async prompt.
zstyle ':omz:alpha:lib:git' async-prompt no
[[ -f "$_zsh_plugins_cache" ]] && source "$_zsh_plugins_cache"
unset _zsh_plugins _zsh_plugins_cache
