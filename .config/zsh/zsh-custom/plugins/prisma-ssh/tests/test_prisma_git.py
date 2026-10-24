#!/usr/bin/env python3
"""Exercise real Git SSH operations through the dispatcher without networking."""

import json
import os
import shlex
import subprocess
import tempfile
from pathlib import Path

PLUGIN = Path(__file__).resolve().parents[1]
GIT_CONFIG = PLUGIN.parents[3] / "git/config"

MOCK = r"""#!/usr/bin/python3
import json, os, shlex, subprocess, sys
name = os.path.basename(sys.argv[0])
args = sys.argv[1:]
state = os.environ['PRISMA_GIT_TEST_STATE']
if name == 'systemctl':
    try:
        mode = open(state).read().strip()
    except FileNotFoundError:
        mode = ''
    service = 'prisma-access-agent-host.service' if mode.startswith('global') else 'prisma-access-agent.service'
    sys.exit(0 if mode and args[-1] == service else 1)
if name == 'prisma-access' and args[:1] in (['status'], ['connect']):
    with open(os.environ['PRISMA_GIT_TEST_LIFECYCLE'], 'a') as output:
        output.write(json.dumps(args) + '\n')
    if args[0] == 'status':
        try:
            connected = open(state).read().strip().endswith('connected')
        except FileNotFoundError:
            connected = False
        print('Tunnel: Connected' if connected else 'Tunnel: Disconnected')
        sys.exit(0)
    print('VPN connection setup output must not enter the Git protocol stream')
    if os.environ.get('PRISMA_GIT_TEST_CONNECT_FAIL'):
        sys.exit(int(os.environ['PRISMA_GIT_TEST_CONNECT_FAIL']))
    with open(state, 'w') as output:
        output.write('global-connected' if '--global' in args else 'connected')
    sys.exit(0)
if name == 'ssh' and args[:1] == ['-G']:
    sys.exit(subprocess.call(['/usr/bin/ssh', '-G', '-F',
                             os.environ['PRISMA_GIT_TEST_CONFIG'], *args[1:]]))
with open(os.environ['PRISMA_GIT_TEST_LOG'], 'a') as output:
    output.write(json.dumps([name, args]) + '\n')
if os.environ.get('PRISMA_GIT_TEST_FAIL'):
    sys.exit(int(os.environ['PRISMA_GIT_TEST_FAIL']))
command = shlex.split(args[-1])
if len(command) != 2 or command[0] not in ('git-upload-pack', 'git-receive-pack'):
    sys.exit('Unexpected SSH command; networking is disabled in this fixture')
sys.exit(subprocess.call(command))
"""


