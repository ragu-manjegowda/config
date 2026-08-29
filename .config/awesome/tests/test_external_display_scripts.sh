#!/usr/bin/env bash
set -euo pipefail

ROOT="${REPO_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
CONNECT="$ROOT/.config/awesome/utilities/connect-external"
DISCONNECT="$ROOT/.config/awesome/utilities/disconnect-external"
SETUP="$ROOT/.config/awesome/utilities/setup-monitors"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/home/.config/awesome/utilities" "$tmp_dir/bin"

cat > "$tmp_dir/home/.config/awesome/utilities/read-display-config" <<'EOF'
#!/usr/bin/env bash
if [[ "${CONFIG_EXIT:-0}" != 0 ]]; then
    exit "$CONFIG_EXIT"
fi
cat <<'CONFIG'
export DISPLAY_DPI=144
export PRIMARY_NAME="eDP-1"
export PRIMARY_MODE="2880x1800"
export PRIMARY_POS="0x0"
export EXTERNAL_NAME="DP-4"
export EXTERNAL_MODE="3840x2160"
export EXTERNAL_POS="2880x0"
export EXTERNAL_SCALE_FROM="2880x1620"
CONFIG
EOF

cat > "$tmp_dir/home/.config/awesome/utilities/setup-monitors" <<'EOF'
#!/usr/bin/env bash
printf 'setup-monitors\n' >> "$DISPLAY_TEST_LOG"
exit "${SETUP_EXIT:-0}"
EOF

cat > "$tmp_dir/home/.config/awesome/utilities/reset-primary-display" <<'EOF'
#!/usr/bin/env bash
printf 'reset-primary-display %s\n' "$*" >> "$DISPLAY_TEST_LOG"
EOF

cat > "$tmp_dir/bin/xrandr" <<'EOF'
#!/usr/bin/env bash
printf 'xrandr %s\n' "$*" >> "$DISPLAY_TEST_LOG"
if [[ "${1:-}" == --current ]]; then
    cat "$XRANDR_STATE"
    exit 0
fi
if [[ "${XRANDR_EXIT:-0}" != 0 ]]; then
    exit "$XRANDR_EXIT"
fi
if [[ "${XRANDR_FAIL_ONCE:-0}" == 1 && ! -e "$DISPLAY_TEST_LOG.xrandr-failed" ]]; then
    : > "$DISPLAY_TEST_LOG.xrandr-failed"
    exit 42
fi
EOF

cat > "$tmp_dir/bin/awesome-client" <<'EOF'
#!/usr/bin/env bash
printf 'awesome-client %s\n' "$*" >> "$DISPLAY_TEST_LOG"
if [[ "$*" == *'#s.tags'* ]]; then
    if [[ "${AWESOME_READY:-1}" == 1 ]]; then
        printf '%s\n' 'string "ready"'
    fi
else
    if [[ "${AWESOME_EXIT:-0}" != 0 ]]; then
        exit "$AWESOME_EXIT"
    fi
    if [[ "${AWESOME_OUTPUT_INVALID:-0}" == 1 ]]; then
        printf '%s\n' 'string "not ok"'
    else
        printf '%s\n' 'string "ok"'
    fi
fi
EOF

cat > "$tmp_dir/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
printf 'systemctl %s\n' "$*" >> "$DISPLAY_TEST_LOG"
if [[ "$*" == *'is-active'* ]]; then
    [[ "${MANAGER_ACTIVE:-1}" == 1 ]]
    exit
fi
if [[ "${SYSTEMCTL_EXIT:-0}" != 0 ]]; then
    exit "$SYSTEMCTL_EXIT"
fi
EOF

cat > "$tmp_dir/bin/sleep" <<'EOF'
#!/usr/bin/env bash
printf 'sleep %s\n' "$*" >> "$DISPLAY_TEST_LOG"
EOF

chmod +x "$tmp_dir/home/.config/awesome/utilities/"* "$tmp_dir/bin/"*

export HOME="$tmp_dir/home"
export PATH="$tmp_dir/bin:/usr/bin:/bin"
export DISPLAY_TEST_LOG="$tmp_dir/commands.log"
export XRANDR_STATE="$tmp_dir/xrandr.state"
export XDG_RUNTIME_DIR="$tmp_dir/runtime"
mkdir -p "$XDG_RUNTIME_DIR"

printf '%s\n' 'eDP-1 connected primary 2880x1800+0+0' > "$XRANDR_STATE"
if "$CONNECT" >"$tmp_dir/output" 2>&1; then
    printf '%s\n' 'connect must fail when the configured external output is absent' >&2
    exit 1
