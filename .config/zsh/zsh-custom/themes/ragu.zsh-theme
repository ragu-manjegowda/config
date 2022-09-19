# Color shortcuts
BLACK=$fg[black]
BLUE=$fg[blue]
CYAN=$fg[cyan]
GREEN=$fg[green]
RED=$fg[red]
WHITE=$fg[white]
YELLOW=$fg[yellow]

BLACK_BOLD=$fg_bold[black]
BLUE_BOLD=$fg_bold[blue]
GREEN_BOLD=$fg_bold[green]
RED_BOLD=$fg_bold[red]
RESET_COLOR=$reset_color
WHITE_BOLD=$fg_bold[white]
YELLOW_BOLD=$fg_bold[yellow]

# Format for git_prompt_status()
ZSH_THEME_GIT_PROMPT_AHEAD="%{$BLUE%}⇡"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$CYAN%}⇣"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$GREEN%}✔"
ZSH_THEME_GIT_PROMPT_DIVERGED="%{$RED%}⇕"
ZSH_THEME_GIT_PROMPT_STAGED="%{$YELLOW%}+"
ZSH_THEME_GIT_PROMPT_STASHED="%{$WHITE%}ª"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$RED%}✘"
ZSH_THEME_GIT_PROMPT_UNSTAGED="%{$BLACK%}!"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$WHITE%}?"

ragu_git_branch () {
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  echo "${ref#refs/heads/}"
}

ragu_git_status() {
  _STATUS=""

  # check status of files
  _INDEX=$(command git status --porcelain 2> /dev/null)
  if [[ -n "$_INDEX" ]]; then
    if $(echo "$_INDEX" | command grep -q '^[AMRD]. '); then
      _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_STAGED"
    fi
    if $(echo "$_INDEX" | command grep -q '^.[MTD] '); then
      _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_UNSTAGED"
    fi
    if $(echo "$_INDEX" | command grep -q -E '^\?\? '); then
      _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_UNTRACKED"
    fi
    if $(echo "$_INDEX" | command grep -q '^UU '); then
      _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_UNMERGED"
    fi
  else
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_CLEAN"
  fi

  # check status of local repository
  _INDEX=$(command git status --porcelain -b 2> /dev/null)
  if $(echo "$_INDEX" | command grep -q '^## .*ahead'); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_AHEAD"
  fi
  if $(echo "$_INDEX" | command grep -q '^## .*behind'); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_BEHIND"
  fi
  if $(echo "$_INDEX" | command grep -q '^## .*diverged'); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_DIVERGED"
  fi

  if $(command git rev-parse --verify refs/stash &> /dev/null); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_STASHED"
  fi

  echo $_STATUS
}

ragu_git_prompt () {
  GIT_DISCOVER_ACROSS_FILESYSTEM=true \
  git check-ignore -q 2>/dev/null; if [ "$?" -ne "1" ]; then
  #if [[ $(git rev-parse --is-inside-work-tree) == "true" ]]; then
    local _branch=$(ragu_git_branch)
    local _status=$(ragu_git_status)
    local _result=""
    if [[ "${_branch}x" != "x" ]]; then
      _result="$ZSH_THEME_GIT_PROMPT_PREFIX$_branch"
      if [[ "${_status}x" != "x" ]]; then
        _result="$_result $_status"
      fi
      _result="$_result%{$BLUE%}$ZSH_THEME_GIT_PROMPT_SUFFIX"
    fi
    echo $_result
  fi
}

PROMPT='%(?:%{$GREEN_BOLD%}%n %{$GREEN_BOLD%}➜ :%{$RED_BOLD%}➜ )'
PROMPT+='%{$CYAN%}%1c ♔%{$RESET_COLOR%} '
#PROMPT+='%{$CYAN%}%1c ♕%{$RESET_COLOR%} '
RPROMPT+='%{$BLUE%}$(ragu_git_prompt)%{$RESET_COLOR%}'

