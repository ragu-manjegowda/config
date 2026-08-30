#!/usr/bin/env bash
set -euo pipefail

xset s off
xset +dpms
xset dpms 0 0 0

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/${UID}}"
socket="$runtime_dir/xidlehook.sock"
rm -f "$socket"

exec xidlehook \
    --socket "$socket" \
    --timer 120 \
        "${HOME}/.config/scripts/xidlehook-lock-action.sh ${socket}" \
        '' \
    --timer 60 \
        "${HOME}/.config/scripts/xidlehook-display-action.sh off" \
        "${HOME}/.config/scripts/xidlehook-display-action.sh on"
