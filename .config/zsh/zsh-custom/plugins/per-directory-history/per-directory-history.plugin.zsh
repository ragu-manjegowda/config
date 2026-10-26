# Keep OMZ's navigation/toggle behavior, but consult the global history filter
# before recording an entry in either history.
source "$ZSH/plugins/per-directory-history/per-directory-history.plugin.zsh"

function _history_tools_append_entry() {
    local destination="$1" entry="$2"
    # An empty, scoped native history preserves Zsh's serialization/locking
    # without rereading a potentially large history or sharing write cursors.
    builtin fc -p -a '' "$HISTSIZE" "$SAVEHIST" || return $?
    builtin print -Sr -- "$entry"
    builtin fc -AI "$destination"
}

function _per-directory-history-addhistory() {
    if [[ ${_history_tools_decision_entry+x} == x && $_history_tools_decision_entry == "$1" ]]; then
        (( _history_tools_decision_status == 0 )) || return "$_history_tools_decision_status"
    elif (( $+functions[zshaddhistory] )); then
        zshaddhistory "$@" || return $?
    fi
    local destination="$_per_directory_history_directory"
    [[ "$HISTFILE" == "$destination" ]] && destination="$_per_directory_history_global"
    typeset -g _history_tools_pending_target="$destination"
    typeset -g _history_tools_pending_entry="${1%$'\n'}"
}

function _history_tools_flush_entry() {
    unset _history_tools_decision_entry _history_tools_decision_status
    [[ -n ${_history_tools_pending_target:-} ]] || return 0
    local destination="$_history_tools_pending_target" entry="$_history_tools_pending_entry"
    unset _history_tools_pending_target _history_tools_pending_entry
    # Zsh saves the active history normally. Append to the other target only
    # after zshaddhistory returns, outside its special history-context handling.
    _history_tools_append_entry "$destination" "$entry"
    return 0
}
add-zsh-hook preexec _history_tools_flush_entry
add-zsh-hook precmd _history_tools_flush_entry
