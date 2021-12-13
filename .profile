# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

export PAGER=less
export LESS='-iMRS -x2'
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# prevent less from saving history in ~/.lesshst
export LESSHISTFILE=/dev/null

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"

export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
export BASH_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bash"
export GPG_TTY=$TTY
export GNUPGHOME="${XDG_CONFIG_HOME:-$HOME/.config}/gnupg"

export RANGER_LOAD_DEFAULT_RC=FALSE

# if running bash
if [ -n "$BASH_VERSION" ]; then

    # include .bashrc if it exists
    if [ -f "$BASH_DIR/bashrc" ]; then
        source "$BASH_DIR/bashrc"
    fi

    HISTFILE="$BASH_DIR/.bash_history"

# if running zsh
elif [ -n "$ZSH_VERSION" ]; then

    HISTFILE="$ZDOTDIR/.zsh_history"

fi

if [[ "$OSTYPE" == "linux-gnu" ]]; then

    # if running zsh
    if [ -n "$ZSH_VERSION" ]; then

        # include .bash_custom if it exists
        if [ -f "$BASH_DIR/bash_custom" ]; then
            source "$BASH_DIR/bash_custom"
        fi

    fi

    # set PATH so it includes user's private bin directories
    PATH="$HOME/bin:$HOME/.local/bin:$PATH"

elif [[ "$OSTYPE" == "darwin"* ]]; then

    # include .bash_profile if it exists
    if [ -f "$BASH_DIR/bash_profile" ]; then
  	    source "$BASH_DIR/bash_profile"
    fi

fi

## Config alias
alias config='git --git-dir=$HOME/.config.git/ --work-tree=$HOME'
alias cvim='GIT_DIR=$HOME/.config.git/ GIT_WORK_TREE=$HOME vim'
alias ca='config add'
alias ccd='config diff'
alias ccm='config commit -s'
alias cco='config checkout'
alias cfa='config fetch --all --prune'
alias clog='config log'
alias cpulla='config pull --rebase --autostash'
alias cpush='config push'
alias cst='config status'
alias csu='config submodule update --init --recursive'

# fzf
export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden'
export FZF_DEFAULT_OPTS='--no-height --color=bg+:#343d46,gutter:-1,pointer:#ff3c3c,info:#0dbc79,hl:#0dbc79,hl+:#23d18b'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"
export FZF_ALT_C_COMMAND='fd --type d . --color=never --hidden'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -50'"

