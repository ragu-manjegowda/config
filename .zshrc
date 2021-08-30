# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="ragu"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Enable command auto-correction.
ENABLE_CORRECTION="true"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=$HOME/.zsh-custom

# Plugins to load?
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(tmux zsh-autosuggestions zsh-autocomplete alias-finder custom-alias
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
