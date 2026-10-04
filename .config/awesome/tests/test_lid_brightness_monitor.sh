#!/usr/bin/env bash

set -euo pipefail

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_HOME=$(cd "$TEST_DIR/../../.." && pwd)
SCRIPT="$REPO_HOME/.config/scripts/lid-brightness-monitor"
SERVICE="$REPO_HOME/.config/systemd/user/lid-brightness-manager.service"
SETUP_MONITORS="$REPO_HOME/.config/awesome/utilities/setup-monitors"
TEST_ROOT=$(mktemp -d)
TEST_USER="lid-brightness-test-$$"
LEGACY_CACHE="/tmp/laptop_brightness_${TEST_USER}"
RESTORED_VALUE="$TEST_ROOT/restored"

cleanup() {
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
grep -Fq 'systemctl --user restart lid-brightness-manager.service' \
    "$SETUP_MONITORS"

mkdir -p "$TEST_ROOT/bin"
cat > "$TEST_ROOT/bin/config-reader" <<'EOF'
#!/usr/bin/env bash
printf 'export PRIMARY_NAME="eDP-1"\nexport EXTERNAL_NAME="DP-1-1"\n'
EOF
cat > "$TEST_ROOT/bin/xrandr" <<'EOF'
#!/usr/bin/env bash
cat "$LID_TEST_TOPOLOGY"
EOF
cat > "$TEST_ROOT/bin/inhibit" <<'EOF'
#!/usr/bin/env bash
printf 'inhibit %s\n' "$*" >> "$LID_TEST_EVENTS"
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

printf '%s\n' 'lid brightness restore tests passed'
