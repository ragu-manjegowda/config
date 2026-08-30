#!/usr/bin/env bash

set -euo pipefail

repo_home="${HOME}"
service="$repo_home/.config/misc/etc/systemd/system/awesome-lock-before-sleep.service"
helper="$repo_home/.config/scripts/lock-before-sleep.sh"
bootstrap="$repo_home/.config/scripts/bootstrap/04-hardware.sh"
system_bootstrap="$repo_home/.config/scripts/bootstrap/03-system.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

grep -Fq -- 'Before=systemd-suspend.service' "$service"
grep -Fq -- 'RequiredBy=systemd-suspend.service' "$service"
grep -Fq -- 'User=ragu' "$service"
grep -Fq -- 'ExecStart=/home/ragu/.config/scripts/lock-before-sleep.sh' "$service"
grep -Fq -- 'enable_system_service awesome-lock-before-sleep.service' "$bootstrap"
grep -Fq -- 'lockscreen.visible' "$helper"
grep -Fq -- 'awful.keygrabber.current_instance ~= nil' "$helper"
test "$(grep -c 'print "auth .*pam_fprintd' "$system_bootstrap")" -eq 2
grep -Fq 'Unsupported greetd PAM structure' "$system_bootstrap"
grep -Fq 'pam_fprintd.so"' "$system_bootstrap"
grep -Fq 'pam_fprintd.so max-tries=3 timeout=10' "$system_bootstrap"

cat > "$tmp_dir/pgrep" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$tmp_dir/awesome-client" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == *'module::lockscreen_show'* ]]; then
    printf 'lock requested\n' >> "$LOCK_TEST_LOG"
elif [[ "$1" == *'module::fingerprint_stop'* ]]; then
    printf 'fingerprint stopped\n' >> "$LOCK_TEST_LOG"
else
    printf '   string "ready"\n'
fi
EOF
chmod +x "$tmp_dir/pgrep" "$tmp_dir/awesome-client"

LOCK_TEST_LOG="$tmp_dir/log" PATH="$tmp_dir:/usr/bin" bash "$helper"
grep -Fxq 'lock requested' "$tmp_dir/log"
grep -Fxq 'fingerprint stopped' "$tmp_dir/log"

printf 'lock-before-sleep tests passed\n'
