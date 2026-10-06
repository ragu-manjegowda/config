#!/usr/bin/env python3
"""Exercise the real on-demand helper through fake commands, without X11/network/systemd."""

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

HELPER = Path(os.environ["HOME"]) / ".local/bin/vnc-server"

FAKE = r"""#!/usr/bin/env python3
import json, os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
root = pathlib.Path(os.environ['VNC_TEST_ROOT'])
args = sys.argv[1:]
with (root / 'calls.jsonl').open('a') as output:
    output.write(json.dumps([name, args]) + '\n')
if name == 'id':
    print('1000' if '-u' in args else 'test-user')
elif name == 'hostnamectl':
    print('test-host')
elif name == 'systemctl':
    if 'is-active' in args:
        sys.exit(0 if (root / 'active').exists() else 3)
    if 'stop' in args:
        (root / 'active').unlink(missing_ok=True)
elif name == 'systemd-run':
    if '--unit=vnc-server' in args and not os.environ.get('VNC_TEST_START_FAIL'):
        (root / 'active').touch()
elif name == 'timeout':
    sys.exit(int(os.environ.get('VNC_TEST_DISPLAY_FAIL', '0')))
"""


class HelperTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for command in (
            "id",
            "hostnamectl",
            "systemctl",
            "systemd-run",
            "x0vncserver",
            "xset",
            "timeout",
            "avahi-publish-service",
            "journalctl",
        ):
            path = self.bin / command
            path.write_text(FAKE)
            path.chmod(0o755)
        (self.root / ".Xauthority").touch()
        self.env = os.environ | {
            "HOME": str(self.root),
            "XAUTHORITY": str(self.root / ".Xauthority"),
            "DISPLAY": ":42",
            "VNC_TEST_ROOT": str(self.root),
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
        }

    def run_helper(self, action, **extra):
        return subprocess.run(
            ["/usr/bin/bash", str(HELPER), action],
            env=self.env | extra,
            text=True,
            capture_output=True,
            timeout=5,
            check=False,
        )

    def calls(self):
        return [
            json.loads(line)
            for line in (self.root / "calls.jsonl").read_text().splitlines()
        ]

    def test_start_uses_tls_and_system_auth_without_enable_or_password_file(
        self,
    ):
        result = self.run_helper("start")
        self.assertEqual(result.returncode, 0, result.stderr)
        launches = [args for name, args in self.calls() if name == "systemd-run"]
        self.assertEqual(len(launches), 2)
        server = launches[0]
        for option in (
            "--user",
            "--collect",
            "-rfbport=5900",
            "-UseIPv6=0",
            "-SecurityTypes=TLSPlain",
            "-PlainUsers=test-user",
            "-PAMService=system-auth",
        ):
            self.assertIn(option, server)
        self.assertIn("--property=BindsTo=vnc-server.service", launches[1])
        self.assertFalse(
            any("enable" in args for name, args in self.calls() if name == "systemctl")
        )
        self.assertFalse(
            any("PasswordFile" in arg or "Password=" in arg for arg in server)
        )
        self.assertIn("test-host.local:5900", result.stdout)

    def test_start_is_idempotent(self):
        (self.root / "active").touch()
        self.assertEqual(self.run_helper("start").returncode, 0)
        self.assertFalse(any(name == "systemd-run" for name, _ in self.calls()))

    def test_stop_and_status(self):
        (self.root / "active").touch()
        self.assertIn("running", self.run_helper("status").stdout)
        self.assertEqual(self.run_helper("stop").returncode, 0)
        self.assertFalse((self.root / "active").exists())
        self.assertIn("stopped", self.run_helper("status").stdout)
        self.assertEqual(self.run_helper("stop").returncode, 0)

    def test_missing_xauthority_prevents_launch(self):
        (self.root / ".Xauthority").unlink()
        self.assertNotEqual(self.run_helper("start").returncode, 0)
        self.assertFalse(any(name == "systemd-run" for name, _ in self.calls()))

    def test_inaccessible_display_prevents_launch(self):
        self.assertNotEqual(
            self.run_helper("start", VNC_TEST_DISPLAY_FAIL="1").returncode, 0
        )
        self.assertFalse(any(name == "systemd-run" for name, _ in self.calls()))

    def test_failed_server_start_is_reported(self):
        self.assertNotEqual(
            self.run_helper("start", VNC_TEST_START_FAIL="1").returncode, 0
        )
        self.assertTrue(any(name == "journalctl" for name, _ in self.calls()))
        self.assertFalse(
            any("--unit=vnc-server-discovery" in args for _, args in self.calls())
        )


if __name__ == "__main__":
    unittest.main()
