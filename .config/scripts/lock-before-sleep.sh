#!/usr/bin/env bash

set -euo pipefail

if ! pgrep -x -u "$UID" awesome >/dev/null; then
    exit 0
fi

awesome-client 'awesome.emit_signal("module::lockscreen_show")' >/dev/null

for _ in {1..40}; do
    state="$(awesome-client '
        local awful = require("awful")
        local s = screen.primary
        local lockscreen = s and (s.lockscreen or s.lockscreen_extended)
        return lockscreen and lockscreen.visible and
            awful.keygrabber.current_instance ~= nil and "ready" or "waiting"
    ')"
    if [[ "$state" == *'"ready"'* ]]; then
        awesome-client 'awesome.emit_signal("module::fingerprint_stop")' >/dev/null
        exit 0
    fi
    sleep 0.05
done

printf 'Lockscreen did not become ready before sleep\n' >&2
exit 1
