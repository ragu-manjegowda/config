#!/usr/bin/env python3
"""Pass a displayed message through while saving sender and recipient aliases."""

import fcntl
import os
import re
import stat
import sys
import tempfile
import time
from email.utils import getaddresses, parseaddr
from pathlib import Path


def message_contacts(message: str) -> list[tuple[str, str]]:
    lines = message.splitlines()
    contacts = []
    in_headers = False
    for index, line in enumerate(lines):
        # NeoMutt may prefix displayed headers with its MIME/PGP escape marker.
        line = re.sub(r"\x1b]9;[0-9]+\x07", "", line)
        if not line.strip() and in_headers:
            break
        if re.match(r"^[A-Za-z][A-Za-z0-9-]*:", line):
            in_headers = True
        match = re.match(r"^(?:From|To):\s*(.*)$", line, re.IGNORECASE)
        if match is None:
            continue
        header = match.group(1)
        for continuation in lines[index + 1 :]:
            if not continuation.startswith((" ", "\t")):
                break
            header += " " + continuation.strip()
        # The HTML mail viewer may insert reference numbers like [6].
        header = re.sub(r"\[[0-9]+\]", "", header)
        for name, address in getaddresses([header]):
            parsed = contact(name, address)
            if parsed is not None:
                contacts.append(parsed)
    return contacts


def contact(name: str, address: str) -> tuple[str, str] | None:
    name = re.sub(r"[\x00-\x1f\x7f\"',]", "", name).strip()
    address = address.strip().casefold()
    if not re.fullmatch(r"[^<>\s@]+@[^<>\s@]+", address):
        return None

    localpart, domain = address.rsplit("@", 1)
    compact_localpart = re.sub(r"[^a-z0-9]", "", localpart)
    compact_name = re.sub(r"[^a-z0-9]", "", name.casefold())
    automated = ("noreply", "donotreply", "dontreply", "autoreply", "mailerdaemon")
    blocked_domains = (
        "facebook.com", "facebookmail.com", "twitter.com", "twittermail.com",
        "amazon.com", "amazonses.com", "amazonaws.com", "paypal.com", "slack.com",
    )
    if (
        compact_localpart.startswith(automated)
        or any(token in compact_name for token in automated)
        or any(domain == blocked or domain.endswith("." + blocked)
               for blocked in blocked_domains)
        or "gerrit" in localpart or "gerrit" in domain
        or "slack" in localpart
        or address in {"ops@exoscale.ch", "gitlab@gitlab-master"}
    ):
        return None
    return name, address


def own_addresses(path: Path) -> set[str]:
    try:
        identities = (path.parent / "notmuch-identities").read_bytes()
    except OSError:
        return set()
    if identities.startswith(b"\0GITCRYPT\0"):
        return set()
    addresses = set()
    for line in identities.decode("utf-8", errors="replace").splitlines():
        _, separator, address = line.partition("|")
        if separator and address.strip():
            addresses.add(address.strip().casefold())
    return addresses


def saved_aliases(contents: bytes) -> tuple[set[str], set[str]]:
    keys = set()
    addresses = set()
    for line in contents.decode("utf-8", errors="replace").splitlines():
        fields = line.split(maxsplit=2)
        if len(fields) < 3 or fields[0].casefold() != "alias":
            continue
        keys.add(fields[1].casefold())
        _, address = parseaddr(fields[2])
        if address:
            addresses.add(address.casefold())
    return keys, addresses


def alias_key(address: str, keys: set[str]) -> str:
    # Addresses distinguish people with the same display name.
    localpart, domain = address.rsplit("@", 1)
    base = re.sub(r"[^a-z0-9._+-]+", "-", localpart).strip("-") or "contact"
    if base.casefold() not in keys:
        return base

    domain = re.sub(r"[^a-z0-9._+-]+", "-", domain).strip("-")
    candidate = f"{base}-{domain}"
    key = candidate
    number = 2
    while key.casefold() in keys:
        key = f"{candidate}-{number}"
        number += 1
    return key


def sorted_aliases(contents: bytes) -> bytes:
    if contents and not contents.endswith(b"\n"):
        contents += b"\n"
    lines = contents.splitlines(keepends=True)
    aliases = []
    for line in lines:
        fields = line.decode("utf-8", errors="replace").split(maxsplit=2)
        if len(fields) >= 3 and fields[0].casefold() == "alias":
            aliases.append(line)

    def name_key(line: bytes) -> tuple[str, str, str]:
        fields = line.decode("utf-8", errors="replace").split(maxsplit=2)
        name, address = parseaddr(fields[2])
        return ((name or address).casefold(), address.casefold(), fields[1].casefold())

    ordered = iter(sorted(aliases, key=name_key))
    result = []
    for line in lines:
        fields = line.decode("utf-8", errors="replace").split(maxsplit=2)
        if len(fields) >= 3 and fields[0].casefold() == "alias":
            result.append(next(ordered))
        else:
            result.append(line)
    return b"".join(result)


def replace_aliases(path: Path, contents: bytes, directory_fd: int) -> None:
    fd, temporary = tempfile.mkstemp(prefix=".aliases-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as output:
            mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o600
            os.fchmod(output.fileno(), mode)
            output.write(contents)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
        os.fsync(directory_fd)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def locked_directory(path: Path) -> int | None:
    directory_fd = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
    deadline = time.monotonic() + 2
    while True:
        try:
            fcntl.flock(directory_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            return directory_fd
        except BlockingIOError:
            if time.monotonic() >= deadline:
                os.close(directory_fd)
                return None
            time.sleep(0.05)


def add_alias(message: str, path: Path) -> None:
    contacts = message_contacts(message)
    if not contacts:
        return
    own = own_addresses(path)

    # A directory lock survives replacing the file, so concurrent readers
    # cannot write through an old inode. The file itself is replaced atomically.
    directory_fd = locked_directory(path)
    if directory_fd is None:
        return
    try:
        contents = path.read_bytes() if path.exists() else b""
        if contents.startswith(b"\0GITCRYPT\0"):
            return
        keys, addresses = saved_aliases(contents)
        additions = []
        for name, address in contacts:
            if address in addresses or address in own:
                continue
            key = alias_key(address, keys)
            entry = f"alias {key} {name} <{address}>" if name else f"alias {key} <{address}>"
            additions.append(entry.encode("utf-8") + b"\n")
            keys.add(key.casefold())
            addresses.add(address)
        if additions:
            separator = b"" if not contents or contents.endswith(b"\n") else b"\n"
            replace_aliases(path, sorted_aliases(contents + separator + b"".join(additions)), directory_fd)
    finally:
        os.close(directory_fd)


def sort_file(path: Path) -> None:
    directory_fd = locked_directory(path)
    if directory_fd is None:
        return
    try:
        contents = path.read_bytes()
        if contents.startswith(b"\0GITCRYPT\0"):
            return
        ordered = sorted_aliases(contents)
        if ordered != contents:
            replace_aliases(path, ordered, directory_fd)
    finally:
        os.close(directory_fd)


def main() -> None:
    config_home = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    path = config_home / "neomutt" / "accounts" / "aliases"
    if sys.argv[1:] == ["--sort"]:
        sort_file(path)
        return

    message = sys.stdin.buffer.read()
    try:
        add_alias(message.decode("utf-8", errors="replace"), path)
    except (OSError, UnicodeError) as error:
        print(f"Could not save sender alias: {error}", file=sys.stderr)
    sys.stdout.buffer.write(message)


if __name__ == "__main__":
    main()
