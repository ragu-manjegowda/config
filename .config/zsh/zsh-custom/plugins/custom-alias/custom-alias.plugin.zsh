# Git version checking
autoload -Uz is-at-least
git_version="${${(As: :)$(git version 2>/dev/null)}[3]}"

#
# Functions
#

# The name of the current branch
# Back-compatibility wrapper for when this function was defined here in
# the plugin, before being pulled in to core lib/git.zsh as git_current_branch()
# to fix the core -> git plugin dependency.
function current_branch() {
  git_current_branch
}

# Pretty log messages
function _git_log_prettily(){
  if ! [ -z $1 ]; then
    git log --pretty=$1
  fi
}
compdef _git _git_log_prettily=git-log

# Warn if the current branch is a WIP
function work_in_progress() {
  if $(git log -n 1 2>/dev/null | grep -q -c "\-\-wip\-\-"); then
    echo "WIP!!"
  fi
}

# Check if main exists and use instead of master
function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in main trunk; do
    if command git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return
    fi
  done
  echo master
}

#
# Aliases
# (sorted alphabetically)
#

alias ga='git add'
alias gb='git branch'

alias gc='git commit -s'
alias gcan='git commit --amend --no-edit'

alias gcl='git clone --recurse-submodules'
alias gco='git checkout'

alias gd='git diff'
alias gdc='git diff --cached'

# --jobs=<n> was added in git 2.8
is-at-least 2.8 "$git_version" \
  && alias gfa='git fetch --all --prune --jobs=10' \
  || alias gfa='git fetch --all --prune'


alias glog='git log --oneline --decorate --graph'
alias glogp="_git_log_prettily"

alias gpush='git push origin "$(git_current_branch)"'
alias gpulla='git pull --rebase --autostash'

alias gst='git status'
alias gstv='vim +Git +only'
alias gsu='git submodule update --init --recursive'

function grename() {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 old_branch new_branch"
    return 1
  fi

  # Rename branch locally
  git branch -m "$1" "$2"
  # Rename branch in origin remote
  if git push origin :"$1"; then
    git push --set-upstream origin "$2"
  fi
}

unset git_version

# Unset alias l
unalias \l

# Define custom aliases
alias l='ls'
alias ldot='ls -d .*'

# use nvim if installed, vi default
case "$(command -v nvim)" in
    */nvim)
        VIM=nvim
        alias vim="nvim"
        ;;
    *)  VIM=vi ;;
esac

export EDITOR=$VIM
export FCEDIT=$EDITOR

# Zsh-hist
HISTSIZE=10000000
SAVEHIST=8000000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.

# Save command to history only if it is successful
zshaddhistory() { whence ${${(z)1}[1]} >| /dev/null || return 1 }
zstyle ":completion:*:commands" rehash 1

############# zsh-autocomplete specific

# '': Start each new command line with normal autocompletion.
# history-incremental-search-backward: Start in live history search mode.
zstyle ':autocomplete:*' default-context ''

# Wait this many seconds for typing to stop, before showing completions.
#zstyle ':autocomplete:*' min-delay 0.1  # float

# Wait until this many characters have been typed, before showing completions.
zstyle ':autocomplete:*' min-input 1  # int

# '':     Always show completions.
# '..##': Don't show completions when the input consists of two or more dots.
zstyle ':autocomplete:*' ignored-input ';;##' # extended glob pattern

# If there are fewer than this many lines below the prompt, move the prompt up
# to make room for showing this many lines of completions (approximately).
zstyle ':autocomplete:*' list-lines 5  # int

# Show this many history lines when pressing ↑.
zstyle ':autocomplete:history-search:*' list-lines 5  # int

# no:  Tab inserts the top completion.
# yes: Tab first inserts a substring common to all listed completions, if any.
zstyle ':autocomplete:*' insert-unambiguous no

# complete-word: (Shift-)Tab inserts the top (bottom) completion.
# menu-complete: Press again to cycle to next (previous) completion.
# menu-select:   Same as `menu-complete`, but updates selection in menu.
zstyle ':autocomplete:*' widget-style complete-word

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=6'

# function to toggle alacritty theme defined in colors.yml
function toggle-alacritty-theme () {
    if ! test -f ~/.config/alacritty/colors.yml; then
        echo "file $HOME/.config/alacritty/colors.yml doesn't exist"
        return
    fi

    config_path="$HOME/.config/alacritty/colors.yml"

    # Get current mode
    mode=$(awk 'sub(/colors:'\ '\*solarized-/,""){print $1}' $config_path)

    case $mode in
        light)
            sed -i -e "s#^colors: \*.*#colors: *solarized-dark#g" $config_path
            export BAT_THEME="Solarized (dark)"
            ;;
        dark)
            sed -i -e "s#^colors: \*.*#colors: *solarized-light#g" $config_path
            export BAT_THEME="Solarized (light)"
            ;;
    esac

    echo "switched away from $mode."
}

