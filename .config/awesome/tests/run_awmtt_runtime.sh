#!/usr/bin/env bash

set -euo pipefail

REPO_HOME="${REPO_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
RUNTIME_NAME="${1:-lua}"
RUNTIME_SECONDS="${AWESOME_RUNTIME_SECONDS:-8}"
LOG_DIR="${GITHUB_WORKSPACE:-$REPO_HOME}/test-logs"
ERROR_LOG="$LOG_DIR/awesome-$RUNTIME_NAME-errors.log"
CRITICAL_LOG="$LOG_DIR/awesome-$RUNTIME_NAME-critical.log"
XVFB_LOG="$LOG_DIR/awesome-$RUNTIME_NAME-xvfb.log"
AWMTT_LOG="$LOG_DIR/awesome-$RUNTIME_NAME-awmtt.log"
RUNTIME_DIR=""
XVFB_PID=""
XEPHYR_PID=""
AWESOME_PID=""
SYSTEM_DBUS_PID=""

if [[ ! "$RUNTIME_NAME" =~ ^[a-z0-9_-]+$ ]]; then
    printf 'Invalid runtime name: %s\n' "$RUNTIME_NAME" >&2
    exit 2
fi
if [[ ! "$RUNTIME_SECONDS" =~ ^[1-9][0-9]*$ ]]; then
    printf 'Invalid runtime duration: %s\n' "$RUNTIME_SECONDS" >&2
    exit 2
fi
RUNTIME_DIR="$(mktemp -d)"

stop_awesome() {
    if [[ -z "$AWESOME_PID" ]]; then
        return
    fi

    kill "$AWESOME_PID" >/dev/null 2>&1 || true
    for _ in {1..20}; do
        if ! kill -0 "$AWESOME_PID" 2>/dev/null; then
            AWESOME_PID=""
            return
        fi
        sleep 0.1
    done
}

cleanup() {
    local status=$?

    trap - EXIT
    stop_awesome
    if [[ -n "$XEPHYR_PID" ]]; then
        kill "$XEPHYR_PID" >/dev/null 2>&1 || true
    fi
    if [[ -n "$XVFB_PID" ]]; then
        kill "$XVFB_PID" >/dev/null 2>&1 || true
    fi
    if [[ -n "${DBUS_SESSION_BUS_PID:-}" ]]; then
        kill "$DBUS_SESSION_BUS_PID" >/dev/null 2>&1 || true
    fi
    if [[ -n "$SYSTEM_DBUS_PID" ]]; then
        kill "$SYSTEM_DBUS_PID" >/dev/null 2>&1 || true
    fi
    rm -rf "$RUNTIME_DIR"
    exit "$status"
}
trap cleanup EXIT

mkdir -p "$LOG_DIR"
: > "$ERROR_LOG"
: > "$CRITICAL_LOG"
: > "$XVFB_LOG"
: > "$AWMTT_LOG"
chmod 700 "$RUNTIME_DIR"

export HOME="$REPO_HOME"
export XDG_RUNTIME_DIR="$RUNTIME_DIR"
export AWESOME_SKIP_AUTOSTART=1

Xvfb :99 -screen 0 1920x1080x24 2>"$XVFB_LOG" &
XVFB_PID=$!
export DISPLAY=:99
sleep 2
if ! kill -0 "$XVFB_PID" 2>/dev/null; then
    printf 'Xvfb failed to start\n' >&2
    cat "$XVFB_LOG" >&2
    exit 1
fi

mkdir -p /var/lib/dbus /run/dbus
dbus-uuidgen --ensure=/var/lib/dbus/machine-id
if [[ ! -S /run/dbus/system_bus_socket ]]; then
    SYSTEM_DBUS_PID="$(dbus-daemon --system --fork --print-pid)"
fi
eval "$(dbus-launch --sh-syntax)"
export DBUS_SESSION_BUS_ADDRESS

printf 'Starting AwesomeWM (%s) for %s seconds...\n' "$RUNTIME_NAME" "$RUNTIME_SECONDS"
awmtt start -C "$REPO_HOME/.config/awesome/rc.lua" >"$AWMTT_LOG" 2>"$ERROR_LOG"
awmtt_output="$(<"$AWMTT_LOG")"
printf '%s\n' "$awmtt_output"

if [[ "$awmtt_output" =~ Awesome\ PID:\ ([0-9]+),\ Xephyr\ PID:\ ([0-9]+) ]]; then
    AWESOME_PID="${BASH_REMATCH[1]}"
    XEPHYR_PID="${BASH_REMATCH[2]}"
else
    printf 'Unable to identify nested AwesomeWM processes\n' >&2
    cat "$ERROR_LOG" >&2
    exit 1
fi

if ! kill -0 "$AWESOME_PID" 2>/dev/null; then
    printf 'AwesomeWM (%s) did not remain running after startup\n' "$RUNTIME_NAME" >&2
    cat "$ERROR_LOG" >&2
    exit 1
fi

sleep "$RUNTIME_SECONDS"
if ! kill -0 "$AWESOME_PID" 2>/dev/null; then
    printf 'AwesomeWM (%s) exited during the runtime check\n' "$RUNTIME_NAME" >&2
    cat "$ERROR_LOG" >&2
    exit 1
fi

stop_awesome

grep -Eai \
    'stack traceback|Traceback \(most recent call last\)|ModuleNotFoundError|command not found|attempt to (call|index)' \
    "$ERROR_LOG" > "$CRITICAL_LOG" || true
grep -Ea ' E: |error:' "$ERROR_LOG" | \
    grep -F '.config/awesome' >> "$CRITICAL_LOG" || true

if [[ -s "$CRITICAL_LOG" ]]; then
    printf 'Critical AwesomeWM (%s) runtime errors:\n' "$RUNTIME_NAME" >&2
    cat "$CRITICAL_LOG" >&2
    printf '\nFull runtime log:\n' >&2
    cat "$ERROR_LOG" >&2
    exit 1
fi

diagnostic_count="$(wc -l < "$ERROR_LOG")"
printf 'AwesomeWM (%s) remained healthy for %s seconds (%s diagnostic lines archived)\n' \
    "$RUNTIME_NAME" "$RUNTIME_SECONDS" "$diagnostic_count"
