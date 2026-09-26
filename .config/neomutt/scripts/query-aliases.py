#!/usr/bin/env python3
"""Return fuzzy-matched aliases using NeoMutt's external query protocol."""

import os
import subprocess
import sys
from email.utils import parseaddr
from pathlib import Path


def main() -> int:
    query = " ".join(sys.argv[1:]).strip()
    if not query:
        print("Type a name, alias, or email before pressing Tab")
        return 1

    config_home = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    path = config_home / "neomutt" / "accounts" / "aliases"
    try:
        contents = path.read_bytes()
    except OSError:
        print("Alias file is unavailable")
        return 1
    if contents.startswith(b"\0GITCRYPT\0"):
        print("Unlock git-crypt before searching aliases")
        return 1

    contacts = {}
    for line in contents.decode("utf-8", errors="replace").splitlines():
        fields = line.split(maxsplit=2)
        if len(fields) < 3 or fields[0].casefold() != "alias":
            continue
        name, address = parseaddr(fields[2])
        if not address or address.casefold() in contacts:
            continue
        name = name.replace("\t", " ").replace('"', "")
        contacts[address.casefold()] = (name, address, fields[1])

    if not contacts:
        print("No aliases available")
        return 1

    # --filter uses fzf's fuzzy ranking without drawing over NeoMutt's curses UI.
    rows = {}
    for name, address, key in contacts.values():
        display = name or address
        rows[f"{display}\t{address}\t{key}"] = (address, display, key)
    environment = dict(os.environ, FZF_DEFAULT_OPTS="")
    try:
        matches = subprocess.run(
            ["fzf", "--filter", query, "--ignore-case"],
            input="\n".join(rows) + "\n",
            text=True,
            capture_output=True,
            timeout=5,
            check=False,
            env=environment,
        )
    except (OSError, subprocess.TimeoutExpired):
        print("Alias search is unavailable")
        return 1

    selected = [rows[line] for line in matches.stdout.splitlines() if line in rows]
    if not selected:
        print("No matching aliases")
        return 1

    print(f"Found {len(selected)} matching aliases")
    for address, name, key in selected:
        print(f"{address}\t{name}\t{key}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
