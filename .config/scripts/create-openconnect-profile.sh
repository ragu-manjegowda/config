#!/usr/bin/env bash

set -euo pipefail

profile_name="Openconnect GP"
gateway="nvidia.gpcloudservice.com"
hip_wrapper="/usr/lib/openconnect/hipreport.sh"

usage() {
    cat <<'EOF'
Usage: create-openconnect-profile.sh [options]

Create or update a NetworkManager GlobalProtect/OpenConnect profile.

Options:
  --name NAME          Profile name (default: Openconnect GP)
  --gateway HOST       GlobalProtect portal (default: nvidia.gpcloudservice.com)
  --hip-wrapper PATH   HIP report script (default: /usr/lib/openconnect/hipreport.sh)
  -h, --help           Show this help
EOF
}

while (( $# )); do
    case "$1" in
        --name)
            profile_name="${2:?--name requires a value}"
            shift 2
            ;;
        --gateway)
            gateway="${2:?--gateway requires a value}"
            shift 2
            ;;
        --hip-wrapper)
            hip_wrapper="${2:?--hip-wrapper requires a value}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if ! command -v nmcli >/dev/null 2>&1; then
    printf 'nmcli is required; install NetworkManager first.\n' >&2
    exit 1
fi

if [[ ! -x "$hip_wrapper" ]]; then
    printf 'HIP wrapper is not executable: %s\n' "$hip_wrapper" >&2
    exit 1
fi

vpn_data="authtype=password,protocol=gp,gateway=$gateway"
vpn_data+=",csd_wrapper=$hip_wrapper,enable_csd_trojan=yes"
vpn_data+=",disable_udp=no,prevent_invalid_cert=no,stoken_source=disabled"
vpn_data+=",cookie-flags=2,gateway-flags=2,gwcert-flags=2,resolve-flags=2"

if nmcli -g connection.id connection show "$profile_name" >/dev/null 2>&1; then
    nmcli connection modify "$profile_name" vpn.data "$vpn_data"
    action="Updated"
else
    nmcli connection add type vpn vpn-type openconnect \
        con-name "$profile_name" vpn.data "$vpn_data"
    action="Created"
fi

printf '%s NetworkManager profile %q for %s.\n' \
    "$action" "$profile_name" "$gateway"
