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
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$YELLOW%}●"
ZSH_THEME_GIT_PROMPT_DELETED="%{$YELLOW%}●"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$RED%}●"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$RED%}●"
ZSH_THEME_GIT_PROMPT_ADDED="%{$GREEN%}●"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$WHITE%}●"

function _git_info() {
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    echo "♮$(git_current_branch)"
  fi
}

PROMPT='%(?:%{$GREEN_BOLD%}%n %{$GREEN_BOLD%}➜ :%{$RED_BOLD%}➜ )'
PROMPT+='%{$CYAN%}%1c ♔%{$RESET_COLOR%} '
RPROMPT='%{$BLUE%}$(_git_info)'
RPROMPT+='$(git_prompt_status)%{$RESET_COLOR%}'

