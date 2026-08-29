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

# Add Homebrew to path
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

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

# FNM (Fast Node Manager - automatic version switching on cd)
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# Cargo (Rust) Setup
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Espup (ESP32 Rust toolchain) Setup
[ -f "$HOME/export-esp.sh" ] && . "$HOME/export-esp.sh"

# Zoxide (Smart directory jumping)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# FZF (Fuzzy finder keybindings: Ctrl+R for history, Ctrl+T for files)
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# Custom tokens
if [ -f ~/.dotfiles/.tokens.zsh ]; then
    source ~/.dotfiles/.tokens.zsh
fi

# Git Aliases
alias gc="git commit"
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
