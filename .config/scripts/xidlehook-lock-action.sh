#!/usr/bin/env bash

set -euo pipefail

socket="$1"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/${UID}}"
lock_state="$runtime_dir/awesome-lockscreen.locked"
pactl_bin="${XIDLEHOOK_PACTL_BIN:-pactl}"
client_bin="${XIDLEHOOK_CLIENT_BIN:-xidlehook-client}"
awesome_client_bin="${XIDLEHOOK_AWESOME_CLIENT_BIN:-awesome-client}"

has_active_audio() {
    local source_output source_outputs sink_input sink_inputs

    if sink_inputs="$(LC_ALL=C "$pactl_bin" list sink-inputs 2>/dev/null)"; then
        sink_inputs=$'\n'"$sink_inputs"
        while [[ "$sink_inputs" == *$'\nSink Input #'* ]]; do
            sink_inputs="${sink_inputs#*$'\nSink Input #'}"
            sink_input="${sink_inputs%%$'\nSink Input #'*}"

            # Notification/system event sounds must never inhibit idle, even
            # if their player hangs with an uncorked stream after resume.
            if [[ "$sink_input" != *'media.role = "event"'* &&
                "$sink_input" != *'application.process.binary = "canberra-gtk-play"'* &&
                "$sink_input" != *'application.name = "PipeWire ALSA [canberra-gtk-play]"'* &&
                "$sink_input" != *'application.name = "Awesome notification sound"'* &&
                ( "$sink_input" == *'State: RUNNING'* || "$sink_input" == *'Corked: no'* ) ]]; then
                return 0
            fi
        done
    fi

    source_outputs="$(LC_ALL=C "$pactl_bin" list source-outputs 2>/dev/null)" || return 1
    source_outputs=$'\n'"$source_outputs"
    while [[ "$source_outputs" == *$'\nSource Output #'* ]]; do
        source_outputs="${source_outputs#*$'\nSource Output #'}"
        source_output="${source_outputs%%$'\nSource Output #'*}"

        # Pavucontrol-compatible peak meters create uncorked source outputs
        # for every input device. Those monitor streams are not microphone
        # capture and must not keep an unattended session unlocked.
        if [[ "$source_output" != *'application.process.binary = "pavucontrol"'* &&
            "$source_output" != *'application.name = "PulseAudio Volume Control"'* &&
            "$source_output" != *'application.id = "org.PulseAudio.pavucontrol"'* &&
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
