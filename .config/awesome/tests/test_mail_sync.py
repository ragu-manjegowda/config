#!/usr/bin/env python3
"""Manual/background mail synchronization tests with real locking and fake commands."""

import fcntl
import json
import os
import re
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NOTIFY = ROOT.parent / "imapnotify/notify.sh"

FAKE = r"""#!/usr/bin/python3
import json, os, pathlib, subprocess, sys
name = pathlib.Path(sys.argv[0]).name
root = pathlib.Path(os.environ['MAIL_SYNC_TEST_ROOT'])
args = sys.argv[1:]
account = 'outlook' if 'outlook' in os.environ.get('NOTMUCH_CONFIG', '') else 'gmail'
with (root / 'calls.jsonl').open('a') as output:
    output.write(json.dumps([name, account, args]) + '\n')
if name == 'mbsync':
    status = int(os.environ.get('FAIL_OUTLOOK' if args[-1].startswith('outlook') else 'FAIL_GMAIL', '0'))
    if status:
        print('simulated mbsync failure', file=sys.stderr)
    sys.exit(status)
elif name == 'notmuch':
    sys.exit(int(os.environ.get('FAIL_NOTMUCH', '0')))
elif name == 'systemctl':
    print('DISPLAY=:99\nXAUTHORITY=/fixture/Xauthority\nDBUS_SESSION_BUS_ADDRESS=unix:path=/fixture/bus')
elif name == 'timeout':
    sys.exit(subprocess.call(args[2:]))
elif name == 'fetch-emails.py':
    sys.exit(int(os.environ.get('FAIL_FETCH', '0')))
"""


class SyncTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if NOTIFY.read_bytes().startswith(b"\x00GITCRYPT\x00"):
            raise unittest.SkipTest("Sync helper is git-crypt locked")

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.bin = self.home / "bin"
        self.bin.mkdir()
        for command in (
            "mbsync",
            "notmuch",
            "systemctl",
            "awesome-client",
            "timeout",
        ):
            path = self.bin / command
            path.write_text(FAKE)
            path.chmod(0o755)
        fetch = self.home / ".config/imapnotify/fetch-emails.py"
        fetch.parent.mkdir(parents=True)
        fetch.write_text(FAKE)
        fetch.chmod(0o755)
        self.env = os.environ | {
            "HOME": str(self.home),
            "XDG_STATE_HOME": str(self.home / "state"),
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "MAIL_SYNC_TEST_ROOT": str(self.home),
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
        }

    def command(self, full=False, **extra):
        env = self.env | {"FULL_SYNC": "1" if full else "0"} | extra
        return ["/usr/bin/bash", str(NOTIFY)], env

    def sync(self, full=False, **extra):
        argv, env = self.command(full, **extra)
        return subprocess.run(
            argv,
            env=env,
            text=True,
            capture_output=True,
            timeout=5,
            check=False,
        )

    def calls(self):
        path = self.home / "calls.jsonl"
        return (
            [json.loads(line) for line in path.read_text().splitlines()]
            if path.exists()
            else []
        )

    def hold_lock(self):
        path = self.home / "state/neomutt/mbsync.lock"
        path.parent.mkdir(parents=True, exist_ok=True)
        handle = path.open("w")
        fcntl.flock(handle, fcntl.LOCK_EX)
        self.addCleanup(handle.close)
        return handle

    def test_full_sync_uses_push_channels_and_indexes_each_account_once(self):
        result = self.sync(full=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        channels = [args[-1] for name, _, args in self.calls() if name == "mbsync"]
        self.assertEqual(channels, ["outlook", "gmail-personal"])
        self.assertEqual(sum(name == "notmuch" for name, _, _ in self.calls()), 2)

    def test_background_sync_remains_pull_only(self):
        self.assertEqual(self.sync().returncode, 0)
        channels = [args[-1] for name, _, args in self.calls() if name == "mbsync"]
        self.assertEqual(channels, ["outlook-pull", "gmail-personal-pull"])

    def test_personal_manual_sync_only_syncs_and_indexes_gmail(self):
        result = self.sync(full=True, MAIL_SYNC_ACCOUNT="gmail-personal")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls()
        self.assertEqual(
            [args[-1] for name, _, args in calls if name == "mbsync"],
            ["gmail-personal"],
        )
        self.assertEqual(
            [(account, args) for name, account, args in calls if name == "notmuch"],
            [("gmail", ["new"])],
        )
        self.assertFalse(any(name == "fetch-emails.py" for name, _, _ in calls))

    def test_personal_manual_sync_uses_the_background_worker_lock(self):
        self.hold_lock()
        result = self.sync(
            full=True,
            MAIL_SYNC_ACCOUNT="gmail-personal",
            MANUAL_SYNC_LOCK_TIMEOUT_SECONDS="0.1",
        )
        self.assertEqual(result.returncode, 75)
        self.assertEqual(self.calls(), [])

    def test_personal_sync_failure_is_reported(self):
        result = self.sync(
            full=True, MAIL_SYNC_ACCOUNT="gmail-personal", FAIL_GMAIL="1"
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(name == "notmuch" for name, _, _ in self.calls()))

    def test_unknown_account_cannot_silently_succeed(self):
        result = self.sync(full=True, MAIL_SYNC_ACCOUNT="unknown")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Unknown mail sync account", result.stderr)
        self.assertEqual(self.calls(), [])

    def test_manual_failure_diagnostics_survive_a_background_sync(self):
        result = self.sync(full=True, FAIL_GMAIL="1")
        self.assertNotEqual(result.returncode, 0)
        latest = self.home / "state/neomutt/manual-sync-last"
        run = latest.resolve()
        status = (run / "status").read_text()
        self.assertIn("account=all\n", status)
        self.assertIn("exit_status=1\n", status)
        self.assertIn("failed_steps=gmail-mbsync\n", status)
        failure_log = (run / "mbsync-gmail-personal.log").read_text()
        self.assertIn("simulated mbsync failure", failure_log)
        self.assertEqual(self.sync().returncode, 0)
        self.assertEqual(latest.resolve(), run)
        self.assertEqual((run / "status").read_text(), status)
        self.assertEqual((run / "mbsync-gmail-personal.log").read_text(), failure_log)

    def test_each_manual_attempt_preserves_its_own_result(self):
        self.assertNotEqual(self.sync(full=True, FAIL_OUTLOOK="1").returncode, 0)
        latest = self.home / "state/neomutt/manual-sync-last"
        failed_run = latest.resolve()
        self.assertIn("failed_steps=outlook-mbsync\n", (failed_run / "status").read_text())
        self.assertEqual(self.sync(full=True).returncode, 0)
        successful_run = latest.resolve()
        self.assertNotEqual(failed_run, successful_run)
        self.assertIn("exit_status=0\n", (successful_run / "status").read_text())
        self.assertIn("exit_status=1\n", (failed_run / "status").read_text())

    def test_manual_summary_and_index_failures_identify_the_failing_stage(self):
        for failure, stage in (
            ("FAIL_FETCH", "outlook-summary"),
            ("FAIL_NOTMUCH", "outlook-index,gmail-index"),
        ):
            with self.subTest(failure=failure):
                self.assertNotEqual(self.sync(full=True, **{failure: "1"}).returncode, 0)
                status = (self.home / "state/neomutt/manual-sync-last/status").read_text()
                self.assertIn(f"failed_steps={stage}\n", status)

    def test_manual_lock_timeout_has_a_persistent_diagnostic(self):
        self.hold_lock()
        result = self.sync(full=True, MANUAL_SYNC_LOCK_TIMEOUT_SECONDS="0.1")
        self.assertEqual(result.returncode, 75)
        status = (self.home / "state/neomutt/manual-sync-last/status").read_text()
        self.assertIn("exit_status=75\n", status)
        self.assertIn("failed_steps=lock-timeout\n", status)

    def test_latest_logs_are_available_while_manual_sync_waits_for_the_lock(self):
        self.assertEqual(self.sync(full=True).returncode, 0)
        latest = self.home / "state/neomutt/manual-sync-last"
        previous = latest.resolve()
        handle = self.hold_lock()
        argv, env = self.command(full=True, MANUAL_SYNC_LOCK_TIMEOUT_SECONDS="5")
        with subprocess.Popen(
            argv, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        ) as process:
            try:
                deadline = time.monotonic() + 2
                while latest.resolve() == previous and time.monotonic() < deadline:
                    time.sleep(0.01)
                current = latest.resolve()
                self.assertNotEqual(current, previous)
                self.assertIsNone(process.poll())
                self.assertFalse((current / "status").exists())
                for name in (
                    "mbsync-outlook.log",
                    "mbsync-gmail-personal.log",
                    "fetch-outlook.log",
                ):
                    self.assertEqual((latest / name).read_text(), "")
                    self.assertEqual((latest / name).stat().st_mode & 0o777, 0o600)
            finally:
                handle.close()
                _, stderr = process.communicate(timeout=5)
            self.assertEqual(process.returncode, 0, stderr)
        self.assertEqual(latest.resolve(), current)
        self.assertIn("exit_status=0\n", (latest / "status").read_text())

    def test_older_completion_does_not_replace_the_latest_started_run(self):
        self.hold_lock()
        first_argv, first_env = self.command(
            full=True, MANUAL_SYNC_LOCK_TIMEOUT_SECONDS="1"
        )
        latest = self.home / "state/neomutt/manual-sync-last"
        with subprocess.Popen(
            first_argv, env=first_env,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        ) as first:
            deadline = time.monotonic() + 2
            while not latest.is_symlink() and time.monotonic() < deadline:
                time.sleep(0.01)
            self.assertTrue(latest.is_symlink())
            first_run = latest.resolve()
            second = self.sync(full=True, MANUAL_SYNC_LOCK_TIMEOUT_SECONDS="0.1")
            self.assertEqual(second.returncode, 75)
            second_run = latest.resolve()
            self.assertNotEqual(first_run, second_run)
            first.communicate(timeout=5)
            self.assertEqual(first.returncode, 75)
        self.assertEqual(latest.resolve(), second_run)
        self.assertIn("exit_status=75\n", (first_run / "status").read_text())

    def test_manual_log_retention_keeps_the_three_most_recent_completed_runs(self):
        state = self.home / "state/neomutt"
        state.mkdir(parents=True)
        old_runs = []
        for index in range(5):
            run = state / f"manual-sync-20000101T00000{index}-fixture"
            run.mkdir()
            status = run / "status"
            status.write_text("exit_status=0\n")
            os.utime(status, (index + 1, index + 1))
            old_runs.append(run)
        self.assertEqual(self.sync(full=True, MAIL_SYNC_ACCOUNT="gmail-personal").returncode, 0)
        latest = (state / "manual-sync-last").resolve()
        completed = {path for path in state.glob("manual-sync-[0-9]*") if path.is_dir()}
        self.assertEqual(completed, {latest, old_runs[3], old_runs[4]})

    def test_manual_log_retention_preserves_in_progress_and_unrelated_directories(self):
        state = self.home / "state/neomutt"
        state.mkdir(parents=True)
        active = state / "manual-sync-20000101T000000-active"
        active.mkdir()
        unrelated = state / "sync-diagnostic-existing"
        unrelated.mkdir()
        (unrelated / "status").write_text("preserve this unrelated directory\n")
        link = state / "manual-sync-20000101T000000-linked"
        link.symlink_to(unrelated, target_is_directory=True)
        for _ in range(4):
            self.assertEqual(self.sync(full=True, MAIL_SYNC_ACCOUNT="gmail-personal").returncode, 0)
        self.assertTrue(active.is_dir())
        self.assertTrue(link.is_symlink())
        self.assertTrue((unrelated / "status").is_file())
        completed = [path for path in state.glob("manual-sync-[0-9]*")
                     if not path.is_symlink() and (path / "status").is_file()]
        self.assertEqual(len(completed), 3)

    def test_busy_background_sync_is_coalesced(self):
        self.hold_lock()
        self.assertEqual(self.sync().returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_busy_manual_sync_cannot_report_success_without_running(self):
        self.hold_lock()
        result = self.sync(full=True, MANUAL_SYNC_LOCK_TIMEOUT_SECONDS="0.1")
        self.assertEqual(result.returncode, 75)
        self.assertEqual(self.calls(), [])

    def test_manual_sync_waits_for_existing_worker_then_runs(self):
        handle = self.hold_lock()
        argv, env = self.command(full=True, MANUAL_SYNC_LOCK_TIMEOUT_SECONDS="2")
        with subprocess.Popen(
            argv,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        ) as process:
            time.sleep(0.15)
            self.assertIsNone(process.poll())
            self.assertEqual(self.calls(), [])
            handle.close()
            _, stderr = process.communicate(timeout=5)
            self.assertEqual(process.returncode, 0, stderr)
        self.assertEqual(sum(name == "mbsync" for name, _, _ in self.calls()), 2)

    def test_outlook_failure_is_not_hidden_by_successful_index_or_gmail(self):
        self.assertNotEqual(self.sync(full=True, FAIL_OUTLOOK="1").returncode, 0)
        self.assertFalse(
            any(
                name == "notmuch" and account == "outlook"
                for name, account, _ in self.calls()
            )
        )
        self.assertTrue(
            any(
                name == "notmuch" and account == "gmail"
                for name, account, _ in self.calls()
            )
        )

    def test_index_summary_and_other_account_failures_are_reported(self):
        for failure in ("FAIL_NOTMUCH", "FAIL_FETCH", "FAIL_GMAIL"):
            with self.subTest(failure=failure):
                self.assertNotEqual(
                    self.sync(full=True, **{failure: "1"}).returncode, 0
                )

    def test_work_macro_saves_flags_before_background_full_sync(self):
        path = ROOT.parent / "neomutt/accounts/work/config-offline"
        blob = path.read_bytes()
        if blob.startswith(b"\x00GITCRYPT\x00"):
            self.skipTest("Account configuration is git-crypt locked")
        macro = re.search(
            r'macro index o.*?"run mbsync to sync outlook"', blob.decode(), re.DOTALL
        ).group()
        self.assertLessEqual(max(len(line) for line in macro.splitlines()), 80)
        self.assertLess(macro.index("<sync-mailbox>"), macro.index("<shell-escape>"))
        self.assertIn("FULL_SYNC=1", macro)
        self.assertIn("Email synchronization failed", macro)

    def test_personal_macro_saves_flags_and_uses_the_shared_lock_worker(self):
        path = ROOT.parent / "neomutt/accounts/personal/config-offline"
        blob = path.read_bytes()
        if blob.startswith(b"\x00GITCRYPT\x00"):
            self.skipTest("Account configuration is git-crypt locked")
        macro = re.search(
            r'macro index o.*?"run mbsync to sync gmail-personal"',
            blob.decode(),
            re.DOTALL,
        ).group()
        self.assertLessEqual(max(len(line) for line in macro.splitlines()), 80)
        self.assertLess(macro.index("<sync-mailbox>"), macro.index("<shell-escape>"))
        self.assertIn("FULL_SYNC=1 MAIL_SYNC_ACCOUNT=gmail-personal", macro)
        self.assertIn("~/.config/imapnotify/notify.sh", macro)
        self.assertIn("Email synchronization failed", macro)
        self.assertNotIn("mbsync -V", macro)

    def test_macro_notification_branch_uses_sync_result_not_notification_result(
        self,
    ):
        path = ROOT.parent / "neomutt/accounts/work/config-offline"
        blob = path.read_bytes()
        if blob.startswith(b"\x00GITCRYPT\x00"):
            self.skipTest("Account configuration is git-crypt locked")
        macro = re.search(
            r'macro index o.*?"run mbsync to sync outlook"', blob.decode(), re.DOTALL
        ).group()
        expanded = macro.replace("\\\n", "").replace('\\"', '"')
        command = expanded.split("<shell-escape>", 1)[1].split("<enter>", 1)[0]
        stub = self.home / ".config/imapnotify/notify.sh"
        stub.write_text('#!/bin/sh\nexit "${MAIL_MACRO_EXIT:-0}"\n')
        stub.chmod(0o755)
        notifier = self.bin / "notify-send"
        notifier.write_text(
            FAKE + '\nsys.exit(int(os.environ.get("MAIL_NOTIFY_EXIT", "0")))\n'
        )
        notifier.chmod(0o755)
        for sync_exit, notify_exit, expected in (
            ("0", "0", "Emails synchronized!"),
            ("1", "0", "Email synchronization failed"),
            ("0", "1", "Emails synchronized!"),
        ):
            with self.subTest(sync_exit=sync_exit, notify_exit=notify_exit):
                log = self.home / "calls.jsonl"
                log.unlink(missing_ok=True)
                result = subprocess.run(
                    ["/usr/bin/bash", "-c", command],
                    env=self.env
                    | {
                        "MAIL_MACRO_EXIT": sync_exit,
                        "MAIL_NOTIFY_EXIT": notify_exit,
                    },
                    text=True,
                    capture_output=True,
                    timeout=5,
                    check=False,
                )
                self.assertEqual(
                    result.returncode,
                    0,
                    "The shell launches the complete job in the background",
                )
                notifications = [
                    args for name, _, args in self.calls() if name == "notify-send"
                ]
                self.assertEqual(len(notifications), 1)
                self.assertIn(expected, notifications[0])


if __name__ == "__main__":
    unittest.main()
