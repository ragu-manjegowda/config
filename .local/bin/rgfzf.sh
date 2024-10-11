#!/usr/bin/env bash

# Switch between Ripgrep launcher mode (CTRL-G) and fzf filtering mode (CTRL-F)
RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "

INITIAL_QUERY="${*:-}"

LAST="${*: -1}"
if [[ -d $LAST ]]; then
  INITIAL_QUERY="${*:1:$#-1}";
  DIR=$LAST
  echo "$INITIAL_QUERY"
fi

IFS=: read -ra selected < <(
  FZF_DEFAULT_COMMAND="$RG_PREFIX $(printf %q "$INITIAL_QUERY") $DIR" \
  fzf --ansi \
      --color "hl:-1:underline,hl+:-1:underline:reverse" \
      --disabled --query "$INITIAL_QUERY" \
      --bind "change:reload:sleep 0.1; $RG_PREFIX {q} $DIR || true" \
      --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(2. fzf> )+enable-search+clear-query+rebind(ctrl-g)" \
      --bind "ctrl-g:unbind(ctrl-g)+change-prompt(1. ripgrep> )+disable-search+reload($RG_PREFIX {q} $DIR || true)+rebind(change,ctrl-f)" \
      --prompt '1. Ripgrep> ' \
      --delimiter : \
      --header '╱ CTRL-G (Ripgrep mode) ╱ CTRL-F (fzf mode) ╱' \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
)
[ -n "${selected[0]}" ] && nvim "${selected[0]}" "+${selected[1]}"
