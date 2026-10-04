#!/usr/bin/env bash
# Hardware-free: all display commands below are replaced by fixture executables.
set -euo pipefail

# GitHub job containers use a PID 1 that does not reap orphaned mock workers.
# Keep a test-only subreaper alive while the short-lived helper starts/stops
# those workers, so kill -0 reflects running processes rather than zombies.
if [[ "${BLUE_LIGHT_TEST_REAPER:-0}" != 1 ]]; then
    exec python3 - "$0" "$@" <<'PY'
import ctypes
import os
import sys

libc = ctypes.CDLL(None, use_errno=True)
if libc.prctl(36, 1, 0, 0, 0) != 0:  # PR_SET_CHILD_SUBREAPER
    raise OSError(ctypes.get_errno(), "Cannot enable the test worker subreaper")
child = os.fork()
if child == 0:
    os.environ["BLUE_LIGHT_TEST_REAPER"] = "1"
    os.execvp("bash", ["bash", *sys.argv[1:]])
result = 1
while True:
    try:
        pid, status = os.waitpid(-1, 0)
    except ChildProcessError:
        break
    if pid == child:
        result = os.waitstatus_to_exitcode(status)
sys.exit(result if result >= 0 else 128 - result)
PY
fi

root="${REPO_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
helper="$root/.config/awesome/utilities/blue-light"
if grep -Fq 'killall -9 redshift' "$root/.config/awesome/configuration/apps.lua"; then
    printf 'Autostart must not replace the per-output color workers\n' >&2
    exit 1
fi
tmp_dir="$(mktemp -d)"
cleanup() {
    if [[ -d "$tmp_dir/runtime/awesome-blue-light" ]]; then
        for file in "$tmp_dir/runtime/awesome-blue-light/"*.pid; do
            [[ -f "$file" ]] || continue
            kill "$(<"$file")" 2>/dev/null || true
        done
    fi
    rm -rf "$tmp_dir"
}
trap cleanup EXIT
mkdir -p "$tmp_dir/config/redshift" "$tmp_dir/runtime" "$tmp_dir/bin"
export XDG_CONFIG_HOME="$tmp_dir/config" XDG_RUNTIME_DIR="$tmp_dir/runtime"
export BLUE_LIGHT_TEST_LOG="$tmp_dir/commands"
export BLUE_LIGHT_REDSHIFT_BIN="$tmp_dir/bin/redshift"
export BLUE_LIGHT_CONFIG_READER="$tmp_dir/bin/config-reader"
export BLUE_LIGHT_XRANDR_BIN="$tmp_dir/bin/xrandr"
export BLUE_LIGHT_COLOR_BIN="$tmp_dir/bin/monitor-color"
export BLUE_LIGHT_DISPLAY_CONTROL="$tmp_dir/bin/display-control"

cat > "$BLUE_LIGHT_CONFIG_READER" <<'EOF'
#!/usr/bin/env bash
printf 'export EXTERNAL_NAME="DP-1-1"\n'
EOF
cat > "$BLUE_LIGHT_XRANDR_BIN" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' \
    'eDP-1 connected primary 2880x1800+0+0' \
    '    CRTC: 0' \
    'DP-1 disconnected' \
    '    CRTCs: 0 1 2 3' \
    'DP-1-1 connected 3440x1440+2880+0' \
    '    CRTC: 4' \
    'DP-1-2 disconnected' \
    '    CRTCs: 4 5 6 7'
EOF
cat > "$BLUE_LIGHT_REDSHIFT_BIN" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$BLUE_LIGHT_TEST_LOG"
if [[ "$1" == -x ]]; then exit 0; fi
# Emulate Redshift mutating its command-line tokens after option parsing.
exec -a "redshift -c $2 -m randr crtc mock" sleep 60
EOF
chmod +x "$tmp_dir/bin/"*

cat > "$BLUE_LIGHT_COLOR_BIN" <<'EOF'
#!/usr/bin/env bash
printf 'ddc %s\n' "$*" >> "$BLUE_LIGHT_TEST_LOG"
: > "$6"
exec -a "$BLUE_LIGHT_COLOR_BIN --config $4" sleep 60
EOF
cat > "$BLUE_LIGHT_DISPLAY_CONTROL" <<'EOF'
#!/usr/bin/env bash
printf 'restore %s\n' "$*" >> "$BLUE_LIGHT_TEST_LOG"
EOF
chmod +x "$BLUE_LIGHT_COLOR_BIN" "$BLUE_LIGHT_DISPLAY_CONTROL"

[[ "$(bash "$helper" start)" == ON ]]
[[ "$(wc -l < "$BLUE_LIGHT_TEST_LOG")" == 3 ]]
grep -Fxq -- "-c $XDG_CONFIG_HOME/redshift/redshift.conf -m randr:crtc=0 -P" "$BLUE_LIGHT_TEST_LOG"
grep -Fq -- 'ddc --output DP-1-1 --config' "$BLUE_LIGHT_TEST_LOG"
[[ "$(bash "$helper" status)" == ON ]]
primary_pid="$(<"$XDG_RUNTIME_DIR/awesome-blue-light/eDP-1.pid")"
external_pid="$(<"$XDG_RUNTIME_DIR/awesome-blue-light/DP-1-1.pid")"
[[ "$(bash "$helper" refresh)" == ON ]]
[[ "$(wc -l < "$BLUE_LIGHT_TEST_LOG")" == 3 ]]
[[ "$(<"$XDG_RUNTIME_DIR/awesome-blue-light/eDP-1.pid")" == "$primary_pid" ]]
[[ "$(<"$XDG_RUNTIME_DIR/awesome-blue-light/DP-1-1.pid")" == "$external_pid" ]]
[[ "$(bash "$helper" toggle)" == OFF ]]
if kill -0 "$primary_pid" 2>/dev/null || kill -0 "$external_pid" 2>/dev/null; then
    printf 'Filter toggle left an owned Redshift worker alive\n' >&2
    exit 1
fi
grep -Fxq -- '-x -m randr:crtc=0' "$BLUE_LIGHT_TEST_LOG"
grep -Fxq -- '-x -m randr:crtc=4' "$BLUE_LIGHT_TEST_LOG"
grep -Fxq -- 'restore --output DP-1-1 --restore-color' "$BLUE_LIGHT_TEST_LOG"
[[ ! -e "$XDG_RUNTIME_DIR/awesome-blue-light/enabled" ]]
[[ "$(bash "$helper" refresh)" == OFF ]]
[[ ! -e "$XDG_RUNTIME_DIR/awesome-blue-light/eDP-1.pid" ]]
[[ ! -e "$XDG_RUNTIME_DIR/awesome-blue-light/DP-1-1.pid" ]]

printf 'blue-light output routing tests passed\n'
