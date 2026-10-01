# Route only explicitly tagged machine hosts through Prisma Access. A tag is
# needed because a non-LAN address alone cannot distinguish machines from
# public SSH services such as Git hosts.
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
