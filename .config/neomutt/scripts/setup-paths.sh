#!/usr/bin/env bash

set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

NEOMUTT_DIR="$CONFIG_HOME/neomutt"
MAILDIR_BASE="$NEOMUTT_DIR/.gitignored/maildir"
CACHE_DIR="$NEOMUTT_DIR/.gitignored/cache"
DATA_DIR="$NEOMUTT_DIR/.gitignored/data"

STATE_NEOMUTT="$STATE_HOME/neomutt"

mkdir -p "$MAILDIR_BASE/outlook" "$MAILDIR_BASE/gmail-personal"
mkdir -p "$CACHE_DIR" "$DATA_DIR" "$STATE_NEOMUTT"

touch "$DATA_DIR/aliases" "$DATA_DIR/history"

echo "Neomutt directories initialized:"
echo "  Maildir: $MAILDIR_BASE/{outlook,gmail-personal}"
echo "  Cache:   $CACHE_DIR"
echo "  Data:    $DATA_DIR"
echo "  Logs:    $STATE_NEOMUTT"
