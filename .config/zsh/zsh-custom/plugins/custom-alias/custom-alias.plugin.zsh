################## Git aliases ################################################

# Git version checking
autoload -Uz is-at-least
git_version="${${(As: :)$(git version 2>/dev/null)}[3]}"

#
# Functions
#

# Pretty log messages
function _git_log_prettily(){
  if ! [ -z $1 ]; then
    git log --pretty=$1 "${@:2}"
  fi
}
compdef _git _git_log_prettily=git-log

#
# Aliases
# (sorted alphabetically)
#

alias ga='git add'
alias gb='git branch --column'

function gbb () {
    eval better-git-branch.sh
}

alias gbl='git blame -w -C -C -C'

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


alias gpush='git push origin "$(git_current_branch)"'
alias gpulla='git pull --rebase --autostash'

alias gst='git status'
alias gstv='vim +Git +only'
alias gsu='git submodule foreach git pull --recurse-submodules --rebase'

unset git_version

################## config aliases #############################################

## Config alias
alias config='git --git-dir=$HOME/.config.git/ --work-tree=$HOME'
alias cvim='GIT_DIR=$HOME/.config.git/ GIT_WORK_TREE=$HOME vim'

# Pretty log messages
function _config_log_prettily(){
  if ! [ -z $1 ]; then
    config log --pretty=$1 "${@:2}"
  fi
}
compdef _git _config_log_prettily=git-log

alias ca='config add'
alias ccd='config diff'
alias ccds='config diff --cached'
alias ccda='config diff HEAD'
alias ccm='config commit -s'
alias cco='config checkout'
alias cfa='config fetch --all --prune'
alias cpulla='config pull --rebase --autostash'
alias cpush='config push'
alias cst='config status'
alias cstv='cvim +Git +only'
# alias csu='config submodule update --remote --rebase'
alias csu='config submodule foreach git pull --recurse-submodules --rebase'

compdef _git config

######################   Git FZF Aliases   ####################################

_fzf_git_fzf() {
  fzf -- \
    --layout=reverse --multi --border \
    --border-label-pos=2 \
    --color='header:italic:underline,label:blue' \
    --preview-window='right,border-left' \
    --bind='ctrl-/:change-preview-window(down,border-top|hidden|)' "$@"
}

_fzf_config_files() {
  GIT_DIR="$HOME/.config.git" WORK_TREE="$HOME" _fzf_git_files
}

_fzf_config_branches() {
  GIT_DIR="$HOME/.config.git" WORK_TREE="$HOME" _fzf_git_branches
}

_fzf_config_tags() {
  GIT_DIR="$HOME/.config.git" WORK_TREE="$HOME" _fzf_git_tags
}

_fzf_config_hashes() {
  GIT_DIR="$HOME/.config.git" WORK_TREE="$HOME" _fzf_git_hashes
}

_fzf_config_remotes() {
  GIT_DIR="$HOME/.config.git" WORK_TREE="$HOME" _fzf_git_remotes
}

_fzf_config_stashes() {
  GIT_DIR="$HOME/.config.git" WORK_TREE="$HOME" _fzf_git_stashes
}

_fzf_config_lreflogs() {
  GIT_DIR="$HOME/.config.git" WORK_TREE="$HOME" _fzf_git_lreflogs
}

_fzf_config_each_ref() {
  GIT_DIR="$HOME/.config.git" WORK_TREE="$HOME" _fzf_git_each_ref
}

_fzf_config_worktrees() {
  GIT_DIR="$HOME/.config.git" WORK_TREE="$HOME" _fzf_git_worktrees
}

__fzf_config_join() {
    local item
    while read item; do
        echo -n "${(q)item} "
    done
}

__fzf_config_init() {
    local m o
    for o in "$@"; do
    {
        eval "fzf-config-$o-widget() { local result=\$(_fzf_config_$o | __fzf_config_join); \
            zle reset-prompt; LBUFFER+=\$result }"

        eval "zle -N fzf-config-$o-widget"

        for m in emacs vicmd viins; do
            eval "bindkey -M $m '^[g${o[1]}' fzf-config-$o-widget"
        done
    }
    done
}

__fzf_config_init files branches tags remotes hashes stashes lreflogs each_ref worktrees

unset -f __fzf_config_init

#################### list alias ###############################################

