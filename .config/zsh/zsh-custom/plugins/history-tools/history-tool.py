#!/usr/bin/env python3
"""Merge and convert shell history without executing commands or editing inputs."""

import argparse
import os
import re
import shlex
import sys
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path

ZSH_HEADER = re.compile(rb"^:\s*(\d+):(\d+);(.*)$")
BASH_HEADER = re.compile(rb"^#(\d+)$")
DEFAULT_EXCLUDE_FILE = Path(__file__).resolve().with_name("ignored-commands.txt")


@dataclass(frozen=True)
class Entry:
    timestamp: int
    duration: int
    command: bytes


def unmetafy(command):
    """Undo Zsh's Meta-byte escaping, including non-ASCII history bytes."""
    result = bytearray()
    index = 0
    while index < len(command):
        if command[index] == 0x83:
            if index + 1 == len(command):
                raise ValueError("incomplete Zsh Meta escape")
            result.append(command[index + 1] ^ 0x20)
            index += 2
        else:
            result.append(command[index])
            index += 1
    return bytes(result)


def metafy(command):
    return b"".join(bytes((0x83, byte ^ 0x20)) if byte >= 0x80 else bytes((byte,))
                    for byte in command)


def parse_zsh(lines):
    entries = []
    index = 0
    while index < len(lines):
        if not lines[index]:
            index += 1
            continue
        header = ZSH_HEADER.fullmatch(lines[index])
        if not header:
            raise ValueError(f"invalid extended Zsh record at line {index + 1}")
        command = header[3]
        while command.endswith(b"\\"):
            index += 1
            if index == len(lines):
                raise ValueError("unfinished Zsh multiline record")
            command = command[:-1] + b"\n" + lines[index]
        # Zsh appends a space to a record ending in a literal backslash.
        if command.endswith(b"\\ "):
            command = command[:-1]
        if command:
            entries.append(Entry(int(header[1]), int(header[2]), unmetafy(command)))
        index += 1
    return entries


def parse_bash(lines, timestamp):
    if not any(BASH_HEADER.fullmatch(line) for line in lines):
        return [Entry(timestamp, 0, line) for line in lines if line]
    entries, command = [], []
    current = None
    for line in lines:
        header = BASH_HEADER.fullmatch(line)
        if header:
            if command:
                entries.append(Entry(current, 0, b"\n".join(command)))
            current, command = int(header[1]), []
        elif current is None:
            if line:
                entries.append(Entry(timestamp, 0, line))
        else:
            command.append(line)
    if command:
        entries.append(Entry(current, 0, b"\n".join(command)))
    return entries


def read_history(path, input_format, timestamp):
    content = path.read_bytes()
    if content.startswith((b"-----BEGIN PGP MESSAGE-----", b"\0GITCRYPT")) or b"\0" in content:
        raise ValueError(f"{path}: input is encrypted or binary; supply plaintext history")
    lines = content.split(b"\n")
    if lines[-1] == b"":
        lines.pop()
    if input_format == "auto":
        input_format = "zsh" if any(ZSH_HEADER.fullmatch(line) for line in lines) else "bash"
    try:
        if input_format == "zsh":
            return parse_zsh(lines)
        if input_format == "plain":
            return [Entry(timestamp, 0, line) for line in lines if line]
        return parse_bash(lines, timestamp)
    except ValueError as error:
        raise ValueError(f"{path}: {error}") from error


def read_exclusions(path):
    patterns = set()
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        name = line.strip()
        if not name or name.startswith("#"):
            continue
        try:
            words = shlex.split(name, comments=True)
        except ValueError as error:
            raise ValueError(f"{path}: line {number}: invalid command phrase") from error
        if words:
            patterns.add(tuple(words))
    return patterns


def unwrap_command(words):
    value_options = {
        "sudo": {"-u", "--user", "-g", "--group", "-h", "--host", "-p", "--prompt",
                 "-C", "--close-from", "-T", "--command-timeout", "-r", "--role", "-t", "--type"},
        "env": {"-u", "--unset", "-C", "--chdir", "--argv0"},
        "time": {"-o", "--output", "-f", "--format"},
    }
    while words:
        if re.match(r"^[A-Za-z_][A-Za-z_0-9]*=", words[0]):
            words.pop(0)
            continue
        prefix = Path(words[0]).name
        if prefix in ("noglob", "nocorrect"):
            words.pop(0)
            continue
        if prefix not in ("command", "builtin", "sudo", "env", "time"):
            break
        words.pop(0)
        while words and words[0].startswith("-"):
            option = words.pop(0)
            if option == "--":
                break
            if (prefix == "command" and option in ("-v", "-V")) or (
                prefix == "env" and (option in ("-S", "--split-string") or option.startswith("--split-string="))
            ) or (prefix == "sudo" and option in ("-l", "--list", "-v", "--validate")):
                return []
            if option in value_options.get(prefix, set()):
                if not words:
                    return []
                words.pop(0)
    return words


def matches_exclusion(words, patterns):
    return bool(words) and any(
        len(words) >= len(pattern) and (words[0] == pattern[0] or Path(words[0]).name == pattern[0])
        and tuple(words[1:len(pattern)]) == pattern[1:] for pattern in patterns)


