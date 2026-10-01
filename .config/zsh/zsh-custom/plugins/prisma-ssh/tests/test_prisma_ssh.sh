#!/usr/bin/env bash
set -euo pipefail

plugin="$(dirname "$(dirname "$(realpath "$0")")")/prisma-ssh.plugin.zsh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "$tmp_dir"' EXIT
mkdir "$tmp_dir/bin"

cat > "$tmp_dir/ssh_config" <<'EOF'
Host vpn-machine
    HostName 10.42.0.8
    Tag prisma-vpn
Host local-machine
    HostName 192.168.1.8
    Tag prisma-vpn
Host private-untagged
    HostName 10.42.0.9
Host service.example.org
    HostName service.example.org
Host proxied-machine
    HostName 10.42.0.10
    Tag prisma-vpn
    ProxyCommand nc proxy.example.org 22
Host jump-machine
    HostName 10.42.0.11
    Tag prisma-vpn
    ProxyJump jump.example.org
EOF

cat > "$tmp_dir/bin/ssh" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == -G ]]; then
    shift
    exec /usr/bin/ssh -G -F "$SSH_TEST_CONFIG" "$@"
fi
{
    printf 'ssh'
    printf ' <%s>' "$@"
    printf '\n'
} >> "$SSH_TEST_LOG"
EOF
cat > "$tmp_dir/bin/prisma-access" <<'EOF'
#!/usr/bin/env bash
{
    printf 'prisma-access'
    printf ' <%s>' "$@"
    printf '\n'
} >> "$SSH_TEST_LOG"
EOF
chmod +x "$tmp_dir/bin/ssh" "$tmp_dir/bin/prisma-access"

SSH_TEST_PLUGIN="$plugin" SSH_TEST_CONFIG="$tmp_dir/ssh_config" \
SSH_TEST_LOG="$tmp_dir/calls" PATH="$tmp_dir/bin:$PATH" \
zsh -f -c '
    compdef() { :; }
    source "$SSH_TEST_PLUGIN"
    ssh vpn-machine "uname -s"
    ssh -A vpn-machine true
    ssh local-machine
    ssh -o HostName=192.168.1.9 vpn-machine
    ssh service.example.org
    ssh private-untagged
    ssh proxied-machine
    ssh jump-machine
    ssh -o ProxyCommand=proxy.example.org vpn-machine
    ssh -V
    ssh -G vpn-machine >/dev/null 2>&1
' 2> "$tmp_dir/notices"

mapfile -t calls < "$tmp_dir/calls"
[[ ${#calls[@]} -eq 10 ]]
[[ "${calls[0]}" == 'prisma-access <ssh> <vpn-machine> <uname -s>' ]]
[[ "${calls[1]}" == 'prisma-access <ssh> <-A> <vpn-machine> <true>' ]]
[[ "${calls[2]}" == 'ssh <local-machine>' ]]
[[ "${calls[3]}" == 'ssh <-o> <HostName=192.168.1.9> <vpn-machine>' ]]
[[ "${calls[4]}" == 'ssh <service.example.org>' ]]
[[ "${calls[5]}" == 'ssh <private-untagged>' ]]
[[ "${calls[6]}" == 'ssh <proxied-machine>' ]]
[[ "${calls[7]}" == 'ssh <jump-machine>' ]]
[[ "${calls[8]}" == 'ssh <-o> <ProxyCommand=proxy.example.org> <vpn-machine>' ]]
[[ "${calls[9]}" == 'ssh <-V>' ]]
if [[ "$(wc -l < "$tmp_dir/notices")" -ne 2 ]]; then
    printf 'Expected two VPN notices; got:\n' >&2
    while IFS= read -r line; do printf '%s\n' "$line" >&2; done < "$tmp_dir/notices"
    exit 1
fi
grep -Fxq 'ssh: running via prisma-access ssh for 10.42.0.8' "$tmp_dir/notices"

# Zsh ships one shared completer for both SSH and SCP, not a separate _scp.
SSH_TEST_PLUGIN="$plugin" zsh -f -c '
    autoload -Uz compinit
    compinit -D
    source "$SSH_TEST_PLUGIN"
    [[ "${_comps[ssh]}" == _ssh && "${_comps[scp]}" == _ssh ]] || exit 1
    autoload +X _ssh
    (( $+functions[_ssh] )) || exit 1
'

printf 'Prisma SSH dispatch tests passed\n'
