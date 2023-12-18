# Needed to add poetry
export PATH="/Users/benedictcarling/.local/bin:$PATH"
# Add Java in path
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

export NVM_DIR="$HOME/.dotfiles/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# This is needed for the signing of GPG keys
export GPG_TTY=$(tty)

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Add Homebrew to path
eval "$(/opt/homebrew/bin/brew shellenv)"

# To tell Oh My Zsh to store zcompdum not in root home folder
export ZSH_COMPDUMP="${HOME}/.cache/.zcompdump-${ZSH_VERSION}"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.dotfiles/ohmyzsh"

# Source zsh theme
source ~/.dotfiles/powerlevel10k/powerlevel10k.zsh-theme

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

# Add autocompletion plugin
source ~/.dotfiles/zsh-autosuggestions/zsh-autosuggestions.zsh

# Add syntax highlighting plugin (this should be the last plugin installed)
source ~/.dotfiles/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Source oh my zsh
source $ZSH/oh-my-zsh.sh


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.dotfiles/.p10k.zsh ]] || source ~/.dotfiles/.p10k.zsh

# PYENV Setup
export PYENV_ROOT="$HOME/.dotfiles/pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

if [ -f ~/.dotfiles/.tokens.zsh ]; then
    source ~/.dotfiles/.tokens.zsh
fi

alias gc="cz commit"
alias ga="git add"
alias gco="git checkout"
alias gco="git checkout"
alias gp="git push"
alias gl="git pull"
alias glc="git rev-parse HEAD | pbcopy"