#!/usr/bin/env bash

set -euo pipefail

socket="$1"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/${UID}}"
lock_state="$runtime_dir/awesome-lockscreen.locked"
pactl_bin="${XIDLEHOOK_PACTL_BIN:-pactl}"
client_bin="${XIDLEHOOK_CLIENT_BIN:-xidlehook-client}"
awesome_client_bin="${XIDLEHOOK_AWESOME_CLIENT_BIN:-awesome-client}"

has_active_audio() {
    local source_output source_outputs sink_inputs

    if sink_inputs="$(LC_ALL=C "$pactl_bin" list sink-inputs 2>/dev/null)" &&
        [[ "$sink_inputs" == *'State: RUNNING'* || "$sink_inputs" == *'Corked: no'* ]]; then
        return 0
    fi

    source_outputs="$(LC_ALL=C "$pactl_bin" list source-outputs 2>/dev/null)" || return 1
    source_outputs=$'\n'"$source_outputs"
    while [[ "$source_outputs" == *$'\nSource Output #'* ]]; do
        source_outputs="${source_outputs#*$'\nSource Output #'}"
        source_output="${source_outputs%%$'\nSource Output #'*}"

        # Pavucontrol creates uncorked source meters for every input device.
        # Those monitor streams are not microphone capture and must not keep
        # an unattended session unlocked indefinitely.
        if [[ "$source_output" != *'application.process.binary = "pavucontrol"'* &&
            "$source_output" != *'application.name = "PulseAudio Volume Control"'* &&
            ( "$source_output" == *'State: RUNNING'* || "$source_output" == *'Corked: no'* ) ]]; then
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
