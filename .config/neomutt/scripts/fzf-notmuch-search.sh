#!/usr/bin/env bash
###############################################################################
## Author       : Ragu Manjegowda
## Github       : @ragu-manjegowda
## Description  : Fuzzy notmuch search with filters
##                Format 1: mtl lidarfree          (all words = fuzzy query)
##                Format 2: "mtl lidarfree" folder:Inbox date:1week..
##                          ^^^^^^^^^^^^^^^ fuzzy   ^^^^^^^^^^^^^^^^^^^^ filters
###############################################################################


# Fallback to default notmuch config, actual config passed as first argument
NOTMUCH_CONFIG="${1:-$HOME/.config/neomutt/.gitignored/maildir/outlook/.notmuch-config}"
MUTTRC_FILE="/tmp/neomutt-fzf-cmd.muttrc"

export NOTMUCH_CONFIG

echo "noop" > "$MUTTRC_FILE"

clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Fuzzy Notmuch Search"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Format 1: release important              (fuzzy search only)"
echo "Format 2: \"release important\" folder:Inbox  (fuzzy + filters)"
echo ""
echo "Filters: from: to: folder: date: tag: is: subject:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -r -p "Search: " user_input

[[ -z "$user_input" ]] && clear && exit 0

fzf_query=""
notmuch_filters=""

if [[ "$user_input" =~ ^\"([^\"]+)\"(.*)$ ]]; then
    fzf_query="${BASH_REMATCH[1]}"
    remaining="${BASH_REMATCH[2]}"

    for word in $remaining; do
        if [[ "$word" =~ ^(from:|to:|subject:|date:|tag:|folder:|is:|id:|thread:|path:|mimetype:|attachment:|body:) ]]; then
            notmuch_filters="$notmuch_filters $word"
        fi
    done
else
    fzf_query="$user_input"
fi

fzf_query=$(echo "$fzf_query" | xargs)
notmuch_filters=$(echo "$notmuch_filters" | xargs)

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
echo "push '<vfolder-from-query>${escaped_query}<enter>'" > "$MUTTRC_FILE"
