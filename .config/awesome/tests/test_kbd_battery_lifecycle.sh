#!/usr/bin/env bash

set -euo pipefail

widget="$HOME/.config/awesome/widget/kbd-battery/init.lua"

test "$(grep -c 'system_bus:signal_subscribe' "$widget")" -eq 3
grep -Fq "'org.freedesktop.DBus.Properties'" "$widget"
grep -Fq "'PropertiesChanged'" "$widget"
grep -Fq "'InterfacesAdded'" "$widget"
grep -Fq "'InterfacesRemoved'" "$widget"
grep -Fq "awesome.emit_signal('module::kbd_battery_status'" "$widget"
grep -Fq "{ '/usr/bin/timeout', '10', battery_command }" "$widget"
grep -Fq 'battery_timer:stop()' "$widget"
grep -Fq 'battery_timer:again()' "$widget"
grep -Fq 'timeout = 18000' "$widget"
grep -Fq 'timeout = 120' "$widget"
grep -Fq 'single_shot = true' "$widget"
grep -Fq 'visible = false' "$widget"

if grep -Fq 'autostart = true' "$widget"; then
    printf 'keyboard battery timer must not run while disconnected\n' >&2
    exit 1
fi

printf 'keyboard battery lifecycle tests passed\n'
