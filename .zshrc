# Environment PATHs
export PATH="$HOME/.local/bin:$HOME/bin:/opt/homebrew/opt/openjdk/bin:$PATH"

# History Configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY          # Record timestamps in history
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded
setopt HIST_IGNORE_ALL_DUPS      # Delete old duplicate entry if a new duplicate is added
setopt HIST_IGNORE_SPACE         # Don't record entries starting with a space (for secrets)
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries to the history file
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording
setopt SHARE_HISTORY             # Share history across all active terminal sessions

# GPG signing
export GPG_TTY=$(tty)

# Add Homebrew to path
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# NVM Setup (Lazy loaded for fast shell startup)
export NVM_DIR="$HOME/.dotfiles/nvm"
if [ -d "$NVM_DIR/versions/node" ]; then
  local _nvm_default_ver
  _nvm_default_ver=$(cat "$NVM_DIR/alias/default" 2>/dev/null || echo "")
  if [ -n "$_nvm_default_ver" ] && [ -d "$NVM_DIR/versions/node/v$_nvm_default_ver/bin" ]; then
    export PATH="$NVM_DIR/versions/node/v$_nvm_default_ver/bin:$PATH"
  fi
fi

_load_nvm() {
  unset -f nvm node npm npx yarn pnpm 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm() { _load_nvm; nvm "$@"; }

# Zsh Completion & Antidote Plugin Manager
export ZSH_COMPDUMP="${HOME}/.cache/.zcompdump-${ZSH_VERSION}"
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.cache/.zcompdump(#qN.mh+24) ]]; then
  compinit -d "$ZSH_COMPDUMP"
else
  compinit -C -d "$ZSH_COMPDUMP"
fi

_zsh_plugins="$HOME/.dotfiles/.zsh_plugins.txt"
_zsh_plugins_cache="${XDG_CACHE_HOME:-$HOME/.cache}/.zsh_plugins.zsh"

if [[ ! -f "$_zsh_plugins_cache" || "$_zsh_plugins" -nt "$_zsh_plugins_cache" ]]; then
  if [ -f /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ]; then
    source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
    [[ -d "${_zsh_plugins_cache:h}" ]] || mkdir -p "${_zsh_plugins_cache:h}"
    antidote bundle < "$_zsh_plugins" >| "$_zsh_plugins_cache"
  fi
fi
[[ -f "$_zsh_plugins_cache" ]] && source "$_zsh_plugins_cache"
unset _zsh_plugins _zsh_plugins_cache

# Starship Prompt
export STARSHIP_CONFIG="$HOME/.dotfiles/starship.toml"
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Zoxide (Smart directory jumping)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# FZF (Fuzzy finder keybindings: Ctrl+R for history, Ctrl+T for files)
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# Auto switch Node version when .nvmrc is found
autoload -U add-zsh-hook
load-nvmrc() {
  local dir="$PWD"
  local nvmrc_path=""
  while [[ "$dir" != "" && "$dir" != "/" ]]; do
    if [[ -f "$dir/.nvmrc" ]]; then
      nvmrc_path="$dir/.nvmrc"
      break
    fi
    dir="${dir:h}"
  done

  if [ -n "$nvmrc_path" ]; then
    _load_nvm
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -z "$(typeset -f _load_nvm)" ] && typeset -f nvm >/dev/null; then
    # Only check if nvm is fully loaded and not the stub
    if [ "$(nvm version 2>/dev/null)" != "$(nvm version default 2>/dev/null)" ]; then
      echo "Reverting to nvm default version"
      nvm use default
    fi
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Custom tokens
if [ -f ~/.dotfiles/.tokens.zsh ]; then
    source ~/.dotfiles/.tokens.zsh
fi

# Git Aliases
alias gc="cz commit"
alias ga="git add"
alias gco="git checkout"
alias gp="git push"
alias gl="git pull --rebase"
alias glc="git rev-parse HEAD | pbcopy"

# Modern CLI Aliases
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons"
  alias ll="eza -la --icons --git"
  alias tree="eza --tree --icons"
fi
if command -v bat >/dev/null 2>&1; then
  alias cat="bat --paging=never"
fi
if command -v dust >/dev/null 2>&1; then
  alias dus="dust -X .git -X node_modules"
else
  alias dus="ncdu --color dark -rr -x --exclude .git --exclude node_modules"
fi

export EDITOR="code --wait --reuse-window"
export VISUAL="code --wait --reuse-window"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000
export STM32CubeMX_PATH=/Applications/STMicroelectronics/STM32CubeMX.app/Contents/Resources

# Conda initialization (fast sourced profile, if installed)
if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
    . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
fi
