#!/usr/bin/env bash
set -euo pipefail

xset s off
xset +dpms
xset dpms 0 0 0

exec xidlehook \
    --not-when-audio \
    --timer 120 \
        'awesome-client "awesome.emit_signal(\"module::lockscreen_show\")"' \
        '' \
    --timer 480 \
        'xset dpms force off' \
        'xset dpms force on'
