###############################################################################
## Author       : Ragu Manjegowda
## Github       : @ragu-manjegowda
###############################################################################

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

# Not thoroughly tested for all side effectes
export COLORTERM="truecolor"

# if running bash
if [ -n "$BASH_VERSION" ]; then

    # include .bashrc if it exists
    if [ -f "$BASH_DIR/bashrc" ]; then
        # shellcheck disable=SC1091
        source "$BASH_DIR/bashrc"
    fi

    HISTFILE="$BASH_DIR/.bash_history"

# if running zsh
elif [ -n "$ZSH_VERSION" ]; then

    ## .profile is always sourced by zsh, safe to add this here
    HISTFILE="$ZDOTDIR/.zsh_history"

    ## Back up zsh_history
    cp "${HISTFILE}" "${ZDOTDIR}"/.zsh_history_"$(date +%Y_%m_%d)".bak

fi

if [[ "$OSTYPE" == "linux-gnu" ]]; then

    # include .bash_custom if it exists
    if [ -f "$BASH_DIR/bash_custom" ]; then
        # shellcheck disable=SC1091
        source "$BASH_DIR/bash_custom"
    fi

elif [[ "$OSTYPE" == "darwin"* ]]; then

    # include .bash_profile if it exists
    if [ -f "$BASH_DIR/bash_profile" ]; then
        # shellcheck disable=SC1091
  	    source "$BASH_DIR/bash_profile"
    fi

fi

## Export local bin folder
if [ -d "$HOME"/.local/bin ]; then
    # shellcheck disable=SC1091
    export PATH="$HOME"/.local/bin:"$PATH"
fi

if [ -d "$HOME"/.local/share/venv/bin ]; then
    # shellcheck disable=SC1091
    export PATH="$HOME"/.local/share/venv/bin:"$PATH"
fi

# use nvim if installed,
# if not use vim
# else vi
case "$(command -v nvim)" in
    */nvim)
        VIM="nvim"
        VISUAL="nvim --cmd 'let g:flatten_wait=1'"
        alias vim="nvim"
        alias vimfast="nvim --cmd '+lua vim.g.blazing_fast=1'"
        alias vimfastx="nvim --cmd '+lua vim.g.blazing_fast=2'"
        ;;
    *)
        case "$(command -v vim)" in
            */vim)
                VIM="vim"
                VISUAL="vim"
                ;;
            *)
                VIM="vi"
                VISUAL="vi"
                ;;
        esac
        ;;
esac

export EDITOR=$VIM
export MANPAGER="$VIM +Man!"
export VISUAL=$VISUAL
export FCEDIT=$EDITOR

# alias bat to cat
case "$(command -v bat)" in
    */bat)
        alias cat="bat"
        ;;
    *)
        ;;
esac

# alias htop to top
case "$(command -v htop)" in
    */htop)
        alias top="htop"
        ;;
    *)
        ;;
esac

###############################################################################
########################             FZF                      #################
###############################################################################

########################           Git FZF                      ###############
if [ -f "$HOME/.config/fzf-git/fzf-git.sh" ]; then
    source "$HOME/.config/fzf-git/fzf-git.sh"
fi

########################             Defaults                 #################
FZF_DEFAULT_OPTS1="--no-height --cycle --color=bg+:#343d46,gutter:-1"
FZF_DEFAULT_OPTS2=",pointer:#ff3c3c,info:#0dbc79,hl:#0dbc79,hl+:#23d18b"

FZF_DEFAULT_BIND_OPTS1="--bind 'alt-j:preview-page-down,alt-k:preview-page-up'"
FZF_DEFAULT_BIND_OPTS2="',ctrl-j:down,ctrl-k:up,ctrl-/:toggle-preview'"
FZF_DEFAULT_BIND_OPTS3="',ctrl-w:toggle-preview-wrap,alt-/:jump'"
FZF_DEFAULT_BIND_OPTS4="',ctrl-u:preview-top,ctrl-d:preview-bottom'"
FZF_DEFAULT_BIND_OPTS5="',ctrl-g:last,ctrl-a:select-all,ctrl-x:deselect-all'"

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    FZF_DEFAULT_BIND_OPTS6="',ctrl-y:execute-silent(echo -n {} | xclip -sel clip)'"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    FZF_DEFAULT_BIND_OPTS6="',ctrl-y:execute-silent(echo -n {} | pbcopy)'"
fi

FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS1$FZF_DEFAULT_OPTS2"
FZF_BIND_OPTS1="$FZF_DEFAULT_BIND_OPTS1$FZF_DEFAULT_BIND_OPTS2$FZF_DEFAULT_BIND_OPTS3"
FZF_BIND_OPTS2="$FZF_DEFAULT_BIND_OPTS4$FZF_DEFAULT_BIND_OPTS5$FZF_DEFAULT_BIND_OPTS6"

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} ${FZF_BIND_OPTS1}${FZF_BIND_OPTS2}"

export FZF_DEFAULT_COMMAND="fd --type f --color=never --hidden"

########################             CTRL-T                 ###################
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

FZF_ROOT_SEARCH_T_COMMAND="fd --type f . / --color=never"
FZF_HOME_SEARCH_T_COMMAND="fd --type f . $HOME --color=never --hidden"

T_OPTS_PREVIEW="--preview 'bat --color=always {}'"
T_OPTS_BIND_OPTS1="--bind 'ctrl-h:reload($FZF_HOME_SEARCH_T_COMMAND)'"
T_OPTS_BIND_OPTS2="',ctrl-r:reload($FZF_ROOT_SEARCH_T_COMMAND)'"

export FZF_CTRL_T_OPTS="$T_OPTS_PREVIEW $T_OPTS_BIND_OPTS1$T_OPTS_BIND_OPTS2"

########################             ALT-C                 ####################
export FZF_ALT_C_COMMAND="fd --type d . --color=never --hidden"

FZF_ROOT_D_SEARCH_COMMAND="fd --type d . / --color=never"
FZF_HOME_D_SEARCH_COMMAND="fd --type d . $HOME --color=never --hidden"

C_OPTS_PREVIEW="--preview 'tree -C {}'"
C_OPTS_BIND_OPTS1="--bind 'ctrl-h:reload($FZF_HOME_D_SEARCH_COMMAND)'"
C_OPTS_BIND_OPTS2="',ctrl-r:reload($FZF_ROOT_D_SEARCH_COMMAND)'"

export FZF_ALT_C_OPTS="$C_OPTS_PREVIEW $C_OPTS_BIND_OPTS1$C_OPTS_BIND_OPTS2"

########################             CTRL-R                 ###################
R_OPTS_PREVIEW="--preview 'echo {}' --preview-window down:3:hidden:wrap"

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    R_BIND_OPTS1="--bind 'ctrl-y:execute-silent(echo -n {2..} | xclip -sel clip)'"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    R_BIND_OPTS1="--bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)'"
fi

export FZF_CTRL_R_OPTS="${R_OPTS_PREVIEW} ${R_BIND_OPTS1}"

########################             TMUX                   ###################
export FZF_TMUX_OPTS="-p95%,90%"

###############################################################################
###############################################################################

# Paru, Pacman fzf
if [ -f "/etc/arch-release" ]; then
    alias pars='paru --color always -Sl | \
        sed -e "s: :/:; s/ unknown-version//; /installed/d" | \
        fzf --multi --ansi --preview "paru -Si {1}" | xargs -ro paru -S'

    alias pacr="pacman --color always -Q | cut -f 1 -d ' ' | \
        fzf --multi --ansi --preview 'pacman -Qi {1}' | xargs -ro sudo pacman -Rns"
fi

# Make keyboard more responsive
# https://www.reddit.com/r/vim/comments/foop8s/comment/flgcqc7/?utm_source=share&utm_medium=web2x&context=3
if command -v xset &> /dev/null; then
    if [ -n "$DISPLAY" ]; then
        xset r rate 200 25
    fi
fi
