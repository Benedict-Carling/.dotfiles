# Environment PATHs
export PATH="$HOME/.local/bin:$HOME/bin:/opt/homebrew/opt/openjdk/bin:$PATH"

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

# Oh My Zsh configuration & compdump cache
export ZSH_COMPDUMP="${HOME}/.cache/.zcompdump-${ZSH_VERSION}"
export ZSH="$HOME/.dotfiles/ohmyzsh"
plugins=(git)

# Plugins
source ~/.dotfiles/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.dotfiles/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Source Oh My Zsh (handles compinit caching automatically)
source $ZSH/oh-my-zsh.sh

# Starship Prompt
export STARSHIP_CONFIG="$HOME/.dotfiles/starship.toml"
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Pyenv Setup (optimized with --no-rehash)
export PYENV_ROOT="$HOME/.dotfiles/pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --no-rehash -)"

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

# Aliases
alias gc="cz commit"
alias ga="git add"
alias gco="git checkout"
alias gp="git push"
alias gl="git pull --rebase"
alias glc="git rev-parse HEAD | pbcopy"
alias dus="ncdu --color dark -rr -x --exclude .git --exclude node_modules"

export EDITOR="code --wait --reuse-window"
export VISUAL="code --wait --reuse-window"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000
export STM32CubeMX_PATH=/Applications/STMicroelectronics/STM32CubeMX.app/Contents/Resources

# Conda initialization (fast sourced profile, if installed)
if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
    . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
fi
