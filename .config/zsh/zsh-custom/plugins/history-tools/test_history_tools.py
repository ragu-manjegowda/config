"""Synthetic history fixtures only; never load or change personal histories."""

import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("history_tool", ROOT / "history-tool.py")
TOOL = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = TOOL
SPEC.loader.exec_module(TOOL)


class HistoryToolsTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="history-tools-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.exclusions = self.history("fixture-exclusions", b"l\nls\ncd\nmkdir\ntake\nrm\nrmdir\napt get\n")

    def history(self, name, content):
        path = self.root / name
        path.write_bytes(content)
        return path

    def invoke(self, *arguments):
        if arguments and arguments[0] in ("merge", "convert") and not any(
            option in arguments for option in ("--exclude-file", "--no-excludes")
        ):
            arguments = (arguments[0], "--exclude-file", str(self.exclusions), *arguments[1:])
        return subprocess.run([sys.executable, str(ROOT / "history-tool.py"), *map(str, arguments)],
                              capture_output=True, timeout=10, check=False)

    def test_mixed_merge_keeps_newest_timestamp_duration_and_leading_whitespace(self):
        zsh = self.history("zsh", b": 1700000000:3;echo duplicate\n: 1700000002:7;  echo space  \n")
        bash = self.history("bash", b"#1700000003\necho duplicate\n#1700000001\nprintf a; printf b\n")
        result = self.invoke("merge", zsh, bash)
        self.assertEqual(result.returncode, 0, result.stderr)
        merged = self.history("merged", result.stdout)
        entries = TOOL.read_history(merged, "zsh", 0)
        self.assertEqual([(e.timestamp, e.duration, e.command) for e in entries], [
            (1700000001, 0, b"printf a; printf b"),
            (1700000002, 7, b"  echo space"),
            (1700000003, 0, b"echo duplicate"),
        ])
        self.assertEqual(zsh.read_bytes(), b": 1700000000:3;echo duplicate\n: 1700000002:7;  echo space  \n")

    def test_timestamped_bash_multiline_and_unicode_roundtrip(self):
        command = "printf café 日本\n  next line".encode()
        bash = self.history("bash", b"#1700000000\n" + command + b"\n")
        result = self.invoke("convert", "--from", "bash", "--to", "zsh", bash)
        self.assertEqual(result.returncode, 0, result.stderr)
        zsh = self.history("zsh", result.stdout)
        self.assertEqual(TOOL.read_history(zsh, "zsh", 0)[0].command, command)
        result = self.invoke("convert", "--from", "zsh", "--to", "bash", zsh)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, bash.read_bytes())

    def test_zsh_continuation_can_look_like_an_extended_header(self):
        command = b"printf first\n: 1700000001:0;still inside command\nlast"
        history = self.history("zsh", TOOL.serialize([TOOL.Entry(1700000000, 3, command)], "zsh"))
        self.assertEqual(TOOL.read_history(history, "auto", 0)[0].command, command)

    def test_plain_bash_timestamp_duplicates_and_comment_commands(self):
        history = self.history("plain", b"  echo a  \n# ordinary comment\necho duplicate\necho duplicate\n")
        result = self.invoke("convert", "--from", "plain", "--to", "zsh", "--timestamp", 42, history)
        self.assertEqual(result.returncode, 0, result.stderr)
        entries = TOOL.read_history(self.history("converted", result.stdout), "zsh", 0)
        self.assertEqual([e.timestamp for e in entries], [42] * 3)
        self.assertEqual(entries[0].command, b"  echo a")
        self.assertEqual(entries[1].command, b"# ordinary comment")
        self.assertEqual(len(entries), 3, "Conversion must remove duplicate commands")

    def test_merge_and_conversion_trim_and_deduplicate_without_changing_internal_lines(self):
        entries = [
            TOOL.Entry(1700000200, 2, b"echo duplicate  "),
            TOOL.Entry(1700000300, 3, b"printf first  \n  next \t\n\n"),
            TOOL.Entry(1700000100, 4, b"  echo leading  "),
            TOOL.Entry(1700000250, 7, b"echo duplicate\t"),
            TOOL.Entry(1700000400, 0, b" \t\n"),
        ]
        source = self.history("normalize-zsh", TOOL.serialize(entries, "zsh"))
        for operation in ("merge", "convert"):
            with self.subTest(operation=operation):
                result = self.invoke(operation, "--from", "zsh", "--to", "zsh", source)
                self.assertEqual(result.returncode, 0, result.stderr)
                normalized = TOOL.read_history(self.history("normalized", result.stdout), "zsh", 0)
                expected = [
                    (1700000300, 3, b"printf first  \n  next"),
                    (1700000100, 4, b"  echo leading"),
                    (1700000250, 7, b"echo duplicate"),
                ]
                if operation == "merge":
                    expected.sort()
                self.assertEqual([(e.timestamp, e.duration, e.command) for e in normalized], expected)

    def test_non_utf8_command_bytes_and_literal_backslashes_roundtrip(self):
        commands = [b"echo \xff\x80", b"echo slash\\\\", b"printf slash\\\n  next"]
        entries = [TOOL.Entry(1700000000 + i, 0, c) for i, c in enumerate(commands)]
        history = self.history("zsh", TOOL.serialize(entries, "zsh"))
        self.assertEqual([e.command for e in TOOL.read_history(history, "zsh", 0)], commands)

    def test_output_can_equal_input_without_losing_records(self):
        history = self.history("same", b": 1700000000:0;echo old\n: 1700000001:0;echo old\n")
        result = self.invoke("merge", history, "--output", history)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(history.read_bytes(), b": 1700000001:0;echo old\n")
        self.assertEqual(history.stat().st_mode & 0o777, 0o600)
        self.assertFalse(list(self.root.glob(".same.*")))

    def test_failures_preserve_existing_output(self):
        output = self.history("output", b"keep this output\n")
        bad = self.history("bad", b": 1700000000:0;valid\nnot a zsh record\n")
        for path in (bad, self.root / "missing", self.history("encrypted", b"-----BEGIN PGP MESSAGE-----\n")):
            with self.subTest(path=path.name):
                result = self.invoke("merge", "--from", "zsh", path, "--output", output)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(output.read_bytes(), b"keep this output\n")

    def test_plain_bash_output_and_help(self):
        history = self.history("zsh", b": 1700000000:4;echo hello\n")
        result = self.invoke("convert", "--to", "bash", "--plain", history)
        self.assertEqual(result.stdout, b"echo hello\n")
        for args in (("--help",), ("merge", "--help"), ("convert", "--help")):
            result = self.invoke(*args)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(b"usage:", result.stdout.lower())

    def test_plugin_paths_literal_arguments_empty_backup_glob_and_help(self):
        home = self.root / "home with spaces"
        home.mkdir()
        plugin = self.root / "plugin with spaces"
        plugin.mkdir()
        for name in ("history-tools.plugin.zsh", "history-tool.py"):
            shutil.copyfile(ROOT / name, plugin / name)
        shutil.copyfile(self.exclusions, plugin / "ignored-commands.txt")
        current = home / ".zsh_history"
        current.write_bytes(b": 1700000000:0;echo current\n")
        extra = self.history("history $(touch SHOULD_NOT_EXIST)", b"#1700000001\necho extra\n")
        env = dict(os.environ, HOME=str(home), ZDOTDIR=str(home), PLUGIN=str(plugin / "history-tools.plugin.zsh"),
                   EXTRA=str(extra))
        for command in ("merge-curr-zsh-history", 'merge-zsh-history "$EXTRA"'):
            result = subprocess.run(["zsh", "-f", "-c", 'source "$PLUGIN"; ' + command],
                                    cwd=home, env=env, capture_output=True, timeout=10, check=False)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(b"echo current", (home / "zsh_history_merged").read_bytes())
        self.assertIn(b"echo extra", (home / "zsh_history_merged").read_bytes())
        self.assertFalse((home / "SHOULD_NOT_EXIST").exists())
        for command in ("history-tools", "merge-curr-zsh-history", "merge-zsh-history",
                        "bash-to-zsh-history", "zsh-to-bash-history"):
            result = subprocess.run(["zsh", "-f", "-c", 'source "$PLUGIN"; ' + command + ' --help'],
                                    env=env, capture_output=True, timeout=10, check=False)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(b"usage:", result.stdout.lower())

    def test_merge_wrapper_help_is_specific_and_never_invokes_python_or_history_io(self):
        home = self.root / "help home"
        home.mkdir()
        binary = self.root / "bin"
        binary.mkdir()
        marker = self.root / "python-called"
        python = binary / "python3"
        python.write_text('#!/bin/sh\n: > "$PYTHON_CALLED"\nexit 77\n')
        python.chmod(0o755)
        env = dict(os.environ, HOME=str(home), ZDOTDIR=str(home / "nonexistent history directory"),
                   PATH=str(binary) + os.pathsep + os.environ["PATH"], PYTHON_CALLED=str(marker),
                   PLUGIN=str(ROOT / "history-tools.plugin.zsh"))
        for command in ("merge-zsh-history", "merge-curr-zsh-history"):
            for arguments in ("-h", "--help", '-o "$HOME/alternate_output" --help'):
                with self.subTest(command=command, arguments=arguments):
                    result = subprocess.run(["zsh", "-f", "-c", 'source "$PLUGIN"; ' + command + ' ' + arguments],
                                            env=env, capture_output=True, timeout=10, check=False)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertIn(f"Usage: {command}".encode(), result.stdout)
                    self.assertIn(b"~/zsh_history_merged", result.stdout)
                    self.assertIn(b"$ZDOTDIR/.zsh_history", result.stdout)
                    self.assertIn(b"history-tools convert --help", result.stdout)
                    if command == "merge-curr-zsh-history":
                        self.assertIn(b".zsh_history_*.bak", result.stdout)
                    self.assertFalse(marker.exists(), "Wrapper help must not invoke Python")
                    self.assertEqual(list(home.iterdir()), [], "Wrapper help must not create history output")

    def test_help_named_input_after_option_terminator_is_merged_as_a_file(self):
        home = self.root / "literal home"
        home.mkdir()
        (home / ".zsh_history").write_bytes(b": 1700000000:0;echo current\n")
        (home / "--help").write_bytes(b"#1700000001\necho literal input\n")
        env = dict(os.environ, HOME=str(home), ZDOTDIR=str(home),
                   PLUGIN=str(ROOT / "history-tools.plugin.zsh"), EXCLUSIONS=str(self.exclusions))
        result = subprocess.run(["zsh", "-f", "-c", 'source "$PLUGIN"; merge-zsh-history --exclude-file "$EXCLUSIONS" -- --help'],
                                cwd=home, env=env, capture_output=True, timeout=10, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(b"echo literal input", (home / "zsh_history_merged").read_bytes())

    def test_output_is_accepted_by_native_zsh_history_reader(self):
        commands = ["echo café 日本".encode(), b"printf a\n  b", b"echo slash\\\\",
                    b"printf a\n: 1700000001:0;header-like body"]
        source = self.history("source", TOOL.serialize([TOOL.Entry(1700000000 + i, 0, c)
                                                       for i, c in enumerate(commands)], "zsh"))
        output = self.root / "native"
        env = dict(os.environ, HOME=str(self.root), ZDOTDIR=str(self.root))
        script = 'fc -p "$2" 100 100; setopt EXTENDED_HISTORY; fc -R "$1"; fc -W "$2"'
        result = subprocess.run(["zsh", "-f", "-i", "-c", script, "zsh", str(source), str(output)],
                                env=env, capture_output=True, timeout=10, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([e.command for e in TOOL.read_history(output, "zsh", 0)], commands)

    def test_output_is_accepted_by_native_bash_history_reader(self):
        commands = ["echo café 日本".encode(), b"printf a\n  b", b"  echo trailing  "]
        source = self.history("bash-source", TOOL.serialize([TOOL.Entry(1700000000 + i, 0, c)
                                                            for i, c in enumerate(commands)], "bash"))
        output = self.root / "bash-native"
        script = 'HISTSIZE=100; HISTFILESIZE=100; HISTTIMEFORMAT="%s "; history -c; history -r "$1"; history -w "$2"'
        result = subprocess.run(["bash", "--noprofile", "--norc", "-c", script, "bash", str(source), str(output)],
                                env=dict(os.environ, HOME=str(self.root)), capture_output=True,
                                timeout=10, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        entries = TOOL.read_history(output, "bash", 0)
        self.assertEqual([e.command for e in entries], commands)
        self.assertEqual([e.timestamp for e in entries], [1700000000 + i for i in range(len(commands))])

    def test_exclusions_apply_to_merge_and_conversion_by_command_name(self):
        commands = [b"l", b"ls -la", b"cd /tmp", b"mkdir 'directory with spaces'", b"take work",
                    b"rm -f file", b"rmdir old", b"echo ls", b"lsblk", b"git status",
                    b"command ls /tmp", b"builtin cd /tmp", b"/usr/bin/ls /tmp", b"LC_ALL=C ls"]
        source = self.history("exclude-zsh", TOOL.serialize([TOOL.Entry(1700000000 + i, 0, c)
                                                            for i, c in enumerate(commands)], "zsh"))
        for operation in ("merge", "convert"):
            with self.subTest(operation=operation):
                result = self.invoke(operation, "--to", "bash", source)
                self.assertEqual(result.returncode, 0, result.stderr)
                entries = TOOL.read_history(self.history("filtered", result.stdout), "bash", 0)
                self.assertEqual([e.command for e in entries], [b"echo ls", b"lsblk", b"git status"])

    def test_exclusions_preserve_compound_multiline_and_ambiguous_commands(self):
        commands = [b"cd project && git pull", b"ls; git status", b"ls | grep name", b"ls &",
                    b"ls\necho next", b"ls $(printf folder)", b"ls 'unclosed", b"command -v ls"]
        exclusions = TOOL.read_exclusions(self.exclusions)
        self.assertTrue(all(not TOOL.is_excluded(command, exclusions) for command in commands))

    def test_exclusion_list_can_be_extended_overridden_or_disabled(self):
        source = self.history("plain-exclude", b"pwd\nls -l\necho retained\n")
        custom = self.history("custom-list", b"# Future additions\n\npwd\n")
        result = self.invoke("convert", "--from", "plain", "--to", "bash", "--plain",
                             "--exclude-file", custom, source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, b"ls -l\necho retained\n")
        result = self.invoke("convert", "--from", "plain", "--to", "bash", "--plain",
                             "--no-excludes", source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, source.read_bytes())

    def test_invalid_or_missing_exclusion_file_preserves_output(self):
        source = self.history("source-list-error", b"echo keep\n")
        output = self.history("list-error-output", b"previous output\n")
        invalid = self.history("invalid-list", b"'unclosed phrase\n")
        for exclusion in (invalid, self.root / "missing-list"):
            result = self.invoke("merge", "--exclude-file", exclusion, source, "-o", output)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(output.read_bytes(), b"previous output\n")

    def test_multiword_exclusions_under_common_prefixes_do_not_match_argument_text(self):
        patterns = TOOL.read_exclusions(self.exclusions)
        excluded = [b"apt get update", b"sudo apt get update", b"sudo -u root apt get update",
                    b"sudo --user=root -- apt get update", b"LC_ALL=C sudo -n apt get update",
                    b"env -u LANG LC_ALL=C apt get update", b"command -p apt get update",
                    b"time -o timing.log sudo apt get update", b"noglob apt get update"]
        retained = [b"echo apt get update", b'echo "apt get update"', b"apt getter update",
                    b"sudo -u apt get echo", b"command -v apt", b"sudo -l apt get update",
                    b"env -S 'apt get update'", b"apt get update && git status"]
        self.assertTrue(all(TOOL.is_excluded(command, patterns) for command in excluded))
        self.assertTrue(all(not TOOL.is_excluded(command, patterns) for command in retained))
        self.assertTrue(TOOL.is_excluded(b"sudo apt get update", {("sudo", "apt", "get")}))
        custom = self.history("multiword-list", b"apt get # package-manager operations\ngit status\n")
        source = self.history("multiword-source", b"sudo apt get update\ngit status --short\necho apt get\n")
        result = self.invoke("convert", "--from", "plain", "--to", "bash", "--plain",
                             "--exclude-file", custom, source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, b"echo apt get\n")

    def test_default_sibling_exclusion_file_is_read_on_each_invocation(self):
        script = self.root / "history-tool.py"
        shutil.copyfile(ROOT / "history-tool.py", script)
        config = self.history("ignored-commands.txt", b"ls\n")
        source = self.history("sibling-list-input", b"ls -l\ngit status\necho retained\n")
        command = [sys.executable, str(script), "convert", "--from", "plain", "--to", "bash", "--plain", str(source)]
        result = subprocess.run(command, capture_output=True, timeout=10, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, b"git status\necho retained\n")
        config.write_bytes(b"ls\ngit status\n")
        result = subprocess.run(command, capture_output=True, timeout=10, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, b"echo retained\n")


if __name__ == "__main__":
    unittest.main()
