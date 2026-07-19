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

printf '%s\n' 'lid brightness restore tests passed'