fi

printf '%s\n' \
    'eDP-1 connected primary 2880x1800+0+0' \
    'DP-4 connected' > "$XRANDR_STATE"

: > "$DISPLAY_TEST_LOG"
CONFIG_EXIT=22
export CONFIG_EXIT
if "$CONNECT" >"$tmp_dir/output" 2>&1; then
    printf '%s\n' 'connect must fail when display configuration cannot be loaded' >&2
    exit 1
fi
unset CONFIG_EXIT
[[ ! -s "$DISPLAY_TEST_LOG" ]]

: > "$DISPLAY_TEST_LOG"
SETUP_EXIT=25
export SETUP_EXIT
if "$CONNECT" >"$tmp_dir/output" 2>&1; then
    printf '%s\n' 'connect must fail when display setup fails' >&2
    exit 1
fi
unset SETUP_EXIT
if grep -Fq 'awesome-client' "$DISPLAY_TEST_LOG"; then
    printf '%s\n' 'connect must not query Awesome after setup failure' >&2
    exit 1
fi
grep -Fq -- '--output DP-4 --off' "$DISPLAY_TEST_LOG"

printf '%s\n' \
    'eDP-1 connected' \
    'DP-4 connected primary 2880x1620+0+0' > "$XRANDR_STATE"
: > "$DISPLAY_TEST_LOG"
AWESOME_READY=0
export AWESOME_READY
if "$CONNECT" >"$tmp_dir/output" 2>&1; then
    printf '%s\n' 'connect must fail when an external-only layout is not decorated' >&2
    exit 1
fi
unset AWESOME_READY
grep -Fq -- '--output eDP-1 --off --output DP-4 --primary --mode 3840x2160 --pos 0x0' \
    "$DISPLAY_TEST_LOG"

printf '%s\n' \
    'eDP-1 connected primary 2880x1800+0+0' \
    'DP-4 connected' > "$XRANDR_STATE"

: > "$DISPLAY_TEST_LOG"
AWESOME_READY=0
export AWESOME_READY
if "$CONNECT" >"$tmp_dir/output" 2>&1; then
    printf '%s\n' 'connect must fail when Awesome does not decorate the external screen' >&2
    exit 1
fi
unset AWESOME_READY
if grep -Fq 'migrate_to_external' "$DISPLAY_TEST_LOG"; then
    printf '%s\n' 'connect must not migrate before external screen readiness' >&2
    exit 1
fi
grep -Fq -- '--output DP-4 --off' "$DISPLAY_TEST_LOG"

: > "$DISPLAY_TEST_LOG"
AWESOME_EXIT=31
export AWESOME_EXIT
if "$CONNECT" >"$tmp_dir/output" 2>&1; then
    printf '%s\n' 'connect must fail when client migration fails' >&2
    exit 1
fi
unset AWESOME_EXIT
grep -Fq -- '--output DP-4 --mode 3840x2160' "$DISPLAY_TEST_LOG"

: > "$DISPLAY_TEST_LOG"
AWESOME_OUTPUT_INVALID=1
export AWESOME_OUTPUT_INVALID
if "$CONNECT" >"$tmp_dir/output" 2>&1; then
    printf '%s\n' 'connect must reject malformed Awesome success output' >&2
    exit 1
fi
unset AWESOME_OUTPUT_INVALID
grep -Fq -- '--output DP-4 --mode 3840x2160' "$DISPLAY_TEST_LOG"

: > "$DISPLAY_TEST_LOG"
"$CONNECT" >"$tmp_dir/output" 2>&1
if grep -Fq 'awesome.restart' "$DISPLAY_TEST_LOG"; then
    printf '%s\n' 'connect must not restart Awesome after dynamic screen initialization' >&2
    exit 1
fi

printf '%s\n' \
    'eDP-1 connected primary 2880x1800+0+0' \
    'DP-4 connected 2880x1620+2880+0' > "$XRANDR_STATE"
: > "$DISPLAY_TEST_LOG"
"$CONNECT" >"$tmp_dir/output" 2>&1
[[ "$(grep -c 'setup-monitors' "$DISPLAY_TEST_LOG")" == 1 ]]

printf '%s\n' \
    'eDP-1 connected 1920x1080+0+0' \
    'DP-4 connected 2880x1620+2880+0' > "$XRANDR_STATE"
: > "$DISPLAY_TEST_LOG"
"$CONNECT" >"$tmp_dir/output" 2>&1
grep -Fq 'setup-monitors' "$DISPLAY_TEST_LOG"

