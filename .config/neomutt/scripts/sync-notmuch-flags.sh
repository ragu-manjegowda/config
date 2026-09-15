#!/usr/bin/env bash
###############################################################################
## Author       : Ragu Manjegowda
## Github       : @ragu-manjegowda
## Description  : Sync maildir flags to notmuch tags
###############################################################################

NOTMUCH_CONFIG="${1:-$HOME/.config/neomutt/.gitignored/maildir/outlook/.notmuch-config}"

export NOTMUCH_CONFIG

echo "Synchronizing Maildir flags through notmuch new..."
echo "Config: $NOTMUCH_CONFIG"
echo ""

notmuch new 2>/dev/null

echo ""
echo "Done. Summary:"
echo "  Unread: $(notmuch count 'tag:unread' 2>/dev/null)"
echo "  Flagged: $(notmuch count 'tag:flagged' 2>/dev/null)"
