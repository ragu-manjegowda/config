"""Codex theme updates and metadata-only session listing for cx."""

import copy
import datetime
import fcntl
import json
import os
import plistlib
import re
import shutil
import sqlite3
import stat
import subprocess
import sys
import tempfile
import time
import tomllib
import uuid
from pathlib import Path


def codex_home():
    return Path(os.environ.get("CODEX_HOME", Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "codex"))


def theme(mode):
    if mode not in ("light", "dark"):
        raise ValueError("theme must be light or dark")
    home = codex_home()
    home.mkdir(parents=True, exist_ok=True)
    directory = home / "themes"
    directory.mkdir(exist_ok=True)
    source = Path(__file__).resolve().parent / "themes"
    for name in ("light", "dark"):
        filename = f"solarized-opencode-{name}.tmTheme"
        target = directory / filename
        if not target.exists():
            shutil.copyfile(source / filename, target)
    path = home / "config.toml"
    selected = f"solarized-opencode-{mode}"
    text = path.read_text() if path.exists() else "[tui]\ntheme = \"solarized-opencode-dark\"\n"
    before = tomllib.loads(text)
    expected = copy.deepcopy(before)

    def update(node, parent=None):
        for key, value in node.items():
            if isinstance(value, dict):
                update(value, key)
            elif parent == "tui" and key == "theme" and value in (
                "solarized-opencode-dark", "solarized-opencode-light",
            ):
                node[key] = selected

    update(expected)
    replacement = re.sub(
        r'''(?m)^(\s*theme\s*=\s*)(["'])solarized-opencode-(?:light|dark)\2''',
        lambda match: match[1] + match[2] + selected + match[2], text,
    )
    if tomllib.loads(replacement) != expected:
        raise ValueError("cannot change theme without modifying unrelated TOML values")
    if replacement == text and path.exists():
        return
    permissions = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o600
    descriptor, temporary = tempfile.mkstemp(dir=home, prefix=".cx-theme-")
    try:
        with os.fdopen(descriptor, "w") as output:
            output.write(replacement)
        os.chmod(temporary, permissions)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def clean(value):
    return re.sub(r"[\x00-\x1f\x7f]", " ", str(value or ""))


def palette():
    home = codex_home()
    path = home / "config.toml"
    data = tomllib.loads(path.read_text()) if path.exists() else {}
    selected = data.get("tui", {}).get("theme")
    if selected not in ("solarized-opencode-dark", "solarized-opencode-light"):
        return
    with (home / "themes" / f"{selected}.tmTheme").open("rb") as source:
        colors = plistlib.load(source)["settings"][0]["settings"]
    foreground, background = colors["foreground"], colors["background"]
    if not all(re.fullmatch(r"#[0-9a-fA-F]{6}", value) for value in (foreground, background)):
        raise ValueError("invalid Solarized terminal colors")
    print(f"fg={foreground},bg={background}")


def sessions():
    home = codex_home()
    config = home / "config.toml"
    data = tomllib.loads(config.read_text()) if config.exists() else {}
    storage = Path(data.get("sqlite_home", home)).expanduser()
    databases = list(storage.glob("state_*.sqlite"))
    databases.sort(key=lambda path: int(re.search(r"state_(\d+)\.sqlite$", path.name)[1])
                   if re.search(r"state_(\d+)\.sqlite$", path.name) else -1, reverse=True)
    if (storage / "state.sqlite").exists():
        databases.append(storage / "state.sqlite")
    if not databases:
        return
    with sqlite3.connect(databases[0].resolve().as_uri() + "?mode=ro", uri=True, timeout=2) as connection:
        connection.row_factory = sqlite3.Row
        columns = {row[1] for row in connection.execute("PRAGMA table_info(threads)")}
        required = {"id", "cwd", "updated_at"}
        if not required <= columns:
            raise ValueError("Codex session database has an unsupported threads schema")
        selected = [name for name in ("id", "cwd", "updated_at", "updated_at_ms", "recency_at_ms", "name", "title", "preview") if name in columns]
        conditions = []
        if "archived" in columns:
            conditions.append("archived = 0")
        if "preview" in columns:
            conditions.append("preview <> ''")
        elif "has_user_event" in columns:
            conditions.append("has_user_event = 1")
        if "source" in columns:
            conditions.append("source IN ('cli', 'vscode', 'app-server', 'app_server', 'appServer')")
        ordering = next(name for name in ("recency_at_ms", "updated_at_ms", "updated_at") if name in columns)
        query = "SELECT " + ",".join(selected) + " FROM threads"
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        for row in connection.execute(query + " ORDER BY " + ordering + " DESC, id DESC"):
            identifier = str(uuid.UUID(row["id"]))
            keys = row.keys()
            title = next((row[name] for name in ("name", "title", "preview") if name in keys and row[name]), "Untitled")
            timestamp = row[ordering] or 0
            if ordering.endswith("_ms") or timestamp > 100000000000:
                timestamp /= 1000
            updated = datetime.datetime.fromtimestamp(timestamp).strftime("%Y-%m-%d %H:%M")
            display = f"{updated:19}  {clean(title)[:44]:44}  {clean(row['cwd'])}"
            print(f"{identifier}\t{display}\t{clean(title)}")