# function to toggle GTK theme defined in xsettingsd.conf
function toggle-gtk-theme () {
    if [[ "$OSTYPE" != "linux-gnu" ]]; then
        echo "Supported only on Linux!"
        return
    fi

    config_path="$HOME/.config/xsettingsd/xsettingsd.conf"
    if ! test -f $config_path; then
        echo "file $config_path doesn't exist"
        return
    fi

    mode=$(awk -F '["]' 'sub(/Net\/ThemeName'\ ''\"'Adwaita-/,""){print $1}' $config_path)

    case $mode in
        light)
            sed -i -e "s#-light#-dark#g" $config_path
            ;;
        dark)
            sed -i -e "s#-dark#-light#g" $config_path
            ;;
    esac

    eval "killall -HUP xsettingsd"

    echo "switched away from $mode."
}

# Set BAT theme for FZF on linux (in Mac it is set below)
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if ! test -f ~/.config/alacritty/colors.yml; then
        echo "file $HOME/.config/alacritty/colors.yml doesn't exist"
    else
        config_path="$HOME/.config/alacritty/colors.yml"
        if grep -Fxq "colors: *solarized-dark" "$config_path"; then
            export BAT_THEME="Solarized (dark)"
        else
            export BAT_THEME="Solarized (light)"
        fi
    fi
fi

# Set Alacritty theme (dark/light) on Mac
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! test -f ~/.config/alacritty/colors.yml; then
        echo "file $HOME/.config/alacritty/colors.yml doesn't exist"
    else
        config_path="$HOME/.config/alacritty/colors.yml"

        # Get current mode
        mode=$(defaults read -g AppleInterfaceStyle 2>/dev/null)

        case $mode in
            Dark)
                sed -i -e "s#^colors: \*.*#colors: *solarized-dark#g" $config_path
                export BAT_THEME="Solarized (dark)"
                ;;
            *)
                sed -i -e "s#^colors: \*.*#colors: *solarized-light#g" $config_path
                export BAT_THEME="Solarized (light)"
                ;;
        esac
    fi
fi

# function to encrypt and decrypt files
function gpg-encrypt-decrypt () {
    if ! type gpg > /dev/null; then
        echo "command `gpg` doesn't exist"
        return
    fi

    echo "Welcome to gpg file encryption/decryption"
    echo "0: Encrypt"
    echo "1: Decrypt"
    echo -n "Enter your choice: "
    read cipherChoice

    case $cipherChoice in
        0)
            echo "Requested encryption"
            cipher=encrypt
            ;;
        1)
            echo "Requested decryption"
            cipher=decrypt
            ;;
        *)
            echo "No kidding please!!"
            return
            ;;
    esac

    case $cipher in
        encrypt)
            echo -n "Enter GPG recipient name: "
            read recipientName

            vared -p "Enter name of the file to be encrypted: " -c fileName

            if ! test -f "$fileName"; then
                echo "File does not exist"
                return
            fi

            encryptedFileName="${fileName}_encrypted"
            echo "Enter encrypted file name (default $encryptedFileName): "
            vared encryptedFileName

            gpg --yes -v -r ${recipientName} --encrypt --sign --armor \
                --output ${encryptedFileName} ${fileName}
            ;;

        decrypt)
            vared -p "Enter name of the file to be decrypted: " -c fileName

            if ! test -f "$fileName"; then
                echo "File does not exist"
                return
            fi

            decryptedFileName="${fileName}_decrypted"
            echo "Enter decrypted file name (default $decryptedFileName): "
            vared decryptedFileName

            gpg --output ${decryptedFileName} --decrypt ${fileName}
            ;;
    esac
}

function cliclick()
{
    while true; do xdotool click 1; sleep 120; done
}

function compresspdf() {
    if [[ "$1" == "--help" ]]; then
        echo 'Usage: compresspdf [input file] [output file] \
            [screen|ebook|printer|prepress]'
        return
    fi

    gs -sDEVICE=pdfwrite -dNOPAUSE -dQUIET -dBATCH \
        -dPDFSETTINGS=/${3:-"screen"} -dCompatibilityLevel=1.4 \
        -sOutputFile="$2" "$1"
}

function listAlias() {
    noglob alias -m c*
}

