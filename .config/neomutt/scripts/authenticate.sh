#!/usr/bin/env bash

set -u

neomutt_dir="${XDG_CONFIG_HOME:-$HOME/.config}/neomutt"
failures=()

authenticate() {
    local label="$1" script="$2" token="$3" reply

    read -r -p "Authenticate ${label}? [Y/n] " reply
    case "$reply" in
        [Nn]|[Nn][Oo])
            printf 'Skipped %s.\n' "$label"
            return
            ;;
    esac

    if "$script" --verbose --authorize "$token"; then
        printf 'Authenticated %s.\n' "$label"
    else
        printf 'Authentication failed for %s; continuing.\n' "$label" >&2
        failures+=("$label")
    fi
}

authenticate \
    "Outlook mail" \
    "$neomutt_dir/accounts/work/oauth2.py" \
    "$neomutt_dir/credentials/token_outlook"
authenticate \
    "personal Gmail" \
    "$neomutt_dir/accounts/personal/oauth2.py" \
    "$neomutt_dir/credentials/token_gmail-personal"
authenticate \
    "Outlook calendar" \
    "$neomutt_dir/accounts/work/oauth2.py" \
    "$neomutt_dir/credentials/token_outlook_graph"

if (( ${#failures[@]} > 0 )); then
    printf 'Failed authentication flow(s): %s\n' "${failures[*]}" >&2
    exit 1
fi
