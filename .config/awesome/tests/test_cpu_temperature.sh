#!/usr/bin/env bash
set -euo pipefail

fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/hwmon0" "$fixture/hwmon1"
printf 'INT3400 Thermal\n' > "$fixture/hwmon0/name"
printf '20000\n' > "$fixture/hwmon0/temp1_input"
printf 'coretemp\n' > "$fixture/hwmon1/name"
printf 'Package id 0\n' > "$fixture/hwmon1/temp1_label"
printf '61000\n' > "$fixture/hwmon1/temp1_input"

AWESOME_CPU_TEMP_FIXTURE="$fixture" luajit <<'LUA'
package.path = os.getenv('HOME') .. '/.config/awesome/?.lua;' .. package.path
local temperature = require('library.cpu-temperature')
local fixture = os.getenv('AWESOME_CPU_TEMP_FIXTURE')
assert(temperature.read(fixture) == 61, 'read a platform zone instead of the CPU package')
assert(temperature.read(fixture .. '/missing') == nil, 'missing sensors should be unavailable')
LUA

printf 'not-a-number\n' > "$fixture/hwmon1/temp1_input"
AWESOME_CPU_TEMP_FIXTURE="$fixture" luajit <<'LUA'
package.path = os.getenv('HOME') .. '/.config/awesome/?.lua;' .. package.path
assert(require('library.cpu-temperature').read(os.getenv('AWESOME_CPU_TEMP_FIXTURE')) == nil,
    'invalid CPU temperature should not appear as zero degrees')
LUA

printf 'CPU temperature tests passed\n'
