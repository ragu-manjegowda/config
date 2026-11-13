#!/usr/bin/env bash

set -euo pipefail

fail() {
    printf 'Awesome session check failed: %s\n' "$*" >&2
    exit 1
}

launcher="$HOME/.local/bin/awesome-session"
source_launcher="$HOME/.config/misc/usr/local/libexec/awesome-session"
session="$HOME/.local/share/xsessions/awesome.desktop"
configuration="$HOME/.config/awesome/rc.lua"

[[ -x "$launcher" ]] || fail "launcher is missing or not executable: $launcher"
[[ "$launcher" -ef "$source_launcher" ]] || fail "launcher does not link to the maintained copy: $source_launcher"
[[ -f "$session" ]] || fail "session entry is missing: $session"
for key in Exec TryExec; do
    value="$(sed -n "s/^${key}=//p" "$session")"
    [[ "$value" == "$launcher" ]] || fail "$key must point to $launcher in $session"
done
bash -n "$launcher" || fail "launcher has invalid shell syntax"
command -v awesome >/dev/null || fail "awesome is not installed or not in PATH"
[[ -f "$configuration" ]] || fail "Awesome configuration is missing: $configuration"
awesome -k -c "$configuration" || fail "Awesome configuration validation failed"
printf 'Awesome session check passed.\n'
