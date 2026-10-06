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
    sys.exit(int(os.environ.get('FAIL_OUTLOOK' if args[-1].startswith('outlook') else 'FAIL_GMAIL', '0')))
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
            r'macro index o.*?"run mbsync to sync outlook"', blob.decode(), re.S
        ).group()
        self.assertLessEqual(max(len(line) for line in macro.splitlines()), 80)
        self.assertLess(macro.index("<sync-mailbox>"), macro.index("<shell-escape>"))
        self.assertIn("FULL_SYNC=1", macro)
        self.assertIn("Email synchronization failed", macro)

    def test_macro_notification_branch_uses_sync_result_not_notification_result(
        self,
    ):
        path = ROOT.parent / "neomutt/accounts/work/config-offline"
        blob = path.read_bytes()
        if blob.startswith(b"\x00GITCRYPT\x00"):
            self.skipTest("Account configuration is git-crypt locked")
        macro = re.search(
            r'macro index o.*?"run mbsync to sync outlook"', blob.decode(), re.S
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
