#!/usr/bin/env bash
###############################################################################
## Author       : Ragu Manjegowda
## Github       : @ragu-manjegowda
## Description  : Sync maildir flags to notmuch tags
###############################################################################

NOTMUCH_CONFIG="${1:-$HOME/.config/neomutt/.gitignored/maildir/outlook/.notmuch-config}"
MAILDIR="${2:-$HOME/.config/neomutt/.gitignored/maildir/outlook}"

export NOTMUCH_CONFIG

echo "Syncing maildir flags to notmuch tags..."
echo "Config: $NOTMUCH_CONFIG"
echo "Maildir: $MAILDIR"
echo ""

notmuch new 2>/dev/null

echo "Removing unread tag from messages with Seen flag..."
notmuch tag -unread -- 'tag:unread' 2>/dev/null

find "$MAILDIR" -type f -path "*/new/*" | while read -r file; do
    msgid=$(grep -m1 "^Message-ID:" "$file" 2>/dev/null | sed 's/Message-ID: *//' | tr -d '<>' | head -1)
    [[ -n "$msgid" ]] && notmuch tag +unread -- "id:$msgid" 2>/dev/null
done

find "$MAILDIR" -type f -name "*:2,*" ! -name "*S*" | while read -r file; do
    msgid=$(grep -m1 "^Message-ID:" "$file" 2>/dev/null | sed 's/Message-ID: *//' | tr -d '<>' | head -1)
    [[ -n "$msgid" ]] && notmuch tag +unread -- "id:$msgid" 2>/dev/null
done

echo "Syncing flagged tag from maildir F flag..."
find "$MAILDIR" -type f -name "*,*F*" | while read -r file; do
    msgid=$(grep -m1 "^Message-ID:" "$file" 2>/dev/null | sed 's/Message-ID: *//' | tr -d '<>' | head -1)
    [[ -n "$msgid" ]] && notmuch tag +flagged -- "id:$msgid" 2>/dev/null
done

echo ""
echo "Done. Summary:"
echo "  Unread: $(notmuch count 'tag:unread' 2>/dev/null)"
echo "  Flagged: $(notmuch count 'tag:flagged' 2>/dev/null)"