def main():
    with tempfile.TemporaryDirectory(prefix="prisma git test ") as temporary:
        root = Path(temporary)
        home = root / "home with spaces"
        plugin_link = home / ".config/zsh/zsh-custom/plugins/prisma-ssh"
        plugin_link.parent.mkdir(parents=True)
        plugin_link.symlink_to(PLUGIN, target_is_directory=True)
        binary = root / "bin"
        binary.mkdir()
        for name in ("ssh", "prisma-access", "custom-ssh", "systemctl"):
            executable = binary / name
            executable.write_text(MOCK)
            executable.chmod(0o755)
        config = root / "ssh_config"
        config.write_text("""Host vpn-git
    HostName git.internal.example
    Tag prisma-vpn
    User developer
    Port 12013
Host local-git
    HostName 192.168.1.8
    Tag prisma-vpn
Host private-untagged
    HostName 10.42.0.9
Host public-git
    HostName git.public.example
Host proxied-git
    HostName 10.42.0.10
    Tag prisma-vpn
    ProxyCommand custom-proxy
Host jump-git
    HostName 10.42.0.11
    Tag prisma-vpn
    ProxyJump jump.example
""")
        log = root / "calls.jsonl"
        lifecycle = root / "lifecycle.jsonl"
        state = root / "vpn-state"
        state.write_text("connected")
        global_config = root / "gitconfig"
        env = os.environ | {
            "HOME": str(home),
            "XDG_CONFIG_HOME": str(home / ".config"),
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": str(global_config),
            "GIT_TERMINAL_PROMPT": "0",
            "PATH": f"{binary}:{os.environ['PATH']}",
            "PRISMA_GIT_TEST_CONFIG": str(config),
            "PRISMA_GIT_TEST_LOG": str(log),
            "PRISMA_GIT_TEST_LIFECYCLE": str(lifecycle),
            "PRISMA_GIT_TEST_STATE": str(state),
        }
        for name in ("GIT_SSH", "GIT_SSH_COMMAND", "GIT_SSH_VARIANT", "GIT_DIR",
                     "GIT_WORK_TREE", "GIT_CONFIG", "GIT_CONFIG_COUNT"):
            env.pop(name, None)

        def git(*args, cwd=root, extra=None, check=True):
            return subprocess.run(
                ["/usr/bin/git", *map(str, args)], cwd=cwd, env=env | (extra or {}),
                capture_output=True, text=True, timeout=20, check=check,
            )

        ssh_command = git("config", "--file", GIT_CONFIG,
                          "--get", "core.sshCommand").stdout.strip()
        git("config", "--file", global_config, "core.sshCommand", ssh_command)
        git("config", "--file", global_config, "user.name", "Fixture User")
        git("config", "--file", global_config, "user.email", "fixture@example.org")
        git("config", "--file", global_config, "commit.gpgSign", "false")
        seed = root / "seed"
        git("init", "-q", seed)
        (seed / "fixture.txt").write_text("first\n")
        git("add", "fixture.txt", cwd=seed)
        git("commit", "-qm", "Fixture initial commit", cwd=seed)
        server = root / "server repository.git"
        git("clone", "-q", "--bare", seed, server)

        def calls():
            return [json.loads(line) for line in log.read_text().splitlines()]

        def reset():
            log.write_text("")
            lifecycle.write_text("")

        for host, expected in (
            ("vpn-git", "prisma-access"), ("local-git", "ssh"),
            ("private-untagged", "ssh"), ("public-git", "ssh"),
            ("proxied-git", "ssh"), ("jump-git", "ssh"),
        ):
            reset()
            result = git("ls-remote", f"{host}:{server}")
            assert "HEAD" in result.stdout, result
            assert [name for name, _ in calls()] == [expected], calls()
            assert ("git: running via prisma-access ssh" in result.stderr) == (
                expected == "prisma-access"
            ), result.stderr
            if expected != "prisma-access":
                assert lifecycle.read_text() == "", lifecycle.read_text()

        for mode, options in ((None, []), ("starting", []),
                              ("global-starting", ["--global"])):
            reset()
            if mode is None:
                state.unlink(missing_ok=True)
            else:
                state.write_text(mode)
            result = git("ls-remote", f"vpn-git:{server}")
            assert "HEAD" in result.stdout, result
            assert "VPN connection setup output" not in result.stdout, result
            assert "VPN connection setup output" in result.stderr, result
            events = [json.loads(line) for line in lifecycle.read_text().splitlines()]
            assert ["connect", *options] in events, events
            assert [name for name, _ in calls()] == ["prisma-access"], calls()

        reset()
        state.unlink()
        result = git("ls-remote", f"vpn-git:{server}",
                     extra={"PRISMA_GIT_TEST_CONNECT_FAIL": "17"}, check=False)
        assert result.returncode != 0 and not calls(), (result, calls())
        assert "VPN connection setup output" not in result.stdout, result
        state.write_text("connected")

        reset()
        git("ls-remote", f"ssh://developer@vpn-git:2222{server}")
        forwarded = calls()[0][1]
        assert calls()[0][0] == "prisma-access", calls()
        assert forwarded[0] == "ssh" and "developer@vpn-git" in forwarded, calls()
        assert forwarded[forwarded.index("-p") + 1] == "2222", calls()
        assert shlex.split(forwarded[-1]) == ["git-upload-pack", str(server)], calls()

        client = root / "client"
        reset()
        git("clone", "-q", f"vpn-git:{server}", client)
        assert [name for name, _ in calls()] == ["prisma-access"], calls()
        (seed / "fixture.txt").write_text("first\nsecond\n")
        git("commit", "-qam", "Fixture upstream update", cwd=seed)
        git("push", "-q", server, "HEAD", cwd=seed)
        for operation in (("fetch",), ("pull", "--ff-only")):
            reset()
            git(*operation, cwd=client)
            assert [name for name, _ in calls()] == ["prisma-access"], calls()
        assert (client / "fixture.txt").read_text() == "first\nsecond\n"
        (client / "client.txt").write_text("pushed through the tagged transport\n")
        git("add", "client.txt", cwd=client)
        git("commit", "-qm", "Fixture client update", cwd=client)
        reset()
        git("push", cwd=client)
        assert [name for name, _ in calls()] == ["prisma-access"], calls()
        assert git("rev-parse", "HEAD", cwd=client).stdout == git(
            "--git-dir", server, "rev-parse", "HEAD"
        ).stdout

        reset()
        git("submodule", "add", f"vpn-git:{server}", "nested", cwd=client)
        assert calls() and all(name == "prisma-access" for name, _ in calls()), calls()

        custom = shlex.quote(str(binary / "custom-ssh"))
        for args, extra in (
            (("ls-remote", f"vpn-git:{server}"), {"GIT_SSH_COMMAND": custom}),
            (("-c", f"core.sshCommand={custom}", "ls-remote", f"vpn-git:{server}"), {}),
        ):
            reset()
            git(*args, extra=extra)
            assert calls() and all(name == "custom-ssh" for name, _ in calls()), calls()

        reset()
        result = git("ls-remote", f"vpn-git:{server}",
                     extra={"PRISMA_GIT_TEST_FAIL": "71"}, check=False)
        assert result.returncode != 0, result
        assert [name for name, _ in calls()] == ["prisma-access"], calls()

    print("Prisma Git routing, clone/fetch/pull/push, submodule and override checks passed")


if __name__ == "__main__":
    main()
