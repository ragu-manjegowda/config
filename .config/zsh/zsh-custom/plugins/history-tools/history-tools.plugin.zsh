# Shared history commands. This plugin does not read history until invoked.
typeset -g _HISTORY_TOOLS_SCRIPT="${0:A:h}/history-tool.py"

function history-tools() {
    command python3 "$_HISTORY_TOOLS_SCRIPT" "$@"
}

function _history_merge_help() {
    local name="$1"
    builtin print -r -- "Usage: $name [OPTIONS] [HISTORY...]"
    builtin print -r -- '
Merge the supplied Bash/Zsh histories with your current Zsh history.

Current history:
  $ZDOTDIR/.zsh_history, or ~/.zsh_history when ZDOTDIR is unset

Default output:
  ~/zsh_history_merged

Trailing command whitespace is trimmed; duplicates retain their newest timestamp.
Routine commands are filtered using ignored-commands.txt beside the helper.
The active history file is not replaced by default.'
    if [[ "$name" == merge-curr-zsh-history ]]; then
        builtin print -r -- '
Also includes .zsh_history_*.bak files beside the current history.
It works when there are no matching backup files.'
    fi
    builtin print -r -- '
Options:
  -h, --help          Show this help without reading or writing history
  -o, --output PATH   Write the merged result to PATH instead
  --timestamp EPOCH   Timestamp to use for untimestamped Bash entries
  --exclude-file PATH Read excluded command phrases from PATH
  --no-excludes       Keep routine commands for this invocation

Examples:'
    builtin print -r -- "  $name ~/bash_history"
    builtin print -r -- "  $name -o ~/merged_history ~/bash_history"
    builtin print -r -- '
For standalone format conversion and advanced merge options, use history-tools.
Refer to its help:
  history-tools --help
  history-tools convert --help
  history-tools merge --help'
}

function _history_merge_wants_help() {
    local argument
    for argument in "$@"; do
        case "$argument" in
            --) return 1 ;;
            -h|--help) return 0 ;;
        esac
    done
    return 1
}

function merge-zsh-history() {
    if _history_merge_wants_help "$@"; then
        _history_merge_help merge-zsh-history
        return 0
    fi
    local history_dir="${ZDOTDIR:-$HOME}"
    history-tools merge --output "$HOME/zsh_history_merged" "$@" "$history_dir/.zsh_history"
}

function merge-curr-zsh-history() {
    if _history_merge_wants_help "$@"; then
        _history_merge_help merge-curr-zsh-history
        return 0
    fi
    local history_dir="${ZDOTDIR:-$HOME}"
    merge-zsh-history "$@" "$history_dir"/.zsh_history_*.bak(N)
}

function bash-to-zsh-history() {
    history-tools convert --from bash --to zsh "$@"
}

function zsh-to-bash-history() {
    history-tools convert --from zsh --to bash "$@"
}
