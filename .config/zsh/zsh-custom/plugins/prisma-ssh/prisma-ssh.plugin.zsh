# Route only explicitly tagged hosts through Prisma Access. A tag is needed
# because a non-LAN address alone cannot distinguish VPN-only machines and
# Git services from public SSH services.
ssh() {
    emulate -L zsh

    local arg config line host='' tag='' proxy='' jump=''
    for arg in "$@"; do
        case "$arg" in
            (-G|-V|-Q|-O)
                command ssh "$@"
                return
                ;;
        esac
    done

    config=$(command ssh -G "$@" 2>/dev/null) || {
        command ssh "$@"
        return
    }

    for line in ${(f)config}; do
        case "$line" in
            (hostname\ *) host=${line#hostname } ;;
            (tag\ *) tag=${line#tag } ;;
            (proxycommand\ *) proxy=${line#proxycommand } ;;
            (proxyjump\ *) jump=${line#proxyjump } ;;
        esac
    done

    if [[ "$tag" == prisma-vpn && -n "$host" &&
          "$host" != 192.168.* && "$host" != 127.* &&
          "$host" != 169.254.* && "$host" != localhost && "$host" != ::1 &&
          ( -z "$proxy" || "$proxy" == none ) &&
          ( -z "$jump" || "$jump" == none ) ]]; then
        print -u2 -r -- "${PRISMA_SSH_CALLER:-ssh}: running via prisma-access ssh for $host"
        if [[ "${PRISMA_SSH_CALLER:-ssh}" == git ]]; then
            # Git reserves stdout for its protocol. Connect before starting SSH
            # so Prisma's gateway/authentication/status output goes to stderr.
            local service='' candidate
            local -a connect_options=()
            for candidate in prisma-access-agent-host.service prisma-access-agent.service; do
                if command systemctl is-active --quiet "$candidate"; then
                    service="$candidate"
                    break
                fi
            done
            if [[ "$service" == prisma-access-agent-host.service ]]; then
                connect_options=(--global)
            fi
            if [[ -z "$service" ]] ||
               ! command prisma-access status --relative 2>/dev/null |
                   command grep -qE '^Tunnel:[[:space:]]+Connected'; then
                command prisma-access connect "${connect_options[@]}" >&2 || return $?
            fi
        fi
        command prisma-access ssh "$@"
    else
        command ssh "$@"
    fi
}

# SCP forwards its SSH arguments to this helper, so aliases, ports, identity
# files, and per-host routing use the same dispatcher as interactive SSH.
# A later explicit -S supplied by the user takes precedence over this default.
scp() {
    emulate -L zsh
    command scp -S "${functions_source[scp]:A:h}/scp-transport" "$@"
}

if (( $+functions[compdef] )); then
    compdef _ssh ssh
    compdef _ssh scp
fi
