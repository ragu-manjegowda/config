#!/usr/bin/env bash
set -euo pipefail

REPO_HOME="${REPO_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
SERVICE="$REPO_HOME/.config/systemd/user/xidlehook.service"
IDLE_SCRIPT="$REPO_HOME/.config/scripts/start_xidlehook.sh"
RESET_SCRIPT="$REPO_HOME/.config/awesome/utilities/reset-primary-display"
SETUP_SCRIPT="$REPO_HOME/.config/awesome/utilities/setup-monitors"

if grep -Fq 'ExecCondition=' "$SERVICE"; then
    printf '%s\n' 'xidlehook service must not depend on a missing session environment' >&2
    exit 1
fi
grep -Fq -- '--not-when-audio' "$IDLE_SCRIPT"
if grep -Fq -- '--not-when-fullscreen' "$IDLE_SCRIPT"; then
    printf '%s\n' 'fullscreen inhibition must not suppress display power-off' >&2
    exit 1
fi
grep -Fq 'xset s off' "$IDLE_SCRIPT"
grep -Fq 'xset dpms 0 0 0' "$IDLE_SCRIPT"
grep -Fq -- '--timer 480' "$IDLE_SCRIPT"
grep -Fq 'xset dpms force off' "$IDLE_SCRIPT"
grep -Fq "'xset dpms force on'" "$IDLE_SCRIPT"
if grep -Fq 'reset-primary-display --force' "$IDLE_SCRIPT"; then
    printf '%s\n' 'routine DPMS wake must not recreate the X screen' >&2
    exit 1
fi
grep -Fq 'reset-primary-display" --once' "$SETUP_SCRIPT"
grep -Fq 'DISPLAY_RESET_SETTLE_SECONDS' "$RESET_SCRIPT"
grep -Fq 'watchdog_pid' "$RESET_SCRIPT"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cat > "$tmp_dir/xrandr" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DISPLAY_RESET_TEST_LOG"
EOF
chmod +x "$tmp_dir/xrandr"

cat > "$tmp_dir/xset" <<'EOF'
#!/usr/bin/env bash
printf 'xset %s\n' "$*" >> "$DISPLAY_RESET_TEST_LOG"
EOF
chmod +x "$tmp_dir/xset"

cat > "$tmp_dir/read-display-config" <<'EOF'
#!/usr/bin/env bash
cat <<'CONFIG'
export PRIMARY_NAME="eDP-1"
export PRIMARY_MODE="2880x1800"
export PRIMARY_POS="0x0"
CONFIG
EOF
chmod +x "$tmp_dir/read-display-config"

export DISPLAY_RESET_XRANDR_BIN="$tmp_dir/xrandr"
export DISPLAY_RESET_XSET_BIN="$tmp_dir/xset"
export DISPLAY_RESET_SLEEP_BIN=true
export DISPLAY_RESET_CONFIG_READER="$tmp_dir/read-display-config"
export DISPLAY_RESET_STATE_FILE="$tmp_dir/reset-done"
export DISPLAY_RESET_TEST_LOG="$tmp_dir/xrandr.log"

"$RESET_SCRIPT" --once
"$RESET_SCRIPT" --once
[[ "$(grep -c -- '--off' "$DISPLAY_RESET_TEST_LOG")" == 1 ]]

"$RESET_SCRIPT" --force
[[ "$(grep -c -- '--off' "$DISPLAY_RESET_TEST_LOG")" == 2 ]]
grep -Fq -- '--output eDP-1 --primary --mode 2880x1800 --pos 0x0' \
    "$DISPLAY_RESET_TEST_LOG"

cat > "$tmp_dir/watchdog-sleep" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == 4 ]]; then
    /usr/bin/sleep 1
else
    /usr/bin/sleep 10
fi
EOF
chmod +x "$tmp_dir/watchdog-sleep"

: > "$DISPLAY_RESET_TEST_LOG"
DISPLAY_RESET_SLEEP_BIN="$tmp_dir/watchdog-sleep" "$RESET_SCRIPT" --force &
reset_pid=$!
for _ in {1..50}; do
    grep -Fq -- '--output eDP-1 --off' "$DISPLAY_RESET_TEST_LOG" && break
    /usr/bin/sleep 0.1
done
grep -Fq -- '--output eDP-1 --off' "$DISPLAY_RESET_TEST_LOG"
kill -9 "$reset_pid"
wait "$reset_pid" 2>/dev/null || true
/usr/bin/sleep 2
grep -Fq -- '--output eDP-1 --primary --mode 2880x1800 --pos 0x0' \
    "$DISPLAY_RESET_TEST_LOG"
grep -Fq 'xset dpms force on' "$DISPLAY_RESET_TEST_LOG"

printf '%s\n' 'xidlehook display recovery tests passed'
