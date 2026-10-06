#!/usr/bin/env python3
"""Use disposable local Git histories; no network, user repository or desktop IO."""

import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "utilities/desktop/config-pull"
CONFIG = ".config/awesome/configuration/config.lua"
VARIANT = ".config/awesome/configuration/config_imac.lua"


def config(machine, revision):
    return f"return {{\n    machine = '{machine}',\n    revision = '{revision}',\n}}\n"


class PullTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.source = self.base / "upstream"
        self.home = self.base / "home"
        self.home.mkdir()
        self.env = os.environ | {
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_SYSTEM": os.devnull,
            "GIT_AUTHOR_NAME": "Fixture",
            "GIT_COMMITTER_NAME": "Fixture",
            "GIT_AUTHOR_EMAIL": "fixture@example.test",
            "GIT_COMMITTER_EMAIL": "fixture@example.test",
            "HOME": str(self.home),
            "XDG_STATE_HOME": str(self.home / ".local/state"),
        }
        self.git(["init", "-q", "--initial-branch=master", str(self.source)])
        (self.source / CONFIG).parent.mkdir(parents=True)
        (self.source / CONFIG).write_text(config("laptop", "base"))
        (self.source / VARIANT).write_text(config("imac", "base"))
        (self.source / ".gitignore").write_text("/.config.git/\n/.local/state/\n")
        (self.source / "notes.txt").write_text("base notes\n")
        self.commit(self.source)
        self.git(
            [
                "clone",
                "-q",
                "--bare",
                str(self.source),
                str(self.home / ".config.git"),
            ]
        )
        self.local("checkout", "--force")
        (self.home / CONFIG).write_bytes((self.home / VARIANT).read_bytes())
        self.local("update-index", "--assume-unchanged", "--", CONFIG)

    def git(self, args, cwd=None, input_text=None, check=True):
        return subprocess.run(
            ["git"] + args,
            cwd=cwd or self.base,
            env=self.env,
            input=input_text,
            text=True,
            capture_output=True,
            check=check,
        )

    def local(self, *args, **kwargs):
        return self.git(
            [
                "-c",
                "core.bare=false",
                f"--git-dir={self.home / '.config.git'}",
                f"--work-tree={self.home}",
            ]
            + list(args),
            cwd=self.home,
            **kwargs,
        )

    def commit(self, directory, local=False):
        runner = (
            self.local
            if local
            else lambda *args, **kwargs: self.git(
                ["-C", str(directory)] + list(args), **kwargs
            )
        )
        runner("add", "-A")
        tree = runner("write-tree").stdout.strip()
        previous = runner("rev-parse", "--verify", "HEAD", check=False)
        parents = ["-p", previous.stdout.strip()] if previous.returncode == 0 else []
        commit = runner(
            "commit-tree", tree, *parents, input_text="Generic fixture\n"
        ).stdout.strip()
        runner("update-ref", "refs/heads/master", commit)

    def upstream_update(self):
        (self.source / CONFIG).write_text(config("laptop", "updated"))
        (self.source / VARIANT).write_text(config("imac", "updated"))
        self.commit(self.source)

    def run_helper(self, *args):
        return subprocess.run(
            ["/usr/bin/python3", str(HELPER), *args],
            cwd=self.home,
            env=self.env,
            text=True,
            capture_output=True,
            timeout=15,
            check=False,
        )

    def test_success_reapplies_updated_variant_and_preserves_autostashed_work(
        self,
    ):
        (self.home / "notes.txt").write_text("base notes\nlocal note\n")
        self.upstream_update()
        result = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            (self.home / CONFIG).read_bytes(),
            (self.home / VARIANT).read_bytes(),
        )
        self.assertIn("updated", (self.home / CONFIG).read_text())
        self.assertEqual(
            self.local("show", "HEAD:" + CONFIG).stdout,
            config("laptop", "updated"),
        )
        self.assertIn("local note", (self.home / "notes.txt").read_text())
        self.assertTrue(
            self.local("ls-files", "-v", "--", CONFIG).stdout.startswith("h ")
        )
        self.assertFalse(self.local("diff", "--cached", "--name-only").stdout)

    def test_laptop_pulls_normally_without_profile_copy(self):
        self.local("update-index", "--no-assume-unchanged", "--", CONFIG)
        (self.home / CONFIG).write_text(config("laptop", "base"))
        self.upstream_update()
        result = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / CONFIG).read_text(), config("laptop", "updated"))
        self.assertTrue(
            self.local("ls-files", "-v", "--", CONFIG).stdout.startswith("H ")
        )

    def test_failed_fetch_restores_exact_config_flags_and_permissions(self):
        original = (self.home / CONFIG).read_bytes()
        self.local("remote", "set-url", "origin", str(self.base / "missing-upstream"))
        result = self.run_helper()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.home / CONFIG).read_bytes(), original)
        self.assertEqual((self.home / CONFIG).stat().st_mode & 0o777, 0o644)
        self.assertTrue(
            self.local("ls-files", "-v", "--", CONFIG).stdout.startswith("h ")
        )
        backups = list(
            (self.home / ".local/state/awesome/config-pull").glob("pull-*/config.lua")
        )
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].stat().st_mode & 0o777, 0o600)

    def test_staged_config_is_refused_without_index_or_worktree_changes(self):
        self.local("update-index", "--no-assume-unchanged", "--", CONFIG)
        self.local("add", CONFIG)
        before = self.local("diff", "--cached").stdout
        result = self.run_helper()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.local("diff", "--cached").stdout, before)
        self.assertEqual((self.home / CONFIG).read_text(), config("imac", "base"))

    def test_managed_rebase_conflict_is_not_hidden_or_overwritten(self):
        self.local("update-index", "--no-assume-unchanged", "--", CONFIG)
        (self.home / CONFIG).write_text(config("laptop", "local history"))
        self.commit(self.home, local=True)
        (self.home / CONFIG).write_text(config("imac", "base"))
        self.local("update-index", "--assume-unchanged", "--", CONFIG)
        self.upstream_update()
        result = self.run_helper()
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(
            self.local("ls-files", "--unmerged", "--", CONFIG).stdout,
            result.stdout
            + result.stderr
            + self.local("status", "--short").stdout
            + self.local("ls-files").stdout,
        )
        self.assertIn("<<<<<<<", (self.home / CONFIG).read_text())
        self.assertIn("conflict files remain intact", result.stderr)
        self.assertTrue(
            list(
                (self.home / ".local/state/awesome/config-pull").glob(
                    "pull-*/config.lua"
                )
            )
        )

    def test_apply_profile_is_desktop_only_and_keeps_tracked_laptop_index(self):
        result = self.run_helper("--apply-profile", "imac")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.local("show", ":" + CONFIG).stdout, config("laptop", "base")
        )
        self.assertNotEqual(self.run_helper("--apply-profile", "laptop").returncode, 0)

    def test_unrelated_rebase_conflict_retains_original_profile_and_conflict(
        self,
    ):
        self.local("update-index", "--no-assume-unchanged", "--", CONFIG)
        (self.home / CONFIG).write_text(config("laptop", "base"))
        (self.home / "notes.txt").write_text("local history notes\n")
        self.commit(self.home, local=True)
        (self.home / CONFIG).write_text(config("imac", "base"))
        self.local("update-index", "--assume-unchanged", "--", CONFIG)
        (self.source / "notes.txt").write_text("upstream history notes\n")
        self.commit(self.source)
        result = self.run_helper()
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(self.local("ls-files", "--unmerged", "--", "notes.txt").stdout)
        self.assertIn("<<<<<<<", (self.home / "notes.txt").read_text())
        self.assertEqual((self.home / CONFIG).read_text(), config("imac", "base"))
        self.assertTrue(
            self.local("ls-files", "-v", "--", CONFIG).stdout.startswith("h ")
        )

    def test_custom_active_configuration_is_backed_up_before_successful_replacement(
        self,
    ):
        original = config("imac", "local-only setting")
        (self.home / CONFIG).write_text(original)
        self.upstream_update()
        result = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / CONFIG).read_text(), config("imac", "updated"))
        backups = list(
            (self.home / ".local/state/awesome/config-pull").glob("pull-*/config.lua")
        )
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), original)
        self.assertEqual(backups[0].stat().st_mode & 0o777, 0o600)

    def test_missing_variant_never_cleans_active_config(self):
        (self.home / VARIANT).unlink()
        original = (self.home / CONFIG).read_bytes()
        self.assertNotEqual(self.run_helper().returncode, 0)
        self.assertEqual((self.home / CONFIG).read_bytes(), original)

    def test_cpulla_uses_bootstrap_copy_until_tracked_helper_arrives(self):
        plugin = (
            ROOT.parent / "zsh/zsh-custom/plugins/custom-alias/custom-alias.plugin.zsh"
        )
        function = re.search(
            r"function cpulla\(\) \{.*?\n\}", plugin.read_text(), re.S
        ).group()
        fallback = self.home / ".config.git/local-tools/config-pull"
        fallback.parent.mkdir()
        shutil.copy2(HELPER, fallback)
        fallback.chmod(0o755)
        result = subprocess.run(
            ["zsh", "-f", "-c", function + "\ncpulla --help"],
            env=self.env,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("config-pull", result.stdout)
        incoming = self.source / ".config/awesome/utilities/desktop/config-pull"
        incoming.parent.mkdir(parents=True)
        shutil.copy2(HELPER, incoming)
        self.commit(self.source)
        pulled = subprocess.run(
            ["zsh", "-f", "-c", function + "\ncpulla"],
            env=self.env,
            text=True,
            capture_output=True,
            timeout=15,
            check=False,
        )
        self.assertEqual(pulled.returncode, 0, pulled.stderr)
        tracked = self.home / ".config/awesome/utilities/desktop/config-pull"
        self.assertTrue(
            tracked.exists(),
            "The first upstream pull must install the tracked helper without collision",
        )
        fallback.unlink()
        preferred = subprocess.run(
            ["zsh", "-f", "-c", function + "\ncpulla --help"],
            env=self.env,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(
            preferred.returncode,
            0,
            "cpulla must prefer the tracked helper once it arrives",
        )

    def test_cpulla_missing_or_nonexecutable_helpers_use_original_git_arguments(
        self,
    ):
        plugin = (
            ROOT.parent / "zsh/zsh-custom/plugins/custom-alias/custom-alias.plugin.zsh"
        )
        function = re.search(
            r"function cpulla\(\) \{.*?\n\}", plugin.read_text(), re.S
        ).group()
        commands = self.base / "commands"
        commands.mkdir()
        fake_git = commands / "git"
        fake_git.write_text(
            "#!/usr/bin/python3\nimport json, sys\nprint(json.dumps(sys.argv[1:]))\n"
        )
        fake_git.chmod(0o755)
        env = self.env | {"PATH": str(commands) + os.pathsep + self.env["PATH"]}
        for nonexecutable in (False, True):
            with self.subTest(nonexecutable=nonexecutable):
                if nonexecutable:
                    for path in (
                        self.home / ".config/awesome/utilities/desktop/config-pull",
                        self.home / ".config.git/local-tools/config-pull",
                    ):
                        path.parent.mkdir(parents=True, exist_ok=True)
                        path.write_text("Must not run")
                        path.chmod(0o644)
                result = subprocess.run(
                    [
                        "zsh",
                        "-f",
                        "-c",
                        function + '\ncpulla "$@"',
                        "--",
                        "origin",
                        "topic/with space",
                    ],
                    env=env,
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    json.loads(result.stdout),
                    [
                        f"--git-dir={self.home}/.config.git/",
                        f"--work-tree={self.home}",
                        "pull",
                        "--rebase",
                        "--autostash",
                        "origin",
                        "topic/with space",
                    ],
                )

    def test_cpulla_propagates_helper_failure_without_retrying_plain_pull(self):
        plugin = (
            ROOT.parent / "zsh/zsh-custom/plugins/custom-alias/custom-alias.plugin.zsh"
        )
        function = re.search(
            r"function cpulla\(\) \{.*?\n\}", plugin.read_text(), re.S
        ).group()
        helper = self.home / ".config/awesome/utilities/desktop/config-pull"
        helper.parent.mkdir(parents=True)
        helper.write_text("#!/bin/sh\nexit 23\n")
        helper.chmod(0o755)
        result = subprocess.run(
            ["zsh", "-f", "-c", function + "\ncpulla"],
            env=self.env,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 23)
        self.assertNotIn("pull", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