printf '%s\n' \
    'eDP-1 connected primary 2880x1800+0+0' \
    'DP-4 connected 2880x1620+2880+0' > "$XRANDR_STATE"

exec 8>"$XDG_RUNTIME_DIR/awesome-display-transition-${UID}.lock"
flock -n 8
: > "$DISPLAY_TEST_LOG"
if "$CONNECT" >"$tmp_dir/output" 2>&1; then
    printf '%s\n' 'connect must reject a concurrent display transition' >&2
    exit 1
fi
[[ ! -s "$DISPLAY_TEST_LOG" ]]
flock -u 8

flock -n 8
: > "$DISPLAY_TEST_LOG"
if DISPLAY_TRANSITION_LOCK_FD=9 "$SETUP" >"$tmp_dir/output" 2>&1; then
    printf '%s\n' 'setup must verify rather than trust an inherited-lock claim' >&2
    exit 1
fi
[[ ! -s "$DISPLAY_TEST_LOG" ]]
flock -u 8

: > "$DISPLAY_TEST_LOG"
AWESOME_EXIT=31
export AWESOME_EXIT
if "$DISCONNECT" >"$tmp_dir/output" 2>&1; then
    printf '%s\n' 'disconnect must fail when client migration fails' >&2
    exit 1
fi
unset AWESOME_EXIT
if grep -Fq 'xrandr --dpi' "$DISPLAY_TEST_LOG"; then
    printf '%s\n' 'disconnect must not change topology after migration failure' >&2
    exit 1
fi
grep -Fq 'restore_to_external' "$DISPLAY_TEST_LOG"

: > "$DISPLAY_TEST_LOG"
SYSTEMCTL_EXIT=23
export SYSTEMCTL_EXIT
if "$DISCONNECT" >"$tmp_dir/output" 2>&1; then
    printf '%s\n' 'disconnect must fail when the brightness manager cannot stop' >&2
    exit 1
fi
unset SYSTEMCTL_EXIT
if grep -Fq 'xrandr --dpi' "$DISPLAY_TEST_LOG"; then
    printf '%s\n' 'disconnect must not change topology after service failure' >&2
    exit 1
fi

: > "$DISPLAY_TEST_LOG"
"$DISCONNECT" >"$tmp_dir/output" 2>&1
[[ "$(grep -c '^xrandr --dpi' "$DISPLAY_TEST_LOG")" == 1 ]]
grep -Fq -- '--output eDP-1 --primary --mode 2880x1800 --pos 0x0 --output DP-4 --off' \
    "$DISPLAY_TEST_LOG"

printf '%s\n' 'eDP-1 connected primary 2880x1800+0+0' > "$XRANDR_STATE"
: > "$DISPLAY_TEST_LOG"
"$DISCONNECT" >"$tmp_dir/output" 2>&1
if grep -Eq 'systemctl|awesome-client|xrandr --dpi' "$DISPLAY_TEST_LOG"; then
    printf '%s\n' 'disconnect must be a no-op when external output is inactive' >&2
    exit 1
fi

printf '%s\n' \
    'eDP-1 connected primary 2880x1800+0+0' \
    'DP-4 connected 2880x1620+2880+0' > "$XRANDR_STATE"
: > "$DISPLAY_TEST_LOG"
XRANDR_FAIL_ONCE=1
export XRANDR_FAIL_ONCE
if "$DISCONNECT" >"$tmp_dir/output" 2>&1; then
    printf '%s\n' 'disconnect must fail when the atomic topology change fails' >&2
    exit 1
fi
unset XRANDR_FAIL_ONCE
grep -Fq 'systemctl --user stop lid-brightness-manager.service' "$DISPLAY_TEST_LOG"
grep -Fq 'systemctl --user start lid-brightness-manager.service' "$DISPLAY_TEST_LOG"
grep -Fq 'restore_to_external' "$DISPLAY_TEST_LOG"

printf '%s\n' \
    'eDP-1 connected primary 2880x1800+0+0' \
    'DP-4 connected' > "$XRANDR_STATE"
: > "$DISPLAY_TEST_LOG"
"$SETUP" >"$tmp_dir/output" 2>&1
[[ "$(grep -c '^xrandr --dpi' "$DISPLAY_TEST_LOG")" == 1 ]]
grep -Fq -- '--output eDP-1 --primary --mode 2880x1800 --pos 0x0 --output DP-4 --mode 3840x2160 --pos 2880x0 --scale-from 2880x1620' \
    "$DISPLAY_TEST_LOG"

printf '%s\n' 'external display script tests passed'
