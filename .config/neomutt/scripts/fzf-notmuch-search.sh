#!/usr/bin/env bash
###############################################################################
## Author       : Ragu Manjegowda
## Github       : @ragu-manjegowda
## Description  : Fuzzy notmuch search with filters
##                Format 1: release planning       (all words = fuzzy query)
##                Format 2: "release planning" folder:project date:1week..
##                          ^^^^^^^^^^^^^^^ fuzzy   ^^^^^^^^^^^^^^^^^^^^ filters
###############################################################################


# Fallback to default notmuch config, actual config passed as first argument
NOTMUCH_CONFIG="${1:-$HOME/.config/neomutt/.gitignored/maildir/outlook/.notmuch-config}"
MUTTRC_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/neomutt/.gitignored/cache/fzf-cmd.muttrc"

export NOTMUCH_CONFIG

mkdir -p "${MUTTRC_FILE%/*}"
printf '%s\n' '# No search command generated.' > "$MUTTRC_FILE"

clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Fuzzy Notmuch Search"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Format 1: release important              (fuzzy search only)"
echo "Format 2: \"release important\" folder:project  (fuzzy + filters)"
echo "Format 3: folder:project                 (fuzzy folder only)"
echo ""
echo "Filters: from: to: folder: date: tag: is: subject:"
echo "Folder values are fuzzy-matched against full indexed paths."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -r -p "Search: " user_input

[[ -z "$user_input" ]] && clear && exit 0

fzf_query=""
notmuch_filters=""
filter_prefix='^(from:|to:|subject:|date:|tag:|folder:|is:|id:|thread:|path:|mimetype:|attachment:|body:)'

list_mail_folders() {
    local database_path directory folder
    database_path="$(notmuch config get database.path 2>/dev/null)" || return 1
    [[ -d "$database_path" ]] || return 1

    while IFS= read -r directory; do
        folder="${directory%/cur}"
        folder="${folder#"$database_path"/}"
        [[ -n "$folder" && "$folder" != "$directory" ]] && printf '%s\n' "$folder"
    done < <(find "$database_path" -type d -name cur -print 2>/dev/null)
}

resolve_folder_filter() {
    local fragment="$1" matches folder escaped expression=""
    fragment="${fragment#folder:}"
    fragment="${fragment#\"}"
    fragment="${fragment%\"}"
    [[ -n "$fragment" ]] || return 1

    matches="$(list_mail_folders | sort -u | fzf --filter="$fragment")"
    if [[ -z "$matches" ]]; then
        printf 'No fuzzy folder matches for: %s\n' "$fragment" >&2
        return 1
    fi

    while IFS= read -r folder; do
        [[ -n "$folder" ]] || continue
        escaped="${folder//\\/\\\\}"
        escaped="${escaped//\"/\\\"}"
        if [[ -n "$expression" ]]; then
            expression+=" OR "
        fi
        expression+="folder:\"$escaped\""
    done <<< "$matches"
    printf '(%s)' "$expression"
}

append_filters() {
    local input="$1" word filter
    for word in $input; do
        [[ "$word" =~ $filter_prefix ]] || continue
        if [[ "$word" == folder:* ]]; then
            filter="$(resolve_folder_filter "$word")" || return 1
        else
            filter="$word"
        fi
        notmuch_filters+="${notmuch_filters:+ AND }$filter"
    done
}

if [[ "$user_input" =~ ^\"([^\"]+)\"(.*)$ ]]; then
    fzf_query="${BASH_REMATCH[1]}"
    remaining="${BASH_REMATCH[2]}"
    append_filters "$remaining" || exit 0
elif [[ "$user_input" =~ $filter_prefix ]]; then
    append_filters "$user_input" || exit 0
else
    fzf_query="$user_input"
fi

fzf_query=$(echo "$fzf_query" | xargs)

if [[ -z "$fzf_query" ]]; then
    final_query="${notmuch_filters:-*}"
else
    echo ""
    echo "Fetching emails${notmuch_filters:+ with filters: $notmuch_filters}..."

    emails=$(notmuch search --format=text --limit=1000 "${notmuch_filters:-*}" 2>/dev/null)

    if [[ -z "$emails" ]]; then
        echo "No emails found${notmuch_filters:+ with filters: $notmuch_filters}"
        sleep 2
        clear
        exit 0
    fi

    echo "Fuzzy matching '$fzf_query'..."

    matched=$(echo "$emails" | fzf --filter="$fzf_query" | head -50)

    if [[ -z "$matched" ]]; then
        echo "No fuzzy matches for: $fzf_query"
        sleep 2
        clear
        exit 0
    fi

    thread_ids=$(echo "$matched" | awk '{print $1}' | sort -u)

    thread_query=""
    while IFS= read -r tid; do
        [[ -z "$tid" ]] && continue
        if [[ -z "$thread_query" ]]; then
            thread_query="$tid"
        else
            thread_query="$thread_query OR $tid"
        fi
    done <<< "$thread_ids"

    if [[ -n "$notmuch_filters" ]]; then
        final_query="($thread_query) AND $notmuch_filters"
    else
        final_query="$thread_query"
    fi
fi

clear

escaped_query=$(echo "$final_query" | sed "s/'/\\\\'/g")
printf "push '<vfolder-from-query>%s<enter>'\n" "$escaped_query" > "$MUTTRC_FILE"
