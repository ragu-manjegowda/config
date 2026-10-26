"""Exercise real interactive Zsh history hooks using only temporary histories."""

import importlib.util
import os
import pty
import select
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
UPSTREAM = ROOT.parents[2] / "oh-my-zsh/plugins/per-directory-history/per-directory-history.plugin.zsh"
DIRECTORY_PLUGIN = ROOT.parent / "per-directory-history/per-directory-history.plugin.zsh"
SPEC = importlib.util.spec_from_file_location("live_history_tool", ROOT / "history-tool.py")
TOOL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = TOOL
SPEC.loader.exec_module(TOOL)


@unittest.skipUnless(shutil.which("zsh"), "Interactive history tests require Zsh")
class LiveHistoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="live history ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / "project A"
        self.other = self.root / "project B"
        self.project.mkdir()
        self.other.mkdir()
        self.plugin = self.root / "history-tools"
        self.plugin.mkdir()
        for name in ("history-tools.plugin.zsh", "history-tool.py"):
            shutil.copy2(ROOT / name, self.plugin / name)
        self.exclusions = self.plugin / "ignored-commands.txt"
        self.exclusions.write_text("ls\nll\ncd\ngit diff\nprint -r -- SKIP\n")
        self.vendor = self.root / "vendor"
        upstream = self.vendor / "plugins/per-directory-history/per-directory-history.plugin.zsh"
        upstream.parent.mkdir(parents=True)
        shutil.copy2(UPSTREAM, upstream)
        self.global_file = self.root / "global-history"
        self.global_file.touch()
        self.base = self.root / "directory-histories"
        (self.root / ".zshrc").write_text(f"""
PROMPT=''
PROMPT2=''
RPROMPT=''
HISTFILE={shlex.quote(str(self.global_file))}
HISTSIZE=1000
SAVEHIST=1000
HISTORY_BASE={shlex.quote(str(self.base))}
HISTORY_START_WITH_GLOBAL=${{HISTORY_TEST_START_GLOBAL:-false}}
PER_DIRECTORY_HISTORY_PRINT_MODE_CHANGE=false
ZSH={shlex.quote(str(self.vendor))}
setopt EXTENDED_HISTORY INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_SPACE
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS
source {shlex.quote(str(self.plugin / 'history-tools.plugin.zsh'))}
source {shlex.quote(str(DIRECTORY_PLUGIN))}
alias ll='ls -l'
""")

    def shell(self, commands, global_mode=False):
        environment = os.environ | {
            "HOME": str(self.root), "ZDOTDIR": str(self.root), "TERM": "xterm-256color",
            "HISTORY_TEST_START_GLOBAL": "true" if global_mode else "false",
        }
        pid, master = pty.fork()
        if pid == 0:
            try:
                os.chdir(self.project)
                os.execvpe("zsh", ["zsh", "-d", "-i"], environment)
            finally:
                os._exit(127)
        transcript = b""
        status = None
        try:
            os.write(master, ("\n".join(commands) + "\nexit 0\n").encode())
            deadline = time.monotonic() + 15
            while status is None:
                completed, value = os.waitpid(pid, os.WNOHANG)
                if completed:
                    status = value
                    break
                if time.monotonic() > deadline:
                    self.fail("Synthetic interactive shell timed out")
                if select.select([master], [], [], 0.1)[0]:
                    try:
                        transcript += os.read(master, 65536)
                    except OSError:
                        continue
            result = os.waitstatus_to_exitcode(status)
            self.assertEqual(result, 0, transcript.decode(errors="replace"))
        finally:
            os.close(master)
            if status is None:
                try:
                    os.killpg(pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                os.waitpid(pid, 0)
        return subprocess.CompletedProcess(["zsh", "-d", "-i"], result, transcript.decode(errors="replace"), "")

    def records(self, path):
        return [entry.command.decode() for entry in TOOL.read_history(path, "zsh", 0)]

    def local_file(self, directory):
        return self.base / str(directory).lstrip("/") / "history"

    def check_filtering(self, global_mode):
        self.shell([
            "print -r -- KEEP_ONE",
            "history_fixture_command_does_not_exist",
            "ls >/dev/null",
            "command ls >/dev/null",
            "ll >/dev/null",
            "git diff >/dev/null",
            "print -r -- SKIP payload",
            " print -r -- HIDDEN_BY_LEADING_SPACE",
            "ls >/dev/null; print -r -- KEEP_COMPOUND",
            "false",
            "print -r -- KEEP_LAST",
        ], global_mode=global_mode)
        for path in (self.global_file, self.local_file(self.project)):
            records = self.records(path)
            for command in ("print -r -- KEEP_ONE", "print -r -- KEEP_LAST", "false",
                            "ls >/dev/null; print -r -- KEEP_COMPOUND"):
                self.assertIn(command, records, path)
            for rejected in ("history_fixture_command_does_not_exist", "ls >/dev/null",
                             "command ls >/dev/null", "ll >/dev/null",
                             "git diff >/dev/null", "print -r -- SKIP payload",
                             " print -r -- HIDDEN_BY_LEADING_SPACE"):
                self.assertNotIn(rejected, records, path)

    def test_directory_search_mode_uses_global_acceptance(self):
        self.check_filtering(False)

    def test_global_search_mode_still_filters_both_files(self):
        self.check_filtering(True)

    def test_existing_directory_history_still_updates_global_history(self):
        path = self.local_file(self.project)
        path.parent.mkdir(parents=True)
        path.touch()
        self.check_filtering(False)

    def test_runtime_history_toggle_keeps_the_same_filter(self):
        commands = ["print -r -- KEEP_LOCAL", "print -r -- KEEP_GLOBAL",
                    "print -r -- KEEP_LOCAL_AGAIN"]
        self.shell([
            commands[0], "per-directory-history-toggle-history",
            commands[1], "per-directory-history-toggle-history", commands[2],
            "ls >/dev/null", "history_fixture_command_does_not_exist",
        ])
        for path in (self.global_file, self.local_file(self.project)):
            records = self.records(path)
            for command in commands:
                self.assertIn(command, records)
            self.assertNotIn("ls >/dev/null", records)
            self.assertNotIn("history_fixture_command_does_not_exist", records)

    def test_consecutive_duplicates_respect_history_options(self):
        command = "print -r -- KEEP_DUPLICATE_ONCE"
        self.shell([command, command, "print -r -- KEEP_LAST"])
        for path in (self.global_file, self.local_file(self.project)):
            self.assertEqual(self.records(path).count(command), 1, path)

    def test_directory_hook_reuses_the_global_decision_once_per_command(self):
        counter = self.root / "filter-count"
        startup = self.root / ".zshrc"
        startup.write_text(startup.read_text() + f'''
functions[_history_fixture_accept]="$functions[_history_tools_accept_line]"
_history_tools_accept_line() {{
    builtin print -r -- checked >> {shlex.quote(str(counter))}
    _history_fixture_accept "$@"
}}
''')
        self.shell(["print -r -- KEEP_ONE", "ls >/dev/null",
                    "history_fixture_command_does_not_exist", "print -r -- KEEP_LAST"])
        self.assertEqual(counter.read_text().splitlines(), ["checked"] * 5)

    def test_appending_does_not_replace_existing_inactive_history(self):
        local_file = self.local_file(self.project)
        local_file.parent.mkdir(parents=True)
        local_file.touch()
        entries = [TOOL.Entry(1700000000 + index, 0, f"print OLD_{index}".encode())
                   for index in range(10)]
        self.global_file.write_bytes(TOOL.serialize(entries, "zsh"))
        startup = self.root / ".zshrc"
        startup.write_text(startup.read_text().replace("SAVEHIST=1000", "SAVEHIST=5"))
        self.shell(["print -r -- KEEP_NEW"])
        records = self.records(self.global_file)
        self.assertGreaterEqual(len(records), 5, records)
        self.assertTrue(any(command.startswith("print OLD_") for command in records), records)

    def test_directory_changes_keep_allowed_entries_in_their_own_directory(self):
        change = f"cd {shlex.quote(str(self.other))}"
        self.shell([
            "print -r -- KEEP_PROJECT_A",
            change,
            "print -r -- KEEP_PROJECT_B",
        ])
        self.assertIn("print -r -- KEEP_PROJECT_A", self.records(self.local_file(self.project)))
        self.assertIn("print -r -- KEEP_PROJECT_B", self.records(self.local_file(self.other)))
        self.assertNotIn("print -r -- KEEP_PROJECT_A", self.records(self.local_file(self.other)))
        self.assertIn("print -r -- KEEP_PROJECT_A", self.records(self.global_file))
        self.assertIn("print -r -- KEEP_PROJECT_B", self.records(self.global_file))
        for path in (self.global_file, self.local_file(self.project), self.local_file(self.other)):
            self.assertNotIn(change, self.records(path))

    def test_multiline_commands_are_not_flattened_or_excluded(self):
        command = "print -r -- 'café 日本\nsecond line'"
        self.shell([command, "print -r -- KEEP_LAST"])
        for path in (self.global_file, self.local_file(self.project)):
            self.assertIn(command, self.records(path))

    def test_assignments_are_not_mistaken_for_unknown_commands(self):
        keep = "HISTORY_FIXTURE_VALUE=ok /usr/bin/printf 'KEEP_ASSIGNMENT\\n'"
        assignment = "HISTORY_FIXTURE_VALUE='two words'"
        self.shell([
            keep, assignment, "HISTORY_FIXTURE_VALUE=ok ls >/dev/null",
            "HISTORY_FIXTURE_VALUE=ok history_fixture_command_does_not_exist",
            "print -r -- KEEP_LAST",
        ])
        for path in (self.global_file, self.local_file(self.project)):
            records = self.records(path)
            self.assertIn(keep, records)
            self.assertIn(assignment, records)
            self.assertNotIn("HISTORY_FIXTURE_VALUE=ok ls >/dev/null", records)
            self.assertNotIn("HISTORY_FIXTURE_VALUE=ok history_fixture_command_does_not_exist", records)

    def test_future_global_rules_are_consulted_without_copying_them(self):
        self.shell([
            "zshaddhistory() { [[ $1 != *REJECT_BY_GLOBAL_RULE* ]]; }",
            "print -r -- REJECT_BY_GLOBAL_RULE",
            "print -r -- KEEP_LAST",
        ])
        for path in (self.global_file, self.local_file(self.project)):
            records = self.records(path)
            self.assertNotIn("print -r -- REJECT_BY_GLOBAL_RULE", records)
            self.assertIn("print -r -- KEEP_LAST", records)

    def test_exclusion_changes_apply_without_restarting_the_shell(self):
        command = "print -r -- DYNAMIC_RULE"
        self.shell([
            command,
            f"print -r -- {shlex.quote(command)} >> {shlex.quote(str(self.exclusions))}",
            command,
            "print -r -- KEEP_LAST",
        ])
        for path in (self.global_file, self.local_file(self.project)):
            self.assertEqual(self.records(path).count(command), 1, path)

    def test_concurrent_shells_keep_entries_in_both_histories(self):
        processes = []
        commands = [f"print -r -- PARALLEL_{shell}_{index}"
                    for shell in ("A", "B") for index in range(8)]
        try:
            for shell in ("A", "B"):
                process = subprocess.Popen(
                    ["zsh", "-d", "-i"], cwd=self.project,
                    env=os.environ | {"HOME": str(self.root), "ZDOTDIR": str(self.root),
                                      "HISTORY_TEST_START_GLOBAL": "true"},
                    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                    text=True,
                )
                processes.append(process)
            for process, shell in zip(processes, ("A", "B")):
                process.stdin.write("\n".join(command for command in commands
                                             if f"PARALLEL_{shell}_" in command) + "\nexit 0\n")
                process.stdin.flush()
            for process in processes:
                _, stderr = process.communicate(timeout=20)
                self.assertEqual(process.returncode, 0, stderr)
            for path in (self.global_file, self.local_file(self.project)):
                records = self.records(path)
                for command in commands:
                    self.assertIn(command, records, path)
        finally:
            for process in processes:
                if process.poll() is None:
                    process.kill()
                    process.communicate(timeout=5)


if __name__ == "__main__":
    unittest.main()
