"""Verify installation and command lookup for profile-managed tools."""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

TOPGRADE = Path(__file__).resolve().parents[3] / ".local/bin/topgrade"


class NpmToolCommandsTests(unittest.TestCase):
    def run_topgrade(
        self, directory, *, tool_exit=0, shadow=False, existing_path=False
    ):
        root = Path(directory)
        home = root / "home with spaces"
        config = home / ".config/npm-backup"
        config.mkdir(parents=True)
        data = home / "application data"
        config.joinpath("packages.in").write_text("@playwright/mcp@latest\n")
        config.joinpath("package-tools.in").write_text(
            "playwright-mcp install-browser chromium\n"
        )
        fake_bin = root / "bin"
        fake_bin.mkdir()
        npm = fake_bin / "npm"
        npm.write_text("""#!/usr/bin/python3
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
""")
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
        env = dict(
            os.environ,
            HOME=str(home),
            XDG_CONFIG_HOME=str(home / ".config"),
            XDG_DATA_HOME=str(data),
            PATH=initial_path,
            TOOL_TRACE=str(trace),
            TOOL_PATH_TRACE=str(path_trace),
            TOOL_EXIT=str(tool_exit),
            PARENT_PATH_TRACE=str(parent_path_trace),
        )
        result = subprocess.run(
            [
                "bash",
                "-c",
                'source "$1"; printf "%s\\n" "$PATH" > "$PARENT_PATH_TRACE"',
                "test",
                str(TOPGRADE),
            ],
            env=env,
            check=False,
            text=True,
            capture_output=True,
        )
        self.tool_path = path_trace.read_text().strip() if path_trace.exists() else ""
        self.npm_bin = str(data / "npm/bin")
        self.parent_path = (
            parent_path_trace.read_text().strip() if parent_path_trace.exists() else ""
        )
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


class RubyToolTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name) / "home with spaces"
        config = self.home / ".config/gem-backup"
        config.mkdir(parents=True)
        (config / "packages.in").write_text("# Command-line tools\n\nbundler\n")
        self.fake_bin = self.home / "bin"
        self.fake_bin.mkdir()
        self.trace = self.home / "gem-args"
        self.env = dict(
            os.environ,
            HOME=str(self.home),
            XDG_CONFIG_HOME=str(config.parent),
            PATH=f"{self.fake_bin}:/usr/bin:/bin",
            BASH_DIR=str(self.home),
            GEM_TRACE=str(self.trace),
        )
        fake_gem = self.fake_bin / "gem"
        fake_gem.write_text(
            '#!/bin/sh\nprintf "%s\\n" "$@" > "$GEM_TRACE"\nexit "${GEM_RESULT:-0}"\n'
        )
        fake_gem.chmod(0o755)

    def test_default_and_gems_only_install_into_a_stable_bin(self):
        for arguments in ([], ["--gems"]):
            with self.subTest(arguments=arguments):
                subprocess.run(
                    [TOPGRADE, *arguments],
                    env=self.env,
                    check=True,
                    capture_output=True,
                )
                self.assertEqual(
                    self.trace.read_text().splitlines(),
                    [
                        "install",
                        "--user-install",
                        "--bindir",
                        str(self.home / ".local/bin"),
                        "--no-document",
                        "bundler",
                    ],
                )
                self.trace.unlink()

    def test_gem_failure_is_not_reported_as_success(self):
        result = subprocess.run(
            [TOPGRADE, "--gems"],
            env=dict(self.env, GEM_RESULT="23"),
            capture_output=True,
        )
        self.assertEqual(result.returncode, 23)

    def test_unknown_option_does_not_upgrade_anything(self):
        result = subprocess.run(
            [TOPGRADE, "--version"], env=self.env, capture_output=True
        )
        self.assertEqual(result.returncode, 2)
        self.assertFalse(self.trace.exists())

    def test_profile_exposes_active_user_bin_before_first_install(self):
        user_gems = self.home / "gems for this Ruby"
        fake_ruby = self.fake_bin / "ruby"
        fake_ruby.write_text('#!/bin/sh\nprintf "%s" "$TEST_GEM_HOME"\n')
        fake_ruby.chmod(0o755)
        profile = TOPGRADE.parents[2] / ".config/bash/bash_custom"
        for shell in ("bash", "zsh"):
            with self.subTest(shell=shell):
                result = subprocess.run(
                    [
                        shell,
                        "-c",
                        '. "$1"; . "$1"; printf "%s\\n" "$GEM_HOME" "$PATH"',
                        "test",
                        str(profile),
                    ],
                    env=dict(
                        self.env,
                        TEST_GEM_HOME=str(user_gems),
                        GEM_HOME="/old/ruby",
                        CPPFLAGS="",
                        PYTHONPATH="",
                    ),
                    capture_output=True,
                    text=True,
                    check=True,
                )
                gem_home, path = result.stdout.splitlines()
                self.assertEqual(gem_home, str(user_gems))
                self.assertEqual(path.split(":").count(str(user_gems / "bin")), 1)
                self.assertFalse(user_gems.exists())


if __name__ == "__main__":
    unittest.main()
