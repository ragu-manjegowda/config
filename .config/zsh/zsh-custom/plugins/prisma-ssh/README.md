# Prisma SSH routing

Hosts with `Tag prisma-vpn` in `~/.ssh/config` use `prisma-access ssh` through
the shared dispatcher. Untagged hosts, local addresses, and hosts with explicit
`ProxyCommand` or `ProxyJump` settings use ordinary SSH.

The Zsh plugin provides interactive `ssh` and `scp` hooks. Git uses the executable
`git-transport` through `core.sshCommand` in `~/.config/git/config`, so SSH-based
Git operations also work outside an interactive Zsh session.

Your existing host aliases, users, ports, and identities still come from SSH
configuration. Use normal Git commands with SSH remotes:

```sh
git clone user@tagged-host:project/repository.git
git fetch
git pull
git push
```

This also applies to SSH submodule operations. HTTPS remotes use Git's HTTP
transport and do not pass through this dispatcher. Explicit repository
`core.sshCommand` settings or `GIT_SSH_COMMAND` overrides take precedence over
the global transport. The wrapper uses Prisma's existing SSH connection and
authentication behavior. If a tagged host needs a connection, Git's dispatcher
first runs Prisma connection setup with its output directed to stderr, keeping
Git's protocol stream clean. An active host-wide VPN retains host-wide mode;
otherwise setup uses the isolated VPN. Gateway selection and authentication
remain interactive when needed, and a setup failure stops the Git request.

The transport files must be executable. Configuration changes apply to the
next Git invocation without reloading the shell.

## Checks

```sh
bash tests/test_prisma_ssh.sh
python tests/test_prisma_scp.py
python tests/test_prisma_git.py
```

The Git checks run real clone, fetch, pull, push, and submodule operations
against temporary local repositories through mock SSH/Prisma executables.
No network or VPN connection is required.
