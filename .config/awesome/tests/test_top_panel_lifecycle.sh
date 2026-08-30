#!/usr/bin/env bash

set -euo pipefail

top_panel="${HOME}/.config/awesome/layout/top-panel.lua"

grep -Fq 'local function hide_existing_panel(s)' "$top_panel"
grep -Fq 's.top_panel = nil' "$top_panel"
grep -Fq 'panel.visible = false' "$top_panel"
grep -Fq 'panel:struts { top = 0 }' "$top_panel"
grep -Fq "screen.connect_signal('removed', hide_existing_panel)" "$top_panel"

cleanup_line="$(grep -n 'hide_existing_panel(s)' "$top_panel" | tail -n 1 | cut -d: -f1)"
create_line="$(grep -n 'local panel = wibox' "$top_panel" | cut -d: -f1)"
test "$cleanup_line" -lt "$create_line"

printf 'top panel lifecycle tests passed\n'
