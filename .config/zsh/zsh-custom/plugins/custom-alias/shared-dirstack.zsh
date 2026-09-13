# Keep recent directories synchronized across concurrent shells.
autoload -Uz add-zsh-hook

DIRSTACKSIZE="10"
DIRSTACKFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/dirs"
DIRSTACKLOCK="${DIRSTACKFILE}.lock"

mkdir -p "${DIRSTACKFILE:h}"
[[ -f $DIRSTACKFILE ]] || touch "$DIRSTACKFILE"
[[ -f $DIRSTACKLOCK ]] || touch "$DIRSTACKLOCK"
zmodload zsh/system

chpwd_dirpersist() {
  if (( $DIRSTACKSIZE <= 0 )) || [[ -z $DIRSTACKFILE ]]; then return; fi
  local lock_fd temp_file dir
  local -a shared_stack merged_stack

  zsystem flock -t 1 -f lock_fd "$DIRSTACKLOCK" || return
  {
    while IFS= read -r dir; do
      [[ -d $dir ]] && shared_stack+=("$dir")
    done < "$DIRSTACKFILE"

    # Preserve global recency, then supplement it with this shell's stack.
    for dir in "$PWD" "${shared_stack[@]}" "${dirstack[@]}"; do
      [[ -d $dir ]] && merged_stack+=("$dir")
    done
    merged_stack=("${(@u)merged_stack}")

    temp_file="${DIRSTACKFILE}.tmp.${$}.${RANDOM}"
    builtin print -l -- "${merged_stack[@]:0:$DIRSTACKSIZE}" >! "$temp_file"
    command mv -f -- "$temp_file" "$DIRSTACKFILE"
    temp_file=""
  } always {
    [[ -n $temp_file ]] && command rm -f -- "$temp_file"
    zsystem flock -u "$lock_fd"
  }
}

load_dirstack() {
  if [[ -f "$DIRSTACKFILE" ]]; then
    local stack=()
    local dir
    while IFS= read -r dir; do
      [[ -d "$dir" ]] && stack+=("$dir")
    done < "$DIRSTACKFILE"

    if (( ${#stack[@]} > 0 )); then
      builtin cd -q -- "$stack[1]"
      dirstack=("${stack[@]:1}")
    fi
  fi
}

refresh_dirstack() {
  local dir
  local -a shared_stack

  while IFS= read -r dir; do
    [[ -d $dir && $dir != $PWD ]] && shared_stack+=("$dir")
  done < "$DIRSTACKFILE"
  dirstack=("${shared_stack[@]}")
}

# Refresh OMZ's shell-local directory list from the shared stack on demand.
function d() {
  refresh_dirstack
  if [[ -n $1 ]]; then
    dirs "$@"
  else
    dirs -v | head -n "$DIRSTACKSIZE"
  fi
}
compdef _dirs d

load_dirstack
add-zsh-hook chpwd chpwd_dirpersist
# Preserve the shell's cwd before foreground applications or nested shells run.
add-zsh-hook preexec chpwd_dirpersist
