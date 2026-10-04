#!/usr/bin/env bash

set -euo pipefail

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_HOME=$(cd "$TEST_DIR/../../.." && pwd)
SCRIPT="$REPO_HOME/.config/scripts/lid-brightness-monitor"
SERVICE="$REPO_HOME/.config/systemd/user/lid-brightness-manager.service"
SETUP_MONITORS="$REPO_HOME/.config/awesome/utilities/display/setup-monitors"
TEST_ROOT=$(mktemp -d)
TEST_USER="lid-brightness-test-$$"
LEGACY_CACHE="/tmp/laptop_brightness_${TEST_USER}"
RESTORED_VALUE="$TEST_ROOT/restored"
watcher_pid=''

cleanup() {
    if [[ -n "$watcher_pid" ]]; then
        kill "$watcher_pid" 2>/dev/null || true
        wait "$watcher_pid" 2>/dev/null || true
    fi
    rm -rf "$TEST_ROOT"
    rm -f "$LEGACY_CACHE"
}
trap cleanup EXIT

cat > "$TEST_ROOT/light" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "-S" ]; then
    printf '%s\n' "$2" > "$RESTORED_VALUE"
fi
EOF
chmod +x "$TEST_ROOT/light"

export RESTORED_VALUE
export USER="$TEST_USER"
export LID_BRIGHTNESS_LIGHT_BIN="$TEST_ROOT/light"
export LID_BRIGHTNESS_CACHE="$TEST_ROOT/state/brightness"

mkdir -p "$(dirname "$LID_BRIGHTNESS_CACHE")"
printf '%s\n' '73.5' > "$LID_BRIGHTNESS_CACHE"
"$SCRIPT" --restore

test "$(cat "$RESTORED_VALUE")" = '73.5'
test ! -e "$LID_BRIGHTNESS_CACHE"

rm -f "$RESTORED_VALUE"
printf '%s\n' '61.0' > "$LEGACY_CACHE"
"$SCRIPT" --restore

test "$(cat "$RESTORED_VALUE")" = '61.0'
test ! -e "$LEGACY_CACHE"

grep -Fq 'ExecStop=%h/.config/scripts/lid-brightness-monitor --restore' \
    "$SERVICE"
# systemd, not this test shell, expands the literal MAINPID token.
# shellcheck disable=SC2016
grep -Fq 'ExecReload=/usr/bin/kill -HUP $MAINPID' "$SERVICE"
grep -Fq 'systemctl --user reload-or-restart lid-brightness-manager.service' \
    "$SETUP_MONITORS"

mkdir -p "$TEST_ROOT/bin"
cat > "$TEST_ROOT/bin/config-reader" <<'EOF'
#!/usr/bin/env bash
if [[ -e "$LID_TEST_TOPOLOGY.config" ]]; then
    cat "$LID_TEST_TOPOLOGY.config"
    exit
fi
printf 'export PRIMARY_NAME="eDP-1"\nexport EXTERNAL_NAME="DP-1-1"\n'
EOF
cat > "$TEST_ROOT/bin/xrandr" <<'EOF'
#!/usr/bin/env bash
if [[ -e "$LID_TEST_TOPOLOGY.fail" ]]; then
    printf 'Authorization required\n' >&2
    exit 1
fi
cat "$LID_TEST_TOPOLOGY"
EOF
cat > "$TEST_ROOT/bin/inhibit" <<'EOF'
#!/usr/bin/env bash
printf 'inhibit %s\n' "$*" >> "$LID_TEST_EVENTS"
printf '%s\n' "$$" > "$LID_TEST_INHIBITOR_PID"
exec sleep 30
EOF
cat > "$TEST_ROOT/bin/events" <<'EOF'
#!/usr/bin/env bash
printf 'closed\n' > "$LID_BRIGHTNESS_LID_STATE_FILE"
printf 'PropertiesChanged\n'
sleep 0.5
printf 'open\n' > "$LID_BRIGHTNESS_LID_STATE_FILE"
printf 'PropertiesChanged\n'
sleep 0.5
EOF
cat > "$TEST_ROOT/light" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == -G ]]; then printf '64\n'; else printf 'light %s\n' "$*" >> "$LID_TEST_EVENTS"; fi
EOF
chmod +x "$TEST_ROOT/bin/"* "$TEST_ROOT/light"
export LID_BRIGHTNESS_CONFIG_READER="$TEST_ROOT/bin/config-reader"
export LID_BRIGHTNESS_XRANDR_BIN="$TEST_ROOT/bin/xrandr"
export LID_BRIGHTNESS_INHIBIT_BIN="$TEST_ROOT/bin/inhibit"
export LID_BRIGHTNESS_EVENT_BIN="$TEST_ROOT/bin/events"
export LID_BRIGHTNESS_LID_STATE_FILE="$TEST_ROOT/lid"
export LID_TEST_TOPOLOGY="$TEST_ROOT/topology" LID_TEST_EVENTS="$TEST_ROOT/events"
export LID_TEST_INHIBITOR_PID="$TEST_ROOT/inhibitor-pid"
printf 'open\n' > "$LID_BRIGHTNESS_LID_STATE_FILE"
printf 'DP-1-1 connected 3440x1440+2880+0\n' > "$LID_TEST_TOPOLOGY"
"$SCRIPT"
grep -Fq -- '--what=handle-lid-switch' "$LID_TEST_EVENTS"
grep -Fxq -- 'light -S 0' "$LID_TEST_EVENTS"
grep -Fxq -- 'light -S 64' "$LID_TEST_EVENTS"

