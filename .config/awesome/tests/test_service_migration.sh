#!/usr/bin/env bash

set -euo pipefail

repo_home="${HOME}"
script="$repo_home/.config/scripts/bootstrap/05-services.sh"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

dispatcher="$test_root/10-ntpd"
log="$test_root/actions.log"
touch "$dispatcher"

log_step() { :; }
log_info() { :; }
log_ok() { :; }
enable_system_service() { printf 'enable-system %s\n' "$1" >> "$log"; }
enable_user_service() { printf 'enable-user %s\n' "$1" >> "$log"; }
systemctl() {
    case "${1-} ${2-}" in
        'get-default ') printf '%s\n' graphical.target ;;
        'is-enabled ntpd.service') return 0 ;;
        *) printf 'systemctl %s\n' "$*" >> "$log" ;;
    esac
}
sudo() {
    printf 'sudo %s\n' "$*" >> "$log"
    if [[ "${1-} ${2-} ${3-}" == 'systemctl restart systemd-resolved.service' ]]; then
        return "${RESOLVED_RESTART_STATUS:-0}"
    fi
    if [[ $1 == rm ]]; then shift; command rm "$@"; fi
}
getent() { printf 'greeter:x:1000:1000::/var/lib/greetd:/usr/bin/nologin\n'; }
systemd-tmpfiles() { :; }

NTPD_DISPATCHER_PATH="$dispatcher" source "$script"

grep -Fxq 'sudo systemctl disable ntpd.service' "$log"
grep -Fxq 'enable-system systemd-resolved' "$log"
grep -Fxq 'sudo systemctl restart systemd-resolved.service' "$log"
grep -Fxq 'enable-system systemd-timesyncd' "$log"
grep -Fxq 'systemctl --user reenable power-profile-monitor.service' "$log"
grep -Fxq 'systemctl --user start power-profile-monitor.service' "$log"
test ! -e "$dispatcher"
test ! -e "$repo_home/.config/misc/etc/NetworkManager/dispatcher.d/10-ntpd"

# Run in a separate errexit shell, matching the bootstrap orchestrator. A failed
# resolver activation must not be hidden by later successful service commands.
export log script
export -f log_step log_info log_ok enable_system_service enable_user_service
export -f systemctl sudo getent systemd-tmpfiles
if NTPD_DISPATCHER_PATH="$dispatcher" RESOLVED_RESTART_STATUS=1 \
        bash -euo pipefail -c 'source "$script"'; then
    printf 'bootstrap ignored failed systemd-resolved activation\n' >&2
    exit 1
fi

printf 'service migration tests passed\n'
