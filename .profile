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
export XDG_CACHE_HOME="$HOME/.cache"

export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
export BASH_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bash"
export GPG_TTY=$TTY
export GNUPGHOME="${XDG_CONFIG_HOME:-$HOME/.config}/gnupg"

export RANGER_LOAD_DEFAULT_RC=FALSE

# Not thoroughly tested for all side effectes
export TERM=xterm-256color
export COLORTERM="truecolor"

# if running bash
if [ -n "$BASH_VERSION" ]; then

    # include .bashrc if it exists
    if [ -f "$BASH_DIR/bashrc" ]; then
        source "$BASH_DIR/bashrc"
    fi

    HISTFILE="$BASH_DIR/.bash_history"

# if running zsh
elif [ -n "$ZSH_VERSION" ]; then

    ## .profile is always sourced by zsh, safe to add this here
    HISTFILE="$ZDOTDIR/.zsh_history"

    ## Back up zsh_history
    cp ${HISTFILE} ${ZDOTDIR}/.zsh_history_$(date +\%Y_\%m_\%d).bak

fi

if [[ "$OSTYPE" == "linux-gnu" ]]; then

    # include .bash_custom if it exists
    if [ -f "$BASH_DIR/bash_custom" ]; then
        source "$BASH_DIR/bash_custom"
    fi

    if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
        source $HOME/.nix-profile/etc/profile.d/nix.sh;
    fi

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
alias cstv='cvim +Git +only'
alias csu='config submodule update --init --recursive'

# fzf
export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden'
FZF_ROOT_SEARCH_COMMAND='fd --type f . / --color=never'
FZF_HOME_SEARCH_COMMAND='fd --type f . $HOME --color=never --hidden'

FZF_DEFAULT_OPTS1="--no-height --color=bg+:#343d46,gutter:-1"
FZF_DEFAULT_OPTS2=",pointer:#ff3c3c,info:#0dbc79,hl:#0dbc79,hl+:#23d18b"
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS1$FZF_DEFAULT_OPTS2"

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

T_OPTS_PREVIEW="--preview 'bat --color=always {}'"
T_OPTS_BIND_OPTS1="--bind 'ctrl-j:preview-down,ctrl-k:preview-up'"
T_OPTS_BIND_OPTS2="',ctrl-w:toggle-preview-wrap,ctrl-f:jump'"
T_OPTS_BIND_OPTS3="',ctrl-u:preview-top,ctrl-d:preview-bottom'"
T_OPTS_BIND_OPTS4="',ctrl-h:reload($FZF_HOME_SEARCH_COMMAND),ctrl-r:reload($FZF_ROOT_SEARCH_COMMAND)'"
FZF_CTRL_T_OPTS="$T_OPTS_PREVIEW $T_OPTS_BIND_OPTS1$T_OPTS_BIND_OPTS2$T_OPTS_BIND_OPTS3"
export FZF_CTRL_T_OPTS="${FZF_CTRL_T_OPTS}$T_OPTS_BIND_OPTS4"

export FZF_ALT_C_COMMAND='fd --type d . --color=never --hidden'
FZF_ROOT_D_SEARCH_COMMAND='fd --type d . / --color=never'
FZF_HOME_D_SEARCH_COMMAND='fd --type d . $HOME --color=never --hidden'

C_OPTS_PREVIEW="--preview 'tree -C {}'"
C_OPTS_BIND_OPTS1="--bind 'ctrl-j:preview-down,ctrl-k:preview-up'"
C_OPTS_BIND_OPTS2="',ctrl-w:toggle-preview-wrap,ctrl-f:jump'"
C_OPTS_BIND_OPTS3="',ctrl-u:preview-top,ctrl-d:preview-bottom'"
C_OPTS_BIND_OPTS4="',ctrl-h:reload($FZF_HOME_D_SEARCH_COMMAND),ctrl-r:reload($FZF_ROOT_D_SEARCH_COMMAND)'"
FZF_ALT_C_OPTS="$C_OPTS_PREVIEW $C_OPTS_BIND_OPTS1$C_OPTS_BIND_OPTS2$C_OPTS_BIND_OPTS3"
export FZF_ALT_C_OPTS="${FZF_ALT_C_OPTS}$C_OPTS_BIND_OPTS4"

export FZF_TMUX_OPTS="-d 70%"

