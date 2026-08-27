#!/usr/bin/env bash
set -euo pipefail

REPO_HOME="${REPO_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
SERVICE="$REPO_HOME/.config/systemd/user/xidlehook.service"
IDLE_SCRIPT="$REPO_HOME/.config/scripts/start_xidlehook.sh"
RESET_SCRIPT="$REPO_HOME/.config/awesome/utilities/reset-primary-display"
SETUP_SCRIPT="$REPO_HOME/.config/awesome/utilities/setup-monitors"

! grep -Fq 'ExecCondition=' "$SERVICE"
grep -Fq 'xset s off' "$IDLE_SCRIPT"
grep -Fq 'xset dpms 0 0 0' "$IDLE_SCRIPT"
grep -Fq -- '--timer 480' "$IDLE_SCRIPT"
grep -Fq 'xset dpms force off' "$IDLE_SCRIPT"
grep -Fq 'reset-primary-display --force' "$IDLE_SCRIPT"
grep -Fq 'reset-primary-display" --once' "$SETUP_SCRIPT"
grep -Fq 'DISPLAY_RESET_SETTLE_SECONDS' "$RESET_SCRIPT"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cat > "$tmp_dir/xrandr" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DISPLAY_RESET_TEST_LOG"
EOF
chmod +x "$tmp_dir/xrandr"

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

printf '%s\n' 'xidlehook display recovery tests passed'
