#!/usr/bin/env python3
"""Check the user-owned Awesome session without starting a desktop."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

CHECK = Path(__file__).resolve().parents[2] / "check-awesome-session.sh"
LAUNCHER = Path(__file__).resolve().parents[3] / "misc/usr/local/libexec/awesome-session"


class DesktopSessionTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)
        self.source = self.home / ".config/misc/usr/local/libexec/awesome-session"
        self.launcher = self.home / ".local/bin/awesome-session"
        self.session = self.home / ".local/share/xsessions/awesome.desktop"
        self.configuration = self.home / ".config/awesome/rc.lua"
        self.awesome = self.home / ".local/bin/awesome"
        for destination in (self.source, self.launcher, self.session, self.configuration):
            destination.parent.mkdir(parents=True, exist_ok=True)
        self.source.write_text("#!/usr/bin/env bash\nexit 0\n")
        self.source.chmod(0o755)
        self.launcher.symlink_to("../../.config/misc/usr/local/libexec/awesome-session")
        self.session.write_text(
            f"[Desktop Entry]\nExec={self.launcher}\nTryExec={self.launcher}\n"
        )
        self.configuration.touch()
        self.awesome.write_text('#!/bin/bash\n[[ "$1" == -k && "$2" == -c && -f "$3" ]]\n')
        self.awesome.chmod(0o755)
        self.environment = dict(os.environ, HOME=str(self.home),
                                PATH=f"{self.awesome.parent}:/usr/bin:/bin")

    def check(self):
        return subprocess.run(["/bin/bash", str(CHECK)], env=self.environment,
                              text=True, capture_output=True)

    def assert_failure(self, message):
        result = self.check()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(message, result.stderr)

    def test_valid_session(self):
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_missing_launcher(self):
        self.launcher.unlink()
        self.assert_failure("launcher is missing")

    def test_nonexecutable_source(self):
        self.source.chmod(0o644)
        self.assert_failure("not executable")

    def test_stale_launcher_copy(self):
        self.launcher.unlink()
        self.launcher.write_text(self.source.read_text())
        self.launcher.chmod(0o755)
        self.assert_failure("does not link to the maintained copy")

    def test_wrong_session_paths(self):
        for key in ("Exec", "TryExec"):
            with self.subTest(key=key):
                self.session.write_text(
                    f"[Desktop Entry]\nExec={self.launcher}\nTryExec={self.launcher}\n"
                    .replace(f"{key}={self.launcher}", f"{key}=/usr/local/libexec/awesome-session")
                )
                self.assert_failure(f"{key} must point to")

    def test_invalid_launcher_syntax(self):
        self.source.write_text("if then\n")
        self.assert_failure("invalid shell syntax")

    def test_missing_session(self):
        self.session.unlink()
        self.assert_failure("session entry is missing")

    def test_missing_configuration(self):
        self.configuration.unlink()
        self.assert_failure("configuration is missing")

    def test_invalid_configuration(self):
        self.awesome.write_text("#!/bin/bash\nexit 1\n")
        self.assert_failure("configuration validation failed")

    def prepare_launcher(self):
        self.source.write_text(LAUNCHER.read_text())
        self.arguments = self.home / "session-arguments"
        self.environment["SESSION_TEST_ARGS"] = str(self.arguments)
        self.environment.pop("DISPLAY", None)
        self.startx = self.home / ".local/bin/startx"
        self.startx.write_text(
            '#!/bin/bash\nprintf "%s\\n" "$XDG_SESSION_TYPE" "$@" > "$SESSION_TEST_ARGS"\n'
        )
        self.startx.chmod(0o755)

    def test_freeform_command_starts_x_without_display(self):
        self.prepare_launcher()
        (self.home / ".profile").write_text("exit 23\n")
        result = subprocess.run([str(self.launcher)], env=self.environment,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.arguments.read_text().splitlines(),
                         ["x11", "/usr/bin/env", str(self.launcher), "--"])

    def test_x11_wrapper_does_not_start_nested_x_server(self):
        self.prepare_launcher()
        self.environment["DISPLAY"] = ":42"
        (self.home / ".profile").write_text("exit 23\n")
        result = subprocess.run([str(self.launcher)], env=self.environment,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 23, result.stderr)
        self.assertFalse(self.arguments.exists())

    def test_startx_failure_is_propagated(self):
        self.prepare_launcher()
        self.startx.write_text("#!/bin/bash\nexit 17\n")
        result = subprocess.run([str(self.launcher)], env=self.environment,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 17, result.stderr)


if __name__ == "__main__":
    unittest.main()
