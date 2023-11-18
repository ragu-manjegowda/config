# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

ZSH_DISABLE_COMPFIX=true

# Path to your oh-my-zsh installation.
export ZSH="$ZDOTDIR/oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"
POWERLEVEL9K_MODE="nerdfont-complete"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Enable command auto-correction.
ENABLE_CORRECTION="true"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=$ZDOTDIR/zsh-custom

# Plugins to load?
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(tmux fzf-tab fzf-tab-source zsh-autosuggestions alias-finder
         custom-alias zsh-hist history-sync gitfast)

# Enable alias finder by default for every command
ZSH_ALIAS_FINDER_AUTOMATIC=true

# User configuration

# Source user profiles
[[ -e ~/.profile ]] && source ~/.profile

# Custom tab completions
fpath=($ZSH_CUSTOM/completions $fpath)
if type brew &>/dev/null; then
    fpath=($(brew --prefix)/share/zsh-completions $fpath)
fi

if [ ! -d $ZDOTDIR/.zsh.cache ]; then
  mkdir $ZDOTDIR/.zsh.cache
fi

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path $ZDOTDIR/.zsh.cache

ZSH_COMPDUMP="${ZDOTDIR}/.zcompdump-${ZSH_VERSION}"

source $ZSH/oh-my-zsh.sh

# Enable extended globbing
# https://unix.stackexchange.com/a/366137
setopt globdots

# Fix <CTRL-U> to delete till beginning of line
# https://stackoverflow.com/a/3483679
bindkey \^U backward-kill-line

# Enable fzf-tab,
# https://github.com/Aloxaf/fzf-tab/issues/137#issuecomment-716627531
enable-fzf-tab

# To customize prompt, run `p10k configure` or edit $ZDOTDIR/.p10k.zsh.
[[ ! -f $ZDOTDIR/p10k.zsh ]] || source $ZDOTDIR/p10k.zsh

if [ -f "$ZDOTDIR/fzf.zsh" ] ; then
    source "$ZDOTDIR/fzf.zsh"
fi
