#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWESOME_DIR="$(dirname "$SCRIPT_DIR")"

CONTROL_CENTER="$AWESOME_DIR/layout/control-center/init.lua"
PRESENTATION_WIDGET="$AWESOME_DIR/widget/presentation-mode/init.lua"
DND_WIDGET="$AWESOME_DIR/widget/dont-disturb/init.lua"
BLUR_WIDGET="$AWESOME_DIR/widget/blur-toggle/init.lua"
PICOM_CONF="$AWESOME_DIR/configuration/picom.conf"

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

grep -Fq "require('widget.presentation-mode')" "$CONTROL_CENTER" || \
    fail 'control center must include the presentation-mode widget'

grep -Fq "awesome.emit_signal('widget::dont_disturb:set', true)" "$PRESENTATION_WIDGET" || \
    fail 'presentation mode must enable do-not-disturb'

grep -Fq "awesome.emit_signal('widget::blur:set', false)" "$PRESENTATION_WIDGET" || \
    fail 'presentation mode must disable blur'

grep -Fq "'widget::dont_disturb:set'" "$DND_WIDGET" || \
    fail 'do-not-disturb widget must support explicit set signal'

grep -Fq "'widget::blur:set'" "$BLUR_WIDGET" || \
    fail 'blur widget must support explicit set signal'

grep -Eq '^[[:space:]]*blur-background[[:space:]]*=[[:space:]]*true;' "$PICOM_CONF" || \
    fail 'picom global blur-background must stay enabled for normal use'

grep -Eq "window_type[[:space:]]*=[[:space:]]*'desktop'.*blur-background[[:space:]]*=[[:space:]]*false" "$PICOM_CONF" || \
    fail 'top panel desktop windows must stay excluded from blur'

if grep -Eq "window_type[[:space:]]*=[[:space:]]*'notification'.*blur-background[[:space:]]*=[[:space:]]*false" "$PICOM_CONF"; then
    fail 'notification windows must not be excluded from blur; OSD popups use notification type'
fi

printf 'OK: presentation mode, OSD blur, and top-panel blur rules are covered\n'
