#!/usr/bin/env bash

set -euo pipefail

socket="$1"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/${UID}}"
lock_state="$runtime_dir/awesome-lockscreen.locked"
pactl_bin="${XIDLEHOOK_PACTL_BIN:-pactl}"
client_bin="${XIDLEHOOK_CLIENT_BIN:-xidlehook-client}"
awesome_client_bin="${XIDLEHOOK_AWESOME_CLIENT_BIN:-awesome-client}"

has_active_audio() {
    local stream_type streams

    for stream_type in sink-inputs source-outputs; do
        if streams="$(LC_ALL=C "$pactl_bin" list "$stream_type" 2>/dev/null)" &&
            [[ "$streams" == *'State: RUNNING'* || "$streams" == *'Corked: no'* ]]; then
            return 0
        fi
    done

    return 1
}

if [[ ! -e "$lock_state" ]] && has_active_audio; then
    "$client_bin" --socket "$socket" reset-idle
    exit 0
fi

"$awesome_client_bin" 'awesome.emit_signal("module::lockscreen_show")' >/dev/null
