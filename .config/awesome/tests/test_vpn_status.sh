#!/usr/bin/env bash

set -euo pipefail

repo_home="${HOME}"
status_script="$repo_home/.config/awesome/utilities/prisma-vpn-status"
health_script="$repo_home/.config/awesome/utilities/prisma-vpn-health"
diagnostics_script="$repo_home/.config/awesome/utilities/prisma-vpn-diagnostics"
widget="$repo_home/.config/awesome/widget/vpn/init.lua"
panel="$repo_home/.config/awesome/layout/top-panel.lua"
gai_config="$repo_home/.config/misc/etc/gai.conf"
system_bootstrap="$repo_home/.config/scripts/bootstrap/03-system.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cat > "$tmp_dir/systemctl" <<'EOF'
#!/usr/bin/env bash
case "${3:-}" in
    prisma-access-agent.service) [[ "${VPN_NAMESPACE_ACTIVE:-false}" == true ]] ;;
    prisma-access-agent-host.service) [[ "${VPN_GLOBAL_ACTIVE:-false}" == true ]] ;;
    *) exit 1 ;;
esac
EOF
cat > "$tmp_dir/agent-run" <<'EOF'
#!/usr/bin/env bash
[[ "${VPN_AGENT_FAIL:-false}" == false ]] || exit 1
[[ -z "${VPN_AGENT_SLEEP:-}" ]] || sleep "$VPN_AGENT_SLEEP"
printf 'Tunnel: %s\n' "${VPN_TUNNEL_STATUS:-Not Connected}"
EOF
cat > "$tmp_dir/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$PRISMA_VPN_CURL_ARGS"
[[ "${VPN_HEALTH_FAIL:-false}" == false ]]
EOF
chmod +x "$tmp_dir/systemctl" "$tmp_dir/agent-run" "$tmp_dir/curl"

run_status() {
    PRISMA_VPN_SYSTEMCTL_BIN="$tmp_dir/systemctl" \
        PRISMA_VPN_AGENT_RUN="$tmp_dir/agent-run" \
        "$status_script"
}

[[ "$(run_status)" == disconnected ]]
[[ "$(VPN_NAMESPACE_ACTIVE=true VPN_TUNNEL_STATUS=Connected run_status)" == 'connected namespace' ]]
[[ "$(VPN_GLOBAL_ACTIVE=true VPN_TUNNEL_STATUS=Connected run_status)" == 'connected global' ]]
[[ "$(VPN_GLOBAL_ACTIVE=true VPN_NAMESPACE_ACTIVE=true VPN_TUNNEL_STATUS=Connected run_status)" == 'connected global' ]]
[[ "$(VPN_NAMESPACE_ACTIVE=true VPN_TUNNEL_STATUS=Connecting run_status)" == 'connecting namespace' ]]
[[ "$(VPN_GLOBAL_ACTIVE=true VPN_TUNNEL_STATUS=Connecting run_status)" == 'connecting global' ]]
[[ "$(VPN_NAMESPACE_ACTIVE=true VPN_TUNNEL_STATUS='Not Connected' run_status)" == 'disconnected namespace' ]]
[[ "$(VPN_GLOBAL_ACTIVE=true VPN_TUNNEL_STATUS='Not Connected' run_status)" == 'disconnected global' ]]
[[ "$(VPN_NAMESPACE_ACTIVE=true VPN_AGENT_FAIL=true run_status)" == 'unavailable namespace' ]]
[[ "$(VPN_GLOBAL_ACTIVE=true VPN_AGENT_SLEEP=5 PRISMA_VPN_TIMEOUT_SECONDS=1 run_status)" == 'unavailable global' ]]

PRISMA_VPN_CURL_ARGS="$tmp_dir/curl-args" \
    PRISMA_VPN_CURL_BIN="$tmp_dir/curl" "$health_script"
grep -Fq -- '--ipv4 --fail --head --silent --show-error --connect-timeout 5 --max-time 5 https://outlook.office.com/' \
    "$tmp_dir/curl-args"
if PRISMA_VPN_CURL_ARGS="$tmp_dir/curl-args" PRISMA_VPN_CURL_BIN="$tmp_dir/curl" \
    VPN_HEALTH_FAIL=true "$health_script"; then
    printf '%s\n' 'VPN health probe must fail when curl fails' >&2
    exit 1
fi