# Unset alias l
unalias \l

# Define custom aliases
alias l='ls'
function ldot() {
    if [[ $# -ne 1 ]]; then
        ls -d .*
    else
        ls -d $1/.*
    fi
}

####################### zsh history settings ##################################

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

# Remove annoying % at the end of partial line
export PROMPT_EOL_MARK=""

# Save command to history only if it is successful
zshaddhistory() { whence ${${(z)1}[1]} >| /dev/null || return 1 }
zstyle ":completion:*:commands" rehash 1

############# zsh-autocomplete specific #######################################

# Set completion color to yellow
zstyle ':fzf-tab:*' default-color "$fg[yellow]"

# Preview completion
zstyle ':fzf-tab:complete:*:*' fzf-preview 'less ${(Q)realpath}'

zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
	fzf-preview 'echo ${(P)word}'

export LESSOPEN='|$HOME/.config/zsh/lessfilter %s'

# Set hl color
zstyle ':fzf-tab:*' fzf-flags '--color=hl:green'

# Custom binding
zstyle ':fzf-tab:complete:*' fzf-bindings 'tab:toggle+down,shift-tab:toggle-all'

############# zsh-autosuggestion specific #####################################

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=yellow,bold,underline"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '^[/' autosuggest-fetch

######################### dirstack ############################################

# Store 10 recent directories
# Ref: https://wiki.archlinux.org/title/zsh#Tips_and_tricks
autoload -Uz add-zsh-hook

DIRSTACKFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/dirs"
if [[ -f "$DIRSTACKFILE" ]] && (( ${#dirstack} == 0 )); then
	dirstack=("${(@f)"$(< "$DIRSTACKFILE")"}")
	[[ -d "${dirstack[1]}" ]] && cd -- "${dirstack[1]}"
fi

chpwd_dirstack() {
	print -l -- "$PWD" "${(u)dirstack[@]}" > "$DIRSTACKFILE"
}

add-zsh-hook -Uz chpwd chpwd_dirstack

DIRSTACKSIZE='10'

setopt AUTO_PUSHD PUSHD_SILENT PUSHD_TO_HOME

## Remove duplicate entries
setopt PUSHD_IGNORE_DUPS

## This reverts the +/- operators.
setopt PUSHD_MINUS

###################### word navigation ########################################

# Bash-like navigation
autoload -U select-word-style
select-word-style bash

###############################################################################

# function to toggle alacritty theme defined in colors.yml
function toggle-alacritty-theme () {
    if ! test -r ~/.config/alacritty/themes; then
        echo "Directory $HOME/.config/alacritty/themes doesn't exist"
        return
    fi

    config_path="$HOME/.config/alacritty/alacritty.toml"
    git_config_path="$HOME/.config/git/config"
    broot_config_path="$HOME/.config/broot/conf.hjson"
    vim_config_path="$HOME/.config/nvim/lua/user/colorscheme.lua"
    zathura_config_path="$HOME/.config/zathura/zathurarc"
    termshark_config_path="$HOME/.config/termshark/termshark.toml"
    wiki_script_path="$HOME/.local/bin/render-wiki.sh"

    # Get current mode
    mode=$(awk -F'/' '/solarized/ {gsub(/\[|"|\]|solarized_|.toml/,""); print $(NF)}' $config_path)

    case $mode in
        light)
            sed -i -e "s#solarized_light#solarized_dark#g" $config_path
            export BAT_THEME="Solarized (dark)"

            sed -i -e "s#(light)#(dark)#g" $git_config_path

            sed -i -e "s#background=light#background=dark#g" $vim_config_path

            broot_config_dark_path="$HOME/.config/broot/conf-dark.hjson"
            cp $broot_config_dark_path $broot_config_path

            zathura_config_dark_path="$HOME/.config/zathura/zathurarc-dark"
            cp $zathura_config_dark_path $zathura_config_path

            sed -i -e "s#^dark-mode = false#dark-mode = true#g" $termshark_config_path

            sed -i -e "s#solarized-light#solarized-dark#g" $wiki_script_path
            sed -i -e "s#favicon-light#favicon-dark#g" $wiki_script_path

            dircolors_dark_path="${ZSH_CUSTOM}/themes/dircolors-solarized/dircolors.ansi-dark"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                eval `gdircolors ${dircolors_dark_path}`
            else
                eval `dircolors ${dircolors_dark_path}`
            fi
            ;;
        dark)
            sed -i -e "s#solarized_dark#solarized_light#g" $config_path
            export BAT_THEME="Solarized (light)"

            sed -i -e "s#(dark)#(light)#g" $git_config_path

            sed -i -e "s#background=dark#background=light#g" $vim_config_path

            broot_config_light_path="$HOME/.config/broot/conf-light.hjson"
            cp $broot_config_light_path $broot_config_path

            zathura_config_light_path="$HOME/.config/zathura/zathurarc-light"
            cp $zathura_config_light_path $zathura_config_path

            sed -i -e "s#^dark-mode = true#dark-mode = false#g" $termshark_config_path

            sed -i -e "s#solarized-dark#solarized-light#g" $wiki_script_path
            sed -i -e "s#favicon-dark#favicon-light#g" $wiki_script_path

            dircolors_light_path="${ZSH_CUSTOM}/themes/dircolors-solarized/dircolors.ansi-light"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                eval `gdircolors ${dircolors_light_path}`
            else
                eval `dircolors ${dircolors_light_path}`
            fi
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

# Set BAT theme for FZF on linux (for Mac it is set below)
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if ! test -r ~/.config/alacritty/themes; then
        echo "Directory $HOME/.config/alacritty/themes doesn't exist"
    else
        config_path="$HOME/.config/alacritty/alacritty.toml"
        git_config_path="$HOME/.config/git/config"
        broot_config_path="$HOME/.config/broot/conf.hjson"
        vim_config_path="$HOME/.config/nvim/lua/user/colorscheme.lua"
        zathura_config_path="$HOME/.config/zathura/zathurarc"
        termshark_config_path="$HOME/.config/termshark/termshark.toml"
        wiki_script_path="$HOME/.local/bin/render-wiki.sh"

        mode=$(awk -F'/' '/solarized/ {gsub(/\[|"|\]|solarized_|.toml/,""); print $(NF)}' $config_path)
        if [[ "$mode" == "dark" ]]; then
            export BAT_THEME="Solarized (dark)"

            sed -i -e "s#(light)#(dark)#g" $git_config_path

            sed -i -e "s#background=light#background=dark#g" $vim_config_path

            broot_config_dark_path="$HOME/.config/broot/conf-dark.hjson"
            cp $broot_config_dark_path $broot_config_path

            zathura_config_dark_path="$HOME/.config/zathura/zathurarc-dark"
            cp $zathura_config_dark_path $zathura_config_path

            sed -i -e "s#^dark-mode = false#dark-mode = true#g" $termshark_config_path

            sed -i -e "s#solarized-light#solarized-dark#g" $wiki_script_path
            sed -i -e "s#favicon-light#favicon-dark#g" $wiki_script_path

            dircolors_dark_path="${ZSH_CUSTOM}/themes/dircolors-solarized/dircolors.ansi-dark"
            eval `dircolors ${dircolors_dark_path}`
        else
            export BAT_THEME="Solarized (light)"

            sed -i -e "s#(dark)#(light)#g" $git_config_path

            sed -i -e "s#background=dark#background=light#g" $vim_config_path

            broot_config_light_path="$HOME/.config/broot/conf-light.hjson"
            cp $broot_config_light_path $broot_config_path

            zathura_config_light_path="$HOME/.config/zathura/zathurarc-light"
            cp $zathura_config_light_path $zathura_config_path

            sed -i -e "s#^dark-mode = true#dark-mode = false#g" $termshark_config_path

            sed -i -e "s#solarized-dark#solarized-light#g" $wiki_script_path
            sed -i -e "s#favicon-dark#favicon-light#g" $wiki_script_path

            dircolors_light_path="${ZSH_CUSTOM}/themes/dircolors-solarized/dircolors.ansi-light"
            eval `dircolors ${dircolors_light_path}`
        fi
    fi
fi

# Set Alacritty theme (dark/light) on Mac
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! test -r ~/.config/alacritty/themes; then
        echo "Directory $HOME/.config/alacritty/themes doesn't exist"
    else
        config_path="$HOME/.config/alacritty/alacritty.toml"
        git_config_path="$HOME/.config/git/config"
        broot_config_path="$HOME/.config/broot/conf.hjson"
        vim_config_path="$HOME/.config/nvim/lua/user/colorscheme.lua"
        zathura_config_path="$HOME/.config/zathura/zathurarc"
        termshark_config_path="$HOME/.config/termshark/termshark.toml"
        wiki_script_path="$HOME/.local/bin/render-wiki.sh"

        # Get current mode
        mode=$(defaults read -g AppleInterfaceStyle 2>/dev/null)

        case $mode in
            Dark)
                sed -i -e "s#solarized_light#solarized_dark#g" $config_path
                export BAT_THEME="Solarized (dark)"

                sed -i -e "s#(light)#(dark)#g" $git_config_path

                sed -i -e "s#background=light#background=dark#g" $vim_config_path

                broot_config_dark_path="$HOME/.config/broot/conf-dark.hjson"
                cp $broot_config_dark_path $broot_config_path

                zathura_config_dark_path="$HOME/.config/zathura/zathurarc-dark"
                cp $zathura_config_dark_path $zathura_config_path

                sed -i -e "s#^dark-mode = false#dark-mode = true#g" $termshark_config_path

                sed -i -e "s#solarized-light#solarized-dark#g" $wiki_script_path
                sed -i -e "s#favicon-light#favicon-dark#g" $wiki_script_path

                dircolors_dark_path="${ZSH_CUSTOM}/themes/dircolors-solarized/dircolors.ansi-dark"
                eval `gdircolors ${dircolors_dark_path}`
                ;;
            *)
                sed -i -e "s#solarized_dark#solarized_light#g" $config_path
                export BAT_THEME="Solarized (light)"

                sed -i -e "s#(dark)#(light)#g" $git_config_path

                sed -i -e "s#background=dark#background=light#g" $vim_config_path

                broot_config_light_path="$HOME/.config/broot/conf-light.hjson"
                cp $broot_config_light_path $broot_config_path

                zathura_config_light_path="$HOME/.config/zathura/zathurarc-light"
                cp $zathura_config_light_path $zathura_config_path

                sed -i -e "s#^dark-mode = true#dark-mode = false#g" $termshark_config_path

                sed -i -e "s#solarized-dark#solarized-light#g" $wiki_script_path
                sed -i -e "s#favicon-dark#favicon-light#g" $wiki_script_path

                dircolors_light_path="${ZSH_CUSTOM}/themes/dircolors-solarized/dircolors.ansi-light"
                eval `gdircolors ${dircolors_light_path}`
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
    while true; do xdotool click 1; sleep 20; done
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
########################### ZSH History merge #################################
###############################################################################

function merge-curr-zsh-history () {
    eval "merge_zsh_histories.rb ${ZDOTDIR}/.zsh_history_*.bak \
          ${ZDOTDIR}/.zsh_history > ${HOME}/zsh_history_merged"
}

function merge-zsh-history () {
    eval "merge_zsh_histories.rb $@ \
          ${ZDOTDIR}/.zsh_history > ${HOME}/zsh_history_merged"
}


###############################################################################
################################  ytfzf #######################################
###############################################################################

function ytfzf() {
    eval "ytfzf $@"
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

    local pid=$( (date; ps -ef) |
        fzf -m --bind='ctrl-r:reload(date; ps -ef)' \
        --header=$'Press CTRL-R to reload\n\n' --header-lines=2 \
        --preview='echo {}' --preview-window=down,3,wrap \
        --layout=reverse --height=80% | awk '{print $2}' )

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
    eval "merge-images-diagonally.sh $@"
}

###############################################################################
############################## scale-gtk-app ##################################
###############################################################################

function scale-gtk-app() {
    eval "Exec=env GDK_SCALE=2 $@"
}

###############################################################################
############################## goimapnotify ###################################
###############################################################################

function watch-email() {
    # Kill old processes
    killall goimapnotify 2>/dev/null
    killall notify.sh 2>/dev/null

    # Start goimapnotify
    goimapnotify -conf ~/.config/imapnotify/imapnotify.conf > \
        ~/.cache/awesome/imapnotify.log 2>&1 &
    disown %goimapnotify

    # Start notify.sh
    eval "${HOME}/.config/imapnotify/notify.sh" > \
        ~/.cache/awesome/notify.log 2>&1 &
    disown %eval
}
