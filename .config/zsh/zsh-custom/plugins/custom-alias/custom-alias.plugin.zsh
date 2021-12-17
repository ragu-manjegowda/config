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

# Save command to history on if it is successful
# zshaddhistory() { whence ${${(z)1}[1]} >| /dev/null || return 1 }
zstyle ":completion:*:commands" rehash 1

############# zsh-autocomplete specific

# Wait this many seconds for typing to stop, before showing completions.
#zstyle ':autocomplete:*' min-delay 0.1  # float

# Wait until this many characters have been typed, before showing completions.
zstyle ':autocomplete:*' min-input 1  # int

zstyle ':autocomplete:history-incremental-search-*:*' list-lines 5  # int

# no:  Tab inserts the top completion.
# yes: Tab first inserts a substring common to all listed completions, if any.
#zstyle ':autocomplete:*' insert-unambiguous yes

# no:  Tab uses Zsh's completion system only.
# yes: Tab first tries Fzf's completion, then falls back to Zsh's.
zstyle ':autocomplete:*' fzf-completion no
zstyle ':autocomplete:*' fuzzy-search off

# '':     Always show completions.
# '..##': Don't show completions when the input consists of two or more dots.
zstyle ':autocomplete:*' ignored-input '.;' # extended glob pattern

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=6'

# function to toggle alacritty theme defined in colors.yml
function toggle-theme () {
    if ! test -f ~/.config/alacritty/colors.yml; then
        echo "file $HOME/.config/alacritty/colors.yml doesn't exist"
        return
    fi

    config_path="$HOME/.config/alacritty/colors.yml"

    # Get current mode
    mode=$(awk 'sub(/colors:\ \*solarized-/,""){print $1}' $config_path)

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

# Set Alacritty theme (dark/light) on Mac
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! test -f ~/.config/alacritty/colors.yml; then
        echo "file $HOME/.config/alacritty/colors.yml doesn't exist"
        return
    fi

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

            gpg --yes -v -r ${recipientName} --encrypt --sign --armor --output ${encryptedFileName} ${fileName}
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
        echo 'Usage: compresspdf [input file] [output file] [screen|ebook|printer|prepress]'
        return
    fi

    gs -sDEVICE=pdfwrite -dNOPAUSE -dQUIET -dBATCH -dPDFSETTINGS=/${3:-"screen"} -dCompatibilityLevel=1.4 -sOutputFile="$2" "$1"
}

function listAlias() {
    noglob alias -m c*
}

