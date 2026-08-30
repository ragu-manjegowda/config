#!/usr/bin/env bash

set -euo pipefail

action="$1"
awesome_client_bin="${XIDLEHOOK_AWESOME_CLIENT_BIN:-awesome-client}"
xset_bin="${XIDLEHOOK_XSET_BIN:-xset}"

case "$action" in
    off)
        "$awesome_client_bin" 'awesome.emit_signal("module::fingerprint_stop")' >/dev/null || true
        "$xset_bin" dpms force off
        ;;
    on)
        "$xset_bin" dpms force on
        "$awesome_client_bin" 'awesome.emit_signal("module::fingerprint_start")' >/dev/null || true
        ;;
    *)
        printf 'Usage: %s {on|off}\n' "$0" >&2
        exit 2
        ;;
esac
