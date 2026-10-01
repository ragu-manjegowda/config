#!/usr/bin/env python3
"""Exercise real SCP argument forwarding without making network connections."""

import json
import os
import subprocess
import tempfile
from pathlib import Path

plugin = Path(__file__).resolve().parents[1] / "prisma-ssh.plugin.zsh"

with tempfile.TemporaryDirectory(prefix="prisma-scp-test-") as temporary:
    root = Path(temporary)
    binary = root / "bin"
    binary.mkdir()
    config = root / "ssh_config"
    config.write_text("""Host vpn-machine
    HostName 10.42.0.8
    Tag prisma-vpn
Host local-machine
    HostName 192.168.1.8
    Tag prisma-vpn
Host service.example.org
    HostName service.example.org
Host private-untagged
    HostName 10.42.0.9
Host proxied-machine
    HostName 10.42.0.10
    Tag prisma-vpn
    ProxyCommand custom-proxy
""", encoding="utf-8")
    log = root / "calls.jsonl"
    mock = """#!/usr/bin/python3
import json, os, subprocess, sys
args = sys.argv[1:]
name = os.path.basename(sys.argv[0])
if name == 'ssh' and args[:1] == ['-G']:
    command = ['/usr/bin/ssh', '-G', '-F', os.environ['SCP_TEST_CONFIG']]
    sys.exit(subprocess.run([*command, *args[1:]]).returncode)
with open(os.environ['SCP_TEST_LOG'], 'a', encoding='utf-8') as output:
    output.write(json.dumps([name, args]) + '\\n')
# Fail before SCP can attempt any protocol exchange or network connection.
sys.exit(1)
"""
    for name in ("ssh", "prisma-access", "custom-ssh"):
        executable = binary / name
        executable.write_text(mock, encoding="utf-8")
        executable.chmod(0o755)

    environment = os.environ.copy()
    environment.update(
        PATH=f"{binary}:{environment['PATH']}",
        SCP_TEST_CONFIG=str(config),
        SCP_TEST_LOG=str(log),
    )
    source = root / "source file.txt"
    source.write_text("generic fixture\n", encoding="utf-8")

    def run(*args):
        log.write_text("", encoding="utf-8")
        result = subprocess.run(
            ["zsh", "-f", "-c", 'source "$1"; shift; scp "$@"',
             "test", str(plugin), *map(str, args)],
            env=environment, capture_output=True, text=True, timeout=10,
            check=False,
        )
        calls = [json.loads(line)
                 for line in log.read_text(encoding="utf-8").splitlines()]
        return result, calls

    cases = [
        ([source, "vpn-machine:/remote/path"], "prisma-access"),
        (["vpn-machine:/remote/path", root / "download"], "prisma-access"),
        (["-O", source, "vpn-machine:/remote/path"], "prisma-access"),
        (["-r", "-p", source, source, "vpn-machine:/remote/path"], "prisma-access"),
        ([source, "local-machine:/remote/path"], "ssh"),
        ([source, "service.example.org:/remote/path"], "ssh"),
        ([source, "private-untagged:/remote/path"], "ssh"),
        ([source, "proxied-machine:/remote/path"], "ssh"),
        (["-o", "HostName=192.168.1.9", source, "vpn-machine:/remote/path"], "ssh"),
    ]
    for args, expected in cases:
        result, calls = run(*args)
        assert result.returncode != 0 and len(calls) == 1, (args, result, calls)
        assert calls[0][0] == expected, (args, calls)
        notice = "scp: running via prisma-access ssh" in result.stderr
        assert notice == (expected == "prisma-access")

    identity = root / "identity file"
    result, calls = run("-P", "2222", "-i", identity, "-F", config,
                        source, "user@vpn-machine:/remote/path")
    assert calls[0][0] == "prisma-access", (result, calls)
    forwarded = calls[0][1]
    options = (("-p", "2222"), ("-i", str(identity)),
               ("-F", str(config)), ("-l", "user"))
    for flag, value in options:
        assert forwarded[forwarded.index(flag) + 1] == value, forwarded

    result, calls = run("-S", binary / "custom-ssh", source, "vpn-machine:/remote/path")
    assert calls[0][0] == "custom-ssh" and "prisma-access" not in result.stderr

    destination = root / "local copy.txt"
    result, calls = run(source, destination)
    assert result.returncode == 0 and not calls, (result, calls)
    assert destination.read_bytes() == source.read_bytes()

print("Prisma SCP dispatch and argument forwarding tests passed")
