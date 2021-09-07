# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

ZSH_DISABLE_COMPFIX=true

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"
POWERLEVEL9K_MODE="nerdfont-complete"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Enable command auto-correction.
ENABLE_CORRECTION="true"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=$HOME/.zsh-custom

# Plugins to load?
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(tmux zsh-autocomplete zsh-autosuggestions alias-finder custom-alias
         zsh-hist)

# Enable alias finder by default for every command
ZSH_ALIAS_FINDER_AUTOMATIC=true

# User configuration

# Source user profiles
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    # Source bashrc
    [[ -e ~/.profile ]] && emulate sh -c 'source ~/.profile'
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Source bash_profile
    [[ -e ~/.bash_profile ]] && emulate sh -c 'source ~/.bash_profile'
fi

# Brew completion
if type brew &>/dev/null; then
    fpath=($(brew --prefix)/share/zsh/site-functions $fpath)
fi

# Custom tab completions
fpath=($ZSH_CUSTOM/completions $fpath)

if [ ! -d ~/.zsh.cache ]; then
  mkdir ~/.zsh.cache
fi

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh.cache

source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

