#!/usr/bin/env bash

set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

NEOMUTT_DIR="$CONFIG_HOME/neomutt"
MAILDIR_BASE="$NEOMUTT_DIR/.gitignored/maildir"
CACHE_DIR="$NEOMUTT_DIR/.gitignored/cache"
DATA_DIR="$NEOMUTT_DIR/.gitignored/data"
NOTMUCH_IDENTITIES="$NEOMUTT_DIR/accounts/notmuch-identities"

STATE_NEOMUTT="$STATE_HOME/neomutt"

mkdir -p "$MAILDIR_BASE/outlook" "$MAILDIR_BASE/gmail-personal"
mkdir -p "$CACHE_DIR" "$DATA_DIR" "$STATE_NEOMUTT"

touch "$NEOMUTT_DIR/accounts/aliases" "$DATA_DIR/history"
chmod 600 "$NEOMUTT_DIR/accounts/aliases"

setup_notmuch() {
    local account="$1" email="$2"
    local maildir="$MAILDIR_BASE/$account"
    local config="$maildir/.notmuch-config"

    if [[ ! -f "$config" ]]; then
        cat > "$config" <<EOF
[database]
path=$maildir

[user]
name=Ragu Manjegowda
primary_email=$email

[new]
tags=unread;inbox
ignore=.mbsyncstate;.uidvalidity

[search]
exclude_tags=deleted;spam

[maildir]
synchronize_flags=true
EOF
    fi

    if command -v notmuch >/dev/null; then
        NOTMUCH_CONFIG="$config" notmuch new
    fi
}

if [[ ! -r "$NOTMUCH_IDENTITIES" ]]; then
    printf 'Notmuch identity map not found: %s\n' "$NOTMUCH_IDENTITIES" >&2
    exit 1
fi
if head -c9 "$NOTMUCH_IDENTITIES" 2>/dev/null |
        LC_ALL=C tr -d '\0' | grep -q GITCRYPT; then
    printf 'Notmuch identity map is locked; unlock git-crypt first.\n' >&2
    exit 1
fi

while IFS='|' read -r account email; do
    [[ -n "$account" && -n "$email" ]] || continue
    setup_notmuch "$account" "$email"
done < "$NOTMUCH_IDENTITIES"

echo "Neomutt directories initialized:"
echo "  Maildir: $MAILDIR_BASE/{outlook,gmail-personal}"
echo "  Cache:   $CACHE_DIR"
echo "  Data:    $DATA_DIR"
echo "  Logs:    $STATE_NEOMUTT"