def is_excluded(command, patterns):
    # Be conservative: preserve compound commands, substitutions, and multiline
    # entries instead of discarding useful work after a routine first command.
    if not patterns or b"\n" in command or any(byte in command for byte in b";|&`()"):
        return False
    try:
        words = shlex.split(command.decode("utf-8", "surrogateescape"))
    except ValueError:
        return False
    while words and re.match(r"^[A-Za-z_][A-Za-z_0-9]*=", words[0]):
        words.pop(0)
    return matches_exclusion(words, patterns) or matches_exclusion(unwrap_command(words), patterns)


def normalize(entries, chronological=False, exclusions=None):
    newest = {}
    for index, entry in enumerate(entries):
        command = entry.command.rstrip()
        if not command or is_excluded(command, exclusions):
            continue
        entry = Entry(entry.timestamp, entry.duration, command)
        previous = newest.get(command)
        if previous is None or entry.timestamp >= previous[1].timestamp:
            newest[command] = (index, entry)
    key = (lambda item: (item[1].timestamp, item[0])) if chronological else (lambda item: item[0])
    return [entry for _, entry in sorted(newest.values(), key=key)]


def serialize(entries, output_format, plain=False):
    records = []
    for entry in entries:
        if output_format == "zsh":
            command = metafy(entry.command).replace(b"\n", b"\\\n")
            if command.endswith(b"\\"):
                command += b" "
            records.append(f": {entry.timestamp}:{entry.duration};".encode() + command + b"\n")
        else:
            prefix = b"" if plain else f"#{entry.timestamp}\n".encode()
            records.append(prefix + entry.command + b"\n")
    return b"".join(records)


def write_output(output, content):
    if output is None:
        sys.stdout.buffer.write(content)
        return
    fd, name = tempfile.mkstemp(prefix=f".{output.name}.", dir=output.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(content)
        os.replace(name, output)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="history-tools",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description="Merge or convert Zsh, timestamped Bash, and plain Bash history.\n"
                    "Both operations trim trailing command whitespace and keep the newest duplicate.\n"
                    "Command-name phrases are filtered using ignored-commands.txt beside this helper.\n"
                    "No commands are executed.",
        epilog="Examples:\n"
               "  history-tools merge zsh_history bash_history -o merged\n"
               "  history-tools convert --from bash --to zsh bash_history\n"
               "  history-tools convert --from zsh --to bash zsh_history",
    )
    subparsers = parser.add_subparsers(dest="operation", required=True)
    for operation in ("merge", "convert"):
        command = subparsers.add_parser(
            operation,
            help="Deduplicate histories by newest timestamp" if operation == "merge" else "Convert history formats",
            description=("Read all inputs before writing output. Both operations trim trailing whitespace from each complete "
                         "command and keep its newest occurrence. Internal whitespace and multiline indentation are preserved. "
                         "Merge sorts chronologically; conversion preserves the relative input order of retained entries. "
                         "Zsh durations are retained where the destination format supports them."),
            epilog="Plain histories have no reliable multiline boundaries or timestamps. "
                   "Each physical line becomes a command with the import timestamp. "
                   "Use --from to override ambiguous automatic format detection.",
        )
        command.add_argument("--from", "--input-format", dest="input_format", default="auto",
                             choices=("auto", "zsh", "bash", "plain"),
                             help="Input format; auto detects extended Zsh or Bash separately for each file (default: auto)")
        command.add_argument("--to", dest="output_format", choices=("zsh", "bash"),
                             default="zsh" if operation == "merge" else None,
                             required=operation == "convert", help="Output format (merge default: zsh)")
        command.add_argument("-o", "--output", type=Path,
                             help="Atomically replace this file only after successful parsing; default: stdout")
        command.add_argument("--timestamp", type=int, default=int(time.time()), metavar="EPOCH",
                             help="Fallback timestamp for untimestamped entries (default: current import time)")
        command.add_argument("--plain", action="store_true",
                             help="Omit timestamps in Bash output; multiline record boundaries will be lost")
        exclusions = command.add_mutually_exclusive_group()
        exclusions.add_argument("--exclude-file", type=Path, default=DEFAULT_EXCLUDE_FILE, metavar="PATH",
                                help="Read excluded command phrases from PATH (default: ignored-commands.txt beside helper)")
        exclusions.add_argument("--no-excludes", action="store_true",
                                help="Keep routine commands instead of applying the exclusion list")
        command.add_argument("files", type=Path, nargs="+", metavar="HISTORY",
                             help="History files to read; inputs may mix Bash and Zsh in auto mode")
    args = parser.parse_args(argv)
    if args.timestamp < 0:
        parser.error("--timestamp must be nonnegative")
    if args.plain and args.output_format != "bash":
        parser.error("--plain requires --to bash")
    try:
        exclusions = set() if args.no_excludes else read_exclusions(args.exclude_file)
        entries = [entry for path in args.files for entry in read_history(path, args.input_format, args.timestamp)]
        entries = normalize(entries, chronological=args.operation == "merge", exclusions=exclusions)
        write_output(args.output, serialize(entries, args.output_format, args.plain))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
