#!/usr/bin/env bash
set -euo pipefail

REPO_HOME="${REPO_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
FETCH_SCRIPT="$REPO_HOME/.config/imapnotify/fetch-emails.py"
NOTIFY_SCRIPT="$REPO_HOME/.config/imapnotify/notify.sh"

grep -Fq 'IMAP4_SSL(endpoint, timeout=' "$FETCH_SCRIPT"
grep -Fq 'BODY.PEEK[HEADER.FIELDS (FROM SUBJECT DATE)]' "$FETCH_SCRIPT"
if grep -Fq 'BODY.PEEK[]' "$FETCH_SCRIPT"; then
    printf '%s\n' 'fetch-emails must not download complete unread messages' >&2
    exit 1
fi
grep -Fq 'IMAP_FETCH_TIMEOUT_SECONDS' "$NOTIFY_SCRIPT"
grep -Fq 'timeout --kill-after=5' "$NOTIFY_SCRIPT"

printf '%s\n' 'goimapnotify timeout tests passed'