function start-http-web-server () {
    if ! type http-file-server > /dev/null; then
        echo "Download binary: "
        echo "For Linux: "
        echo "curl -L https://github.com/sgreben/http-file-server/releases/\
                download/1.6.1/http-file-server_1.6.1_linux_x86_64.tar.gz | \
                tar xz"
        echo "For Mac: "
        echo "curl -L https://github.com/sgreben/http-file-server/releases/\
                download/1.6.1/http-file-server_1.6.1_osx_x86_64.tar.gz | \
                tar xz"
        return
    fi

    echo "Welcome to file http-file-server"
    echo "0: Download Server only"
    echo "1: Upload/Download Server"
    echo -n "Enter your choice: "
    read serverChoice

    case $serverChoice in
        0)
            echo "Requested to start download server"
            serverType=downloadOnly
            ;;
        1)
            echo "Requested upload server"
            serverType=allowUpload
            ;;
        *)
            echo "No kidding please!!"
            return
            ;;
    esac

    echo -n "Enter server address: "
    read serverAddress

    echo -n "Enter server port: "
    read port

    vared -p "Enter path to be served: " -c serverPath

    echo -e "\033[0;31mTo download from command line use: "
    echo -e "curl -O ${serverAddress}:${port}/path_from_below/filename\033[0m\n"

    case $serverType in
        downloadOnly)
            http-file-server -a $serverAddress:$port $serverPath
            ;;

        allowUpload)
            echo -e "\033[0;31mTo upload from command line use: "
            echo -e "curl -LF 'file=@example.txt' \
                ${serverAddress}:${port}/path_from_below\033[0m\n"
            http-file-server -u -a $serverAddress:$port $serverPath
            ;;
    esac
}

###############################################################################
#################################### FZF ######################################
###############################################################################

is_in_git_repo() {
  git rev-parse HEAD > /dev/null 2>&1 || echo "This_is_not_a_git_repository"
}

FZF_PREFIX="fzf-git"

PREFIX_BIND_OPTS1="ctrl-j:preview-down,ctrl-k:preview-up"
PREFIX_BIND_OPTS2=",ctrl-w:toggle-preview-wrap,ctrl-f:jump"
PREFIX_BIND_OPTS3=",ctrl-u:preview-top,ctrl-d:preview-bottom"
PREFIX_BIND_OPTS="$PREFIX_BIND_OPTS1$PREFIX_BIND_OPTS2$PREFIX_BIND_OPTS3"

function "${FZF_PREFIX}gg" () {
  config -c color.status=always status --short |
  fzf -m --ansi --nth 2..,.. \
    --preview '(git --git-dir=$HOME/.config.git/ --work-tree=$HOME diff \
    --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' \
    --bind "${PREFIX_BIND_OPTS}" |
  cut -c4- | sed 's/.* -> //'
}

function "${FZF_PREFIX}gh" () {
  is_in_git_repo || return
  git -c color.status=always status --short |
  fzf -m --ansi --nth 2..,.. \
    --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | \
    head -500' \
    --bind "${PREFIX_BIND_OPTS}" |
  cut -c4- | sed 's/.* -> //'
}

join-lines() {
  local item
  while read item; do
    echo -n "${(q)item} "
  done
}

bind-git-helper() {
  local char
  for c in $@; do
    eval "fzf-g$c-widget() { local result=\$(${FZF_PREFIX}g$c | join-lines); \
        zle reset-prompt; LBUFFER+=\$result }"
    eval "zle -N fzf-g$c-widget"
    eval "bindkey '^[$c' fzf-g$c-widget"
  done
}

bind-git-helper g h
unset -f bind-git-helper

###############################################################################
########################### ZSH History merge #################################
###############################################################################

function merge-zsh-history () {
    eval "${ZDOTDIR}/merge_zsh_histories.rb ${ZDOTDIR}/.zsh_history_*.bak \
          ${ZDOTDIR}/.zsh_history > ${HOME}/zsh_history_merged"
}

###############################################################################
############################### notflix #######################################
###############################################################################

function notflix() {
    eval "${ZDOTDIR}/notflix $@"
}

###############################################################################
################################  ytfzf #######################################
###############################################################################

function ytfzf() {
    eval "${ZDOTDIR}/ytfzf $@"
}


###############################################################################
########################### grep-functions ####################################
###############################################################################

function grep-functions() {
    print -l ${(ok)functions} | fzf
}


###############################################################################
############################## kill-process ###################################
###############################################################################

function kill-process() {
    ### PROCESS
    # mnemonic: [K]ill [P]rocess
    # show output of "ps -ef", use [tab] to select one or multiple entries
    # press [enter] to kill selected processes and go back to the process list.
    # or press [escape] to go back to the process list.
    # Press [escape] twice to exit completely.

    local pid=$(ps -ef | sed 1d | eval "fzf ${FZF_DEFAULT_OPTS} \
                -m --header='[kill:process]'" | awk '{print $2}')

    if [ "x$pid" != "x" ]
    then
      echo $pid | xargs kill -${1:-9}
      $(kill-process)
    fi
}


###############################################################################
######################### merge-images-diagonally #############################
###############################################################################

function merge-images-diagonally() {
    eval "${ZDOTDIR}/merge-images-diagonally.sh $@"
}

