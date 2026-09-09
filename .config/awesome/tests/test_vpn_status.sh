#!/usr/bin/env bash

set -euo pipefail

repo_home="${HOME}"
status_script="$repo_home/.config/awesome/utilities/prisma-vpn-status"
widget="$repo_home/.config/awesome/widget/vpn/init.lua"
panel="$repo_home/.config/awesome/layout/top-panel.lua"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cat > "$tmp_dir/systemctl" <<'EOF'
#!/usr/bin/env bash
[[ "${VPN_SERVICE_ACTIVE:-false}" == true ]]
EOF
cat > "$tmp_dir/agent-run" <<'EOF'
#!/usr/bin/env bash
[[ "${VPN_AGENT_FAIL:-false}" == false ]] || exit 1
[[ -z "${VPN_AGENT_SLEEP:-}" ]] || sleep "$VPN_AGENT_SLEEP"
printf 'Tunnel: %s\n' "${VPN_TUNNEL_STATUS:-Not Connected}"
EOF
chmod +x "$tmp_dir/systemctl" "$tmp_dir/agent-run"

run_status() {
    PRISMA_VPN_SYSTEMCTL_BIN="$tmp_dir/systemctl" \
        PRISMA_VPN_AGENT_RUN="$tmp_dir/agent-run" \
        "$status_script"
}

[[ "$(VPN_SERVICE_ACTIVE=false run_status)" == disconnected ]]
[[ "$(VPN_SERVICE_ACTIVE=true VPN_TUNNEL_STATUS=Connected run_status)" == connected ]]
[[ "$(VPN_SERVICE_ACTIVE=true VPN_TUNNEL_STATUS=Connecting run_status)" == connecting ]]
[[ "$(VPN_SERVICE_ACTIVE=true VPN_TUNNEL_STATUS='Not Connected' run_status)" == disconnected ]]
[[ "$(VPN_SERVICE_ACTIVE=true VPN_AGENT_FAIL=true run_status)" == unavailable ]]
[[ "$(VPN_SERVICE_ACTIVE=true VPN_AGENT_SLEEP=5 PRISMA_VPN_TIMEOUT_SECONDS=1 run_status)" == unavailable ]]

grep -Fq "awesome.emit_signal('module::vpn_status', status)" "$widget"
grep -Fq 'status_timer:again()' "$widget"
grep -Fq "widget/vpn/icons/prisma-access.svg" "$widget"
grep -Fq 'fill="#073642"' "$repo_home/.config/awesome/widget/vpn/icons/prisma-access.svg"
grep -Fq 'left = dpi(4)' "$widget"
grep -Fq 'right = 0' "$widget"
grep -Fq 'timeout = 120' "$widget"
grep -Fq 'single_shot = true' "$widget"
grep -Fq 's.vpn' "$panel"
grep -Fq "require('widget.vpn')()" "$panel"

printf 'vpn status tests passed\n'