def daemon_socket_is_idle(socket):
    connections = subprocess.run(
        ["ss", "-xanH"], check=True, capture_output=True, text=True, timeout=1,
    ).stdout
    endpoint = re.compile(rf"^u_str\s+(\S+)\s+\d+\s+\d+\s+{re.escape(str(socket))}\s+\d+\s")
    states = [match[1] for line in connections.splitlines() if (match := endpoint.match(line))]
    return states == ["LISTEN"]


def daemon_work_is_idle(connection):
    deadline = time.monotonic() + 2
    request_id = 0

    def request(method, params=None):
        nonlocal request_id
        request_id += 1
        message = {"id": request_id, "method": method}
        if params is not None:
            message["params"] = params
        connection.send(json.dumps(message))
        while time.monotonic() < deadline:
            response = json.loads(connection.recv(timeout=max(0, deadline - time.monotonic())))
            if response.get("id") == request_id:
                return response["result"]
        raise TimeoutError("Codex did not answer the idle check")

    request("initialize", {
        "clientInfo": {"name": "cx-idle-check", "version": "1"},
        "capabilities": {"experimentalApi": True},
    })
    connection.send(json.dumps({"method": "initialized"}))
    if request("remoteControl/status/read")["status"] != "disabled":
        return False
    loaded = request("thread/loaded/list", {"limit": 100})
    if loaded.get("nextCursor"):
        return False
    if not isinstance(loaded["data"], list):
        return False
    for identifier in loaded["data"]:
        thread = request("thread/read", {"threadId": identifier, "includeTurns": False})["thread"]
        if thread["status"]["type"] != "idle":
            return False
        queue = request("thread/queue/list", {"threadId": identifier, "limit": 1})
        if queue["data"] != [] or queue.get("nextCursor"):
            return False
    return True


def stop_idle_daemon():
    try:
        from websockets.exceptions import WebSocketException
        from websockets.sync.client import unix_connect
    except ImportError:
        return

    home = codex_home()
    state = home / "app-server-daemon"
    control = home / "app-server-control/app-server-control.sock"
    pid_file = state / "daemon.pid"
    settings_file = state / "settings.json"

    def snapshot():
        socket = control.resolve(strict=True)
        info = socket.stat()
        if not stat.S_ISSOCK(info.st_mode):
            raise ValueError("Codex control endpoint is not a socket")
        try:
            settings = settings_file.read_bytes()
        except FileNotFoundError:
            settings = b"{}"
        return socket, info.st_dev, info.st_ino, pid_file.read_bytes(), settings

    try:
        with (state / "cx-idle.lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            before = snapshot()
            socket = before[0]
            settings = json.loads(before[-1])
            if settings.get("remoteControlEnabled", False) is not False or settings.get("shutdownGraceSeconds", 60) <= 5:
                return
            if not daemon_socket_is_idle(socket):
                return
            with unix_connect(str(socket), open_timeout=1, close_timeout=0.25) as connection:
                if not daemon_work_is_idle(connection):
                    return
            if snapshot() == before and daemon_socket_is_idle(socket):
                subprocess.run(["codex", "app-server", "daemon", "stop"], timeout=5, check=True)
    except (OSError, ValueError, KeyError, TypeError, AttributeError, RuntimeError,
            subprocess.SubprocessError, WebSocketException):
        return


def main():
    try:
        if sys.argv[1:2] == ["theme"] and len(sys.argv) == 3:
            theme(sys.argv[2])
        elif sys.argv[1:] == ["sessions"]:
            sessions()
        elif sys.argv[1:] == ["palette"]:
            palette()
        elif sys.argv[1:] == ["stop-idle-daemon"]:
            stop_idle_daemon()
        else:
            raise ValueError("usage: tools.py theme light|dark | sessions | palette | stop-idle-daemon")
    except (OSError, ValueError, sqlite3.Error) as error:
        print(f"cx: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
