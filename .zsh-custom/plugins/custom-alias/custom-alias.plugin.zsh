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

# Unset auto cd as the auto suggestion theme makes it annoying
unsetopt AUTO_CD

# Unset alias l
unalias \l

# Define custom aliases
alias l='ls'
alias ldot='ls -d .*'
alias vim="nvim"
## Config alias
alias config='git --git-dir=$HOME/.config.git/ --work-tree=$HOME'

# Zsh-hist
unsetopt HIST_REDUCE_BLANKS

# Save command to history on if it is successful
zshaddhistory() { whence ${${(z)1}[1]} >| /dev/null || return 1 }
