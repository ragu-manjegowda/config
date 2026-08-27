#!/usr/bin/env bash
set -euo pipefail

xset s off
xset +dpms
xset dpms 0 0 0

exec xidlehook \
    --not-when-fullscreen \
    --timer 120 \
        'awesome-client "awesome.emit_signal(\"module::lockscreen_show\")"' \
        '' \
    --timer 480 \
        'xset dpms force off' \
        "$HOME/.config/awesome/utilities/reset-primary-display --force"
