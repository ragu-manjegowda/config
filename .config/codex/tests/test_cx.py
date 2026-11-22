"""Codex launcher/session/theme regressions, with isolated metadata and tools."""

import importlib.util
import json
import os
import plistlib
import pty
import shutil
import signal
import sqlite3
import subprocess
import sys
import tempfile
import time
import tomllib
import unittest
import uuid
from pathlib import Path
from unittest.mock import MagicMock, patch

CONFIG = Path(__file__).resolve().parents[1]
HOME = CONFIG.parents[1]
LAUNCHER = HOME / ".local/bin/cx"
SPEC = importlib.util.spec_from_file_location("codex_tools", CONFIG / "tools.py")
TOOLS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(TOOLS)

MOCK = r'''#!/usr/bin/python3
import json, os, subprocess, sys, time
from pathlib import Path
name = Path(sys.argv[0]).name
args = sys.argv[1:]
if name == 'darkman':
    print(os.environ.get('TEST_THEME', 'dark'))
elif name == 'tmux':
    with open(os.environ['TEST_TMUX'], 'a') as output:
        output.write(json.dumps(args)+'\n')
    if args[0] == 'show-options' and args[-1] == 'window-style':
        print('fg=green,bg=black')
elif name == 'fzf':
    text = sys.stdin.read()
    Path(os.environ['TEST_FZF']).write_text(json.dumps({'args':args,'input':text}))
    if os.environ.get('TEST_CANCEL'):
        sys.exit(130)
    rows = text.splitlines()
    if rows: print(rows[0])
elif name == 'firejail':
    Path(os.environ['TEST_FIREJAIL']).write_text(json.dumps(args))
    for index, arg in enumerate(args):
        if not arg.startswith('--'):
            break
    environment = dict(os.environ)
    for arg in args[:index]:
        if arg.startswith('--env='):
            key, value = arg[len('--env='):].split('=',1)
            environment[key] = value
    sys.exit(subprocess.call(args[index:], env=environment))
else:
    with open(os.environ['TEST_CODEX'], 'a') as output:
        output.write(json.dumps({'args':args,'home':os.environ['HOME'],
                                'codex_home':os.environ.get('CODEX_HOME'),
                                'stdin_tty':sys.stdin.isatty()})+'\n')
    if os.environ.get('TEST_GATE'):
        gate = Path(os.environ['TEST_GATE'])
        Path(str(gate) + '.ready').touch()
        while not gate.exists(): time.sleep(0.01)
    sys.exit(int(os.environ.get('TEST_EXIT', '0')))
'''


class LauncherTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="cx tests ")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / "home with spaces"
        self.codex_home = self.home / ".config/codex"
        self.codex_home.mkdir(parents=True)
        shutil.copy2(CONFIG / "tools.py", self.codex_home / "tools.py")
        shutil.copytree(CONFIG / "themes", self.codex_home / "themes")
        (self.codex_home / "config.toml").write_text(
            'approval_policy = "on-request"\nsandbox_mode = "workspace-write"\n'
            '[tui]\ntheme = "solarized-opencode-dark"\n'
        )
        (self.home / ".config/git").mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("codex", "firejail", "darkman", "fzf", "tmux"):
            path = self.bin / name
            path.write_text(MOCK)
            path.chmod(0o755)
        self.repo = self.home / "project with spaces"
        self.repo.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), CODEX_HOME=str(self.codex_home),
                        XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_CACHE_HOME=str(self.home / ".cache"),
                        XDG_DATA_HOME=str(self.home / ".local/share"),
                        XDG_STATE_HOME=str(self.home / ".local/state"),
                        CX_PYTHON=sys.executable, CX_SANDBOX_DOCKER="0",
                        PATH=f"{self.bin}:{os.environ['PATH']}",
                        TEST_CODEX=str(self.root / "codex.jsonl"), TEST_FZF=str(self.root / "fzf.json"),
                        TEST_FIREJAIL=str(self.root / "firejail.json"))
        for key in ("GIT_DIR", "GIT_WORK_TREE", "GIT_CONFIG", "GIT_CONFIG_GLOBAL", "GIT_CONFIG_COUNT"):
            self.env.pop(key, None)
        subprocess.run(["/usr/bin/git", "init", "-q", str(self.repo)], env=self.env, check=True)

    def run_cx(self, *arguments, cwd=None, extra=None):
        return subprocess.run([str(LAUNCHER), *arguments], cwd=cwd or self.repo,
                              env=self.env | (extra or {}), check=False,
                              capture_output=True, text=True, timeout=10)

    def calls(self):
        path = self.root / "codex.jsonl"
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def seed_sessions(self):
        identifier = str(uuid.uuid4())
        with sqlite3.connect(self.codex_home / "state_5.sqlite") as database:
            database.execute("CREATE TABLE threads(id TEXT,cwd TEXT,updated_at INTEGER,recency_at_ms INTEGER,name TEXT,title TEXT,preview TEXT,source TEXT,archived INTEGER)")
            database.execute("INSERT INTO threads VALUES(?,?,?,?,?,?,?,?,?)",
                             (identifier, str(self.repo), 1, 2000000000000, "Named session", "Old title", "preview", "cli", 0))
            database.execute("INSERT INTO threads VALUES(?,?,?,?,?,?,?,?,?)",
                             (str(uuid.uuid4()), str(self.repo), 1, 3000000000000, "Archived", "", "preview", "cli", 1))
            database.execute("INSERT INTO threads VALUES(?,?,?,?,?,?,?,?,?)",
                             (str(uuid.uuid4()), str(self.repo), 1, 3000000000000, "Child", "", "preview", "subagent", 0))
        return identifier

    def test_native_options_and_exit_status_are_preserved(self):
        result = self.run_cx("--search", "-m", "example-model", "prompt with spaces", extra={"TEST_EXIT": "7"})
        self.assertEqual(result.returncode, 7)
        self.assertEqual(self.calls()[0]["args"], ["--search", "-m", "example-model", "prompt with spaces"])
        self.assertEqual(self.calls()[0]["home"], str(self.home))

    def test_specific_session_resumes_normally(self):
        identifier = str(uuid.uuid4())
        result = self.run_cx("--session", identifier, "follow up")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls()[0]["args"], ["resume", identifier, "follow up"])

    def test_idle_cleanup_runs_only_after_a_local_interactive_client(self):
        invocation_log = self.root / "idle-check"
        (self.codex_home / "tools.py").write_text(
            "import os, sys\nfrom pathlib import Path\n"
            "if sys.argv[1:] == ['stop-idle-daemon']:\n"
            "    assert Path(os.environ['TEST_CODEX']).is_file()\n"
            f"    Path({str(invocation_log)!r}).touch()\n"
        )
        for arguments, should_check in (
            ((), True), (("resume", "--last"), True), (("--no-daemon",), False),
            (("--remote=unix://",), False), (("app-server", "daemon", "start"), False),
            (("-p", "custom"), True),
        ):
            with self.subTest(arguments=arguments):
                invocation_log.unlink(missing_ok=True)
                Path(self.env["TEST_CODEX"]).unlink(missing_ok=True)
                master, slave = pty.openpty()
                try:
                    result = subprocess.run(
                        [str(LAUNCHER), *arguments], cwd=self.repo,
                        env=self.env | {"TMUX_PANE": "", "TEST_EXIT": "7"},
                        stdin=slave, stdout=slave, stderr=slave, check=False, timeout=10,
                    )
                finally:
                    os.close(master)
                    os.close(slave)
                self.assertEqual(result.returncode, 7)
                self.assertEqual(invocation_log.exists(), should_check)
                self.assertEqual(self.calls()[0]["args"], list(arguments))

    def test_idle_cleanup_rechecks_clients_before_stopping(self):
        if importlib.util.find_spec("websockets") is None:
            self.skipTest("websockets is unavailable")
        state = self.codex_home / "app-server-daemon"
        state.mkdir()
        (state / "daemon.pid").write_text('{"pid": 123}')
        control = self.codex_home / "app-server-control"
        control.mkdir()
        endpoint = self.root / "codex.sock"
        endpoint.touch()
        (control / "app-server-control.sock").symlink_to(endpoint)
        for socket_checks, active_work, should_stop in (
            ([True, True], False, True),
            ([False], False, False),
            ([True, False], False, False),
            ([True], True, False),
        ):
            with self.subTest(socket_checks=socket_checks, active_work=active_work), \
                 patch.object(TOOLS, "codex_home", return_value=self.codex_home), \
                 patch.object(TOOLS.stat, "S_ISSOCK", return_value=True), \
                 patch.object(TOOLS, "daemon_socket_is_idle", side_effect=socket_checks), \
                 patch.object(TOOLS, "daemon_work_is_idle", return_value=not active_work), \
                 patch("websockets.sync.client.unix_connect"), \
                 patch.object(TOOLS.subprocess, "run") as run:
                TOOLS.stop_idle_daemon()
                if should_stop:
                    run.assert_called_once_with(["codex", "app-server", "daemon", "stop"], timeout=5, check=True)
                else:
                    run.assert_not_called()

    def test_daemon_work_probe_checks_turns_and_queue(self):
        for status, thread_status, queue, expected in (
            ("disabled", "idle", [], True),
            ("disabled", "active", [], False),
            ("disabled", "idle", [{"id": "queued-work"}], False),
            ("connected", "idle", [], False),
        ):
            with self.subTest(status=status, thread_status=thread_status, queue=queue):
                connection = MagicMock()
                responses = (
                    {}, {"status": status}, {"data": ["thread-id"], "nextCursor": None},
                    {"thread": {"status": {"type": thread_status}}}, {"data": queue},
                )
                connection.recv.side_effect = [json.dumps({"id": index, "result": result})
                                               for index, result in enumerate(responses, 1)]
                self.assertEqual(TOOLS.daemon_work_is_idle(connection), expected)

    def test_metadata_picker_and_cancellation(self):
        identifier = self.seed_sessions()
        result = self.run_cx("--session")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls()[0]["args"], ["resume", identifier])
        picker = json.loads((self.root / "fzf.json").read_text())
        self.assertIn("Named session", picker["input"])
        self.assertNotIn("Archived", picker["input"])
        self.assertNotIn("Child", picker["input"])
        self.assertIn("ctrl-d:transform:", " ".join(picker["args"]))
        result = self.run_cx("--session", extra={"TEST_CANCEL": "1"})
        self.assertEqual(result.returncode, 130)
        self.assertEqual(len(self.calls()), 1)

    def test_double_ctrl_d_and_focus_reset(self):
        identifier = str(uuid.uuid4())
        confirmation = self.root / "confirm"
        confirmation.touch()
        args = (str(confirmation), str(LAUNCHER), identifier, "title [with]+chars")
        first = self.run_cx("--session-ctrl-d-action-for-fzf", *args)
        self.assertEqual(confirmation.read_text(), identifier)
        self.assertNotIn("bg-transform", first.stdout)
        second = self.run_cx("--session-ctrl-d-action-for-fzf", *args)
        self.assertIn("bg-transform", second.stdout)
        self.assertEqual(confirmation.read_text(), "")
        self.run_cx("--session-ctrl-d-action-for-fzf", *args)
        self.run_cx("--session-focus-action-for-fzf", str(confirmation), str(uuid.uuid4()))
        self.assertEqual(confirmation.read_text(), "")
        deletion = self.run_cx("--session-delete-for-fzf", *args)
        self.assertIn("reload[", deletion.stdout)
        self.assertEqual(self.calls()[0]["args"], ["delete", "--force", identifier])

    def test_sandbox_requires_root_and_rejects_remote(self):
        child = self.repo / "child"
        child.mkdir()
        for arguments, cwd in ((("--sandbox",), child), (("--sandbox",), self.home),
                                (("--sandbox", "--remote=ws://example"), self.repo)):
            result = self.run_cx(*arguments, cwd=cwd)
            self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.calls())

    def test_sandbox_wraps_codex_and_preserves_state(self):
        result = self.run_cx("--sandbox", "-m", "example")
        self.assertEqual(result.returncode, 0, result.stderr)
        options = json.loads((self.root / "firejail.json").read_text())
        self.assertIn(f"--read-only={self.home}", options)
        self.assertIn(f"--read-write={self.repo}", options)
        self.assertIn(f"--read-write={self.codex_home}", options)
        self.assertIn(f"--read-only={self.home / '.config/git'}", options)
        call = self.calls()[0]
        self.assertIn("--no-daemon", call["args"])
        self.assertIn("--dangerously-bypass-approvals-and-sandbox", call["args"])
        self.assertEqual(call["codex_home"], str(self.codex_home))
        sandbox_home = self.home / ".local/state/codex/sandbox-home"
        self.assertEqual(call["home"], str(sandbox_home))
        self.assertFalse(list(sandbox_home.iterdir()))

    def test_darkman_changes_only_the_managed_theme(self):
        path = self.codex_home / "config.toml"
        path.write_text('model = "my-model"\n# retain comment\n[tui]\ntheme = "solarized-opencode-dark" # theme comment\n')
        result = self.run_cx(extra={"TEST_THEME": "light"})
        self.assertEqual(result.returncode, 0, result.stderr)
        data = tomllib.loads(path.read_text())
        self.assertEqual(data["model"], "my-model")
        self.assertEqual(data["tui"]["theme"], "solarized-opencode-light")
        self.assertIn("# retain comment", path.read_text())
        self.assertIn("# theme comment", path.read_text())

    def test_overlapping_sandboxes_keep_home_until_last_exit(self):
        def start(name):
            gate = self.root / name
            process = subprocess.Popen(
                [str(LAUNCHER), "--sandbox"], cwd=self.repo,
                env=self.env | {"TEST_GATE": str(gate)}, start_new_session=True,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )

            def stop():
                if process.poll() is None:
                    os.killpg(process.pid, signal.SIGTERM)
                    process.wait(timeout=5)

            self.addCleanup(stop)
            deadline = time.monotonic() + 5
            while not Path(str(gate) + ".ready").exists():
                self.assertIsNone(process.poll(), "sandbox exited before becoming ready")
                self.assertLess(time.monotonic(), deadline, "sandbox did not become ready")
                time.sleep(0.01)
            return process, gate

        first, first_gate = start("first")
        second, second_gate = start("second")
        sandbox_home = self.home / ".local/state/codex/sandbox-home"
        first_gate.touch()
        self.assertEqual(first.wait(timeout=5), 0)
        self.assertTrue((sandbox_home / ".local").is_symlink())
        self.assertTrue((sandbox_home / ".config").is_symlink())
        self.assertTrue((sandbox_home.parent / "sandbox-home-users" / str(second.pid)).exists())
        second_gate.touch()
        self.assertEqual(second.wait(timeout=5), 0)
        self.assertFalse(list(sandbox_home.iterdir()))

    def test_tmux_prompt_palette_and_tty_are_scoped_and_restored(self):
        for mode, arguments, palette in (
            ("dark", [], "fg=#839496,bg=#002b36"),
            ("light", ["--sandbox"], "fg=#657b83,bg=#fdf6e3"),
        ):
            with self.subTest(mode=mode):
                log = self.root / f"tmux-{mode}.jsonl"
                master, slave = pty.openpty()
                try:
                    result = subprocess.run(
                        [str(LAUNCHER), *arguments], cwd=self.repo,
                        env=self.env | {"TEST_THEME": mode, "TMUX_PANE": "%4242",
                                        "TEST_TMUX": str(log), "TEST_EXIT": "7"},
                        stdin=slave, stdout=slave, stderr=slave, check=False, timeout=10,
                    )
                finally:
                    os.close(master)
                    os.close(slave)
                self.assertEqual(result.returncode, 7)
                actions = [json.loads(line) for line in log.read_text().splitlines()]
                self.assertEqual(actions, [
                    ["show-options", "-pv", "-t", "%4242", "window-style"],
                    ["show-options", "-pv", "-t", "%4242", "window-active-style"],
                    ["set-option", "-p", "-t", "%4242", "window-style", palette],
                    ["set-option", "-p", "-t", "%4242", "window-active-style", palette],
                    ["set-option", "-p", "-t", "%4242", "window-style", "fg=green,bg=black"],
                    ["set-option", "-pu", "-t", "%4242", "window-active-style"],
                ])
                self.assertTrue(self.calls()[-1]["stdin_tty"])

    def test_darkman_hooks_and_invalid_toml(self):
        for mode in ("light", "dark"):
            hook = HOME / f".config/darkman/{mode}-mode.d/set-codex-theme.sh"
            result = subprocess.run([str(hook)], env=self.env, check=False, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(tomllib.loads((self.codex_home / "config.toml").read_text())["tui"]["theme"],
                             f"solarized-opencode-{mode}")
        path = self.codex_home / "config.toml"
        broken = '[tui\ntheme="bad"'
        path.write_text(broken)
        result = self.run_cx(extra={"TEST_THEME": "light"})
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(path.read_text(), broken)


class ThemeTests(unittest.TestCase):
    def test_palettes_follow_opencode_and_use_distinct_custom_names(self):
        for mode in ("dark", "light"):
            reference = json.loads((HOME / f".config/opencode/themes/solarized-{mode}.json").read_text())
            with (CONFIG / f"themes/solarized-opencode-{mode}.tmTheme").open('rb') as source:
                theme = plistlib.load(source)

            def color(role, reference=reference):
                value = reference["theme"][role]
                return reference["defs"].get(value, value)

            def scope(name, theme=theme):
                return next(entry["settings"] for entry in theme["settings"]
                            if name in [part.strip() for part in entry.get("scope", "").split(",")])

            self.assertEqual(theme["settings"][0]["settings"]["foreground"], color("text"))
            self.assertEqual(theme["settings"][0]["settings"]["background"], color("background"))
            for token, role in (("keyword", "syntaxKeyword"), ("string", "syntaxString"),
                                ("constant.numeric", "syntaxNumber"), ("support.type", "syntaxType"),
                                ("codex.accent", "primary"), ("markup.heading", "markdownHeading")):
                self.assertEqual(scope(token)["foreground"], color(role))
            self.assertEqual(scope("markup.inserted")["background"], color("diffAddedBg"))
            self.assertEqual(scope("markup.deleted")["background"], color("diffRemovedBg"))


if __name__ == "__main__":
    unittest.main()
