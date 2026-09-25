#!/usr/bin/env bash
set -euo pipefail

helper="$HOME/.config/awesome/utilities/ensure-darkman"
unit="$HOME/.config/systemd/user/darkman.service.d/override.conf"
xsettings_unit="$HOME/.config/systemd/user/xsettingsd.service.d/override.conf"
apps="$HOME/.config/awesome/configuration/apps.lua"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cat > "$tmp_dir/systemctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DARKMAN_TEST_LOG"
if [[ "$*" == '--user reset-failed darkman.service' ]]; then
    touch "$DARKMAN_TEST_RESET_FILE"
fi
if [[ "$*" == '--user start darkman.service' && "${DARKMAN_TEST_START_FAIL:-}" == 1 &&
    ! -e "$DARKMAN_TEST_RESET_FILE" ]]; then
    exit 1
fi
EOF
cat > "$tmp_dir/darkman" <<'EOF'
#!/usr/bin/env bash
[[ "${DARKMAN_TEST_HEALTHY:-}" == 1 ]] || exit 1
printf 'light\n'
EOF
cat > "$tmp_dir/timeout" <<'EOF'
#!/usr/bin/env bash
shift
"$@"
EOF
chmod +x "$tmp_dir/systemctl" "$tmp_dir/darkman" "$tmp_dir/timeout"

run_helper() {
    DARKMAN_SYSTEMCTL_BIN="$tmp_dir/systemctl" \
        DARKMAN_BIN="$tmp_dir/darkman" \
        DARKMAN_TIMEOUT_BIN="$tmp_dir/timeout" \
        DARKMAN_TEST_LOG="$tmp_dir/actions" \
        DARKMAN_TEST_RESET_FILE="$tmp_dir/reset" \
        bash "$helper"
}

DARKMAN_TEST_HEALTHY=1 run_helper
grep -Fxq -- '--user start darkman.service' "$tmp_dir/actions"
if grep -Fq 'restart darkman.service' "$tmp_dir/actions"; then
    printf 'Healthy Darkman was restarted\n' >&2
    exit 1
fi

: > "$tmp_dir/actions"
DARKMAN_TEST_HEALTHY=0 run_helper
grep -Fxq -- '--user restart darkman.service' "$tmp_dir/actions"

: > "$tmp_dir/actions"
DARKMAN_TEST_START_FAIL=1 DARKMAN_TEST_HEALTHY=1 run_helper
grep -Fxq -- '--user reset-failed darkman.service' "$tmp_dir/actions"
if grep -Fq 'restart darkman.service' "$tmp_dir/actions"; then
    printf 'Darkman was restarted after successful recovery\n' >&2
    exit 1
fi

grep -Fxq 'Restart=always' "$unit"
grep -Fxq 'RestartSec=5s' "$unit"
grep -Fq "'systemctl --user start darkman.service'" "$apps"
grep -Fxq 'ExecStart=/usr/bin/xsettingsd -c %h/.config/xsettingsd/xsettingsd.conf' "$xsettings_unit"
grep -Fq "'systemctl --user start xsettingsd.service'" "$apps"
for mode in dark light; do
    script="$HOME/.config/darkman/$mode-mode.d/set-gtk-theme.sh"
    grep -Fq 'systemctl --user reload xsettingsd.service' "$script"
    grep -Fq 'systemctl --user start xsettingsd.service' "$script"
done
if grep -Fq 'reload-or-restart --now darkman.service' "$apps"; then
    printf 'Awesome startup still resets manual Darkman mode\n' >&2
    exit 1
fi

printf 'Darkman lifecycle tests passed\n'
