
function _git_info() {
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    echo " %{$fg[magenta]%}♮$(git_current_branch)%{$fg[cyan]%}"
  fi
}

PROMPT='%(?:%{$fg_bold[green]%}%n %{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )'
PROMPT+='%{$fg[cyan]%}%1c$(_git_info) ♔%{$reset_color%} '