printf 'DP-1-1 connected\n' > "$LID_TEST_TOPOLOGY"
: > "$LID_TEST_EVENTS"
"$SCRIPT"
[[ ! -s "$LID_TEST_EVENTS" ]]

# Keep the watcher alive so real SIGHUP reloads can exercise state transitions.
cat > "$TEST_ROOT/bin/hold-events" <<'EOF'
#!/usr/bin/env bash
printf 'PropertiesChanged\n'
exec sleep 30
EOF
chmod +x "$TEST_ROOT/bin/hold-events"
export LID_BRIGHTNESS_EVENT_BIN="$TEST_ROOT/bin/hold-events"
printf 'closed\n' > "$LID_BRIGHTNESS_LID_STATE_FILE"
printf 'DP-1-1 connected 3440x1440+2880+0\n' > "$LID_TEST_TOPOLOGY"
: > "$LID_TEST_EVENTS"
"$SCRIPT" > "$TEST_ROOT/watcher.log" 2>&1 &
watcher_pid=$!
wait_for_line() {
    local text="$1" file="$2"
    for _ in {1..100}; do
        if grep -Fq -- "$text" "$file"; then return; fi
        sleep 0.05
    done
    cat "$TEST_ROOT/watcher.log" >&2
    printf 'Timed out waiting for %s\n' "$text" >&2
    return 1
}
wait_for_line 'light -S 0' "$LID_TEST_EVENTS"
inhibitor_pid="$(cat "$LID_TEST_INHIBITOR_PID")"
kill -0 "$inhibitor_pid"
test "$(cat "$LID_BRIGHTNESS_CACHE")" = 64

# An authorization/connection error must not masquerade as a disconnected dock.
touch "$LID_TEST_TOPOLOGY.fail"
printf 'open\n' > "$LID_BRIGHTNESS_LID_STATE_FILE"
kill -HUP "$watcher_pid"
wait_for_line 'retaining lid inhibition and brightness state' "$TEST_ROOT/watcher.log"
kill -0 "$watcher_pid"
kill -0 "$inhibitor_pid"
test "$(cat "$LID_BRIGHTNESS_CACHE")" = 64
if grep -Fxq 'light -S 64' "$LID_TEST_EVENTS"; then
    printf 'Failed X11 query incorrectly restored brightness\n' >&2
    exit 1
fi

# Reconcile after recovery, preserving the same inhibitor and main process.
rm "$LID_TEST_TOPOLOGY.fail"
kill -HUP "$watcher_pid"
wait_for_line 'light -S 64' "$LID_TEST_EVENTS"
kill -0 "$watcher_pid"
kill -0 "$inhibitor_pid"
test "$(grep -c '^inhibit ' "$LID_TEST_EVENTS")" -eq 1

# Refresh configuration as well as topology without restarting the watcher.
printf 'export PRIMARY_NAME="eDP-1"\nexport EXTERNAL_NAME="DP-NEW"\n' > "$LID_TEST_TOPOLOGY.config"
printf 'DP-NEW connected 3440x1440+2880+0\n' > "$LID_TEST_TOPOLOGY"
kill -HUP "$watcher_pid"
sleep 0.3
kill -0 "$watcher_pid"
kill -0 "$inhibitor_pid"
test "$(grep -c '^inhibit ' "$LID_TEST_EVENTS")" -eq 1

# Only a successful inactive-output snapshot may release docked-lid protection.
printf 'DP-NEW connected\n' > "$LID_TEST_TOPOLOGY"
kill -HUP "$watcher_pid"
for _ in {1..100}; do
    if ! kill -0 "$inhibitor_pid" 2>/dev/null; then break; fi
    sleep 0.05
done
if kill -0 "$inhibitor_pid" 2>/dev/null; then
    printf 'Verified inactive display retained the inhibitor\n' >&2
    exit 1
fi
kill -0 "$watcher_pid"
kill -TERM "$watcher_pid"
wait "$watcher_pid"
watcher_pid=''

printf '%s\n' 'lid brightness restore tests passed'
