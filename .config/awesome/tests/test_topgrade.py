"""Verify fresh npm installs expose their binaries to post-install commands."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

TOPGRADE = Path(__file__).resolve().parents[3] / ".local/bin/topgrade"


class NpmToolCommandsTests(unittest.TestCase):
    def run_topgrade(self, directory, *, tool_exit=0, shadow=False, existing_path=False):
        root = Path(directory)
        home = root / "home with spaces"
        config = home / ".config/npm-backup"
        config.mkdir(parents=True)
        data = home / "application data"
        config.joinpath("packages.in").write_text("@playwright/mcp@latest\n")
        config.joinpath("package-tools.in").write_text("playwright-mcp install-browser chromium\n")
        fake_bin = root / "bin"
        fake_bin.mkdir()
        npm = fake_bin / "npm"
        npm.write_text('''#!/usr/bin/python3
import os
import sys
from pathlib import Path
if sys.argv[1:3] == ['install', '-g']:
    target = Path(os.environ['npm_config_prefix']) / 'bin/playwright-mcp'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text('#!/bin/bash\\nprintf "%s\\\\n" "$*" > "$TOOL_TRACE"\\nprintf "%s\\\\n" "$PATH" > "$TOOL_PATH_TRACE"\\nexit '+os.environ['TOOL_EXIT']+'\\n')
    target.chmod(0o755)
elif sys.argv[1:] != ['cache', 'verify']:
    sys.exit(99)
''')
        npm.chmod(0o755)
        if shadow:
            other = fake_bin / "playwright-mcp"
            other.write_text("#!/bin/sh\nexit 97\n")
            other.chmod(0o755)
        trace = root / "tool-trace"
        path_trace = root / "tool-path-trace"
        parent_path_trace = root / "parent-path-trace"
        initial_path = f"{fake_bin}:/usr/bin:/bin"
        if existing_path:
            initial_path = f"{data}/npm/bin:{initial_path}"
        env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"),
                   XDG_DATA_HOME=str(data), PATH=initial_path,
                   TOOL_TRACE=str(trace), TOOL_PATH_TRACE=str(path_trace), TOOL_EXIT=str(tool_exit),
                   PARENT_PATH_TRACE=str(parent_path_trace))
        result = subprocess.run(["bash", "-c", 'source "$1"; printf "%s\\n" "$PATH" > "$PARENT_PATH_TRACE"',
                                 "test", str(TOPGRADE)], env=env, check=False,
                                text=True, capture_output=True)
        self.tool_path = path_trace.read_text().strip() if path_trace.exists() else ""
        self.npm_bin = str(data / "npm/bin")
        self.parent_path = parent_path_trace.read_text().strip() if parent_path_trace.exists() else ""
        return result, trace.read_text() if trace.exists() else ""

    def test_newly_created_npm_bin_is_visible_without_a_new_login(self):
        with tempfile.TemporaryDirectory() as directory:
            result, trace = self.run_topgrade(directory)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(trace.strip(), "install-browser chromium")
            self.assertIn("Topgrade complete", result.stdout)

    def test_configured_npm_prefix_takes_precedence_over_another_install(self):
        with tempfile.TemporaryDirectory() as directory:
            result, trace = self.run_topgrade(directory, shadow=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(trace.strip(), "install-browser chromium")

    def test_failed_post_install_command_fails_the_upgrade(self):
        with tempfile.TemporaryDirectory() as directory:
            result, _ = self.run_topgrade(directory, tool_exit=23)
            self.assertEqual(result.returncode, 23, result.stdout + result.stderr)
            self.assertNotIn("Topgrade complete", result.stdout)

    def test_existing_npm_path_is_not_duplicated(self):
        with tempfile.TemporaryDirectory() as directory:
            result, _ = self.run_topgrade(directory, existing_path=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(self.tool_path.split(":").count(self.npm_bin), 1)

    def test_tool_function_does_not_change_its_callers_path(self):
        with tempfile.TemporaryDirectory() as directory:
            result, _ = self.run_topgrade(directory)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn(self.npm_bin, self.tool_path.split(":"))
            self.assertNotIn(self.npm_bin, self.parent_path.split(":"))


if __name__ == "__main__":
    unittest.main()