grep -Fq "awesome.emit_signal('module::vpn_status', status, mode)" "$widget"
grep -Fq 'status_timer:again()' "$widget"
grep -Fq "widget/vpn/icons/prisma-access.svg" "$widget"
grep -Fq "widget/vpn/icons/prisma-access-connecting.svg" "$widget"
grep -Fq "widget/vpn/icons/prisma-access-unhealthy.svg" "$widget"
grep -Fq "widget/vpn/icons/prisma-access-namespace.svg" "$widget"
grep -Fq "widget/vpn/icons/prisma-access-namespace-connecting.svg" "$widget"
grep -Fq 'stroke="#dc322f"' "$repo_home/.config/awesome/widget/vpn/icons/prisma-access-unhealthy.svg"
for connecting_icon in "$repo_home/.config/awesome/widget/vpn/icons/prisma-access-connecting.svg" \
    "$repo_home/.config/awesome/widget/vpn/icons/prisma-access-namespace-connecting.svg"; do
    if grep -Fq 'fill="#eee8d5" d="M40 0' "$connecting_icon"; then
        grep -Fq 'fill="#eee8d5" fill-rule="evenodd"' "$connecting_icon"
    else
        grep -Fq 'fill="#073642" d="M40 0' "$connecting_icon"
        grep -Fq 'fill="#073642" fill-rule="evenodd"' "$connecting_icon"
    fi
    if grep -Eq '<circle|stroke=|#b58900' "$connecting_icon"; then
        printf 'VPN connecting icon must use a theme-colored circle with a transparent cutout: %s\n' \
            "$connecting_icon" >&2
        exit 1
    fi
done
for scoped_icon in "$repo_home/.config/awesome/widget/vpn/icons/prisma-access-namespace.svg" \
    "$repo_home/.config/awesome/widget/vpn/icons/prisma-access-connecting.svg" \
    "$repo_home/.config/awesome/widget/vpn/icons/prisma-access-namespace-connecting.svg"; do
    if grep -Fq 'fill="#eee8d5" d="M40 0' "$scoped_icon"; then
        if [[ "$scoped_icon" == *namespace* ]]; then
            grep -Fq 'fill="#eee8d5" d="M45 57' "$scoped_icon"
        fi
    elif grep -Fq 'fill="#073642" d="M40 0' "$scoped_icon"; then
        if [[ "$scoped_icon" == *namespace* ]]; then
            grep -Fq 'fill="#073642" d="M45 57' "$scoped_icon"
        fi
    else
        printf 'VPN icon has no recognized glyph color: %s\n' "$scoped_icon" >&2
        exit 1
    fi
    if grep -Eq '<rect|stroke=|#(002b36|2aa198|b58900)' "$scoped_icon"; then
        printf 'VPN icon contains a stale badge or color: %s\n' "$scoped_icon" >&2
        exit 1
    fi
done
grep -Eq 'fill="#(073642|eee8d5)"' "$repo_home/.config/awesome/widget/vpn/icons/prisma-access.svg"
grep -Fq 'left = dpi(4)' "$widget"
grep -Fq 'right = 0' "$widget"
if grep -Fq 'hide_timer' "$widget"; then
    printf '%s\n' 'VPN widget must hide immediately after disconnect' >&2
    exit 1
fi
grep -Fq "'systemctl', '--user', 'try-restart', 'goimapnotify.service'" "$widget"
grep -Fq 'mail_restart_timer:again()' "$widget"
grep -Fq 'local health_interval_seconds = 60' "$widget"
grep -Fq 'local health_failure_threshold = 3' "$widget"
grep -Fq "awesome.emit_signal('module::vpn_health', health)" "$widget"
grep -Fq "title = 'VPN connectivity lost'" "$widget"
grep -Fq "mode == 'namespace' and namespace_icon" "$widget"
grep -Fq "status == 'connected' and mode == 'global'" "$widget"
grep -Fq 'prisma-vpn-health' "$widget"
grep -Fq 'prisma-vpn-diagnostics' "$widget"
grep -Fq 'umask 077' "$diagnostics_script"
grep -Fq 's.vpn' "$panel"
grep -Fq "require('widget.vpn')()" "$panel"
grep -Eq '^precedence[[:space:]]+::ffff:0:0/96[[:space:]]+100$' "$gai_config"
grep -Fq 'etc/gai.conf' "$system_bootstrap"

printf 'vpn status tests passed\n'
