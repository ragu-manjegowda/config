#!/usr/bin/env bash

set -euo pipefail

exec python3 - "${BASH_SOURCE[0]}" "$@" <<'PY'
import argparse
import hashlib
import json
import os
import platform
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path, PurePosixPath
from urllib.parse import urlsplit


class InstallError(Exception):
    pass


def download(url, destination):
    subprocess.run([
        "curl", "--fail", "--silent", "--show-error", "--location",
        "--proto", "=https", "--proto-redir", "=https",
        "--connect-timeout", "10", "--max-time", "120", "--retry", "2",
        "--output", str(destination), url,
    ], check=True)


def download_asset(asset, destination):
    url = asset["browser_download_url"]
    parsed = urlsplit(url)
    if (parsed.scheme != "https" or parsed.netloc != "github.com"
            or not parsed.path.startswith("/tomasklaen/uosc/releases/download/")):
        raise InstallError("Release asset is not hosted in the official uosc repository")
    download(url, destination)
    digest = asset.get("digest")
    if digest:
        algorithm, expected = digest.split(":", 1)
        if algorithm != "sha256":
            raise InstallError(f"Unsupported release checksum: {algorithm}")
        if hashlib.sha256(destination.read_bytes()).hexdigest() != expected:
            raise InstallError(f"Checksum verification failed for {asset['name']}")
    else:
        print(f"Warning: upstream provides no checksum for {asset['name']}", file=sys.stderr)


def unpack(archive_path, destination):
    with zipfile.ZipFile(archive_path) as archive:
        for member in archive.infolist():
            name = PurePosixPath(member.filename)
            mode = member.external_attr >> 16
            if name.is_absolute() or ".." in name.parts or "\\" in member.filename or stat.S_ISLNK(mode):
                raise InstallError("Release archive contains an unsafe path or symbolic link")
        archive.extractall(destination)


def remove(path):
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    elif os.path.lexists(path):
        path.unlink()


def replace_installation(replacements, backup_dir):
    applied = []
    try:
        for index, (source, destination) in enumerate(replacements):
            destination.parent.mkdir(parents=True, exist_ok=True)
            backup = backup_dir / str(index)
            if os.path.lexists(destination):
                os.replace(destination, backup)
            applied.append((destination, backup))
            os.replace(source, destination)
    except OSError:
        for destination, backup in reversed(applied):
            remove(destination)
            if os.path.lexists(backup):
                os.replace(backup, destination)
        raise


def main():
    parser = argparse.ArgumentParser(
        prog=Path(sys.argv[1]).name,
        description="Install or update uosc from its latest stable GitHub release, preserving existing settings.",
    )
    parser.parse_args(sys.argv[2:])
    if not shutil.which("curl"):
        raise InstallError("Missing required command: curl")
    systems = {"Linux": "linux", "Darwin": "darwin"}
    system = systems.get(platform.system())
    if not system or platform.machine().lower() not in ("x86_64", "amd64"):
        raise InstallError("Upstream release helpers support only x86_64 Linux and macOS")
    config_dir = Path(sys.argv[1]).resolve().parent
    runtime = config_dir / "scripts/uosc"
    configuration = config_dir / "script-opts/uosc.conf"
    fonts = ("uosc_icons.otf", "uosc_textures.ttf")
    helper = f"bin/ziggy-{system}"
    marker = runtime / ".release-version"
    if runtime.is_symlink() or (runtime.exists() and not runtime.is_dir()):
        raise InstallError(f"Refusing to replace a symbolic link or non-directory: {runtime}")
    if runtime.exists() and not (runtime / "main.lua").is_file():
        raise InstallError(f"Existing directory is not a recognizable uosc installation: {runtime}")
    with tempfile.TemporaryDirectory(prefix=".uosc-install-", dir=config_dir) as temporary:
        work = Path(temporary)
        metadata = work / "release.json"
        download("https://api.github.com/repos/tomasklaen/uosc/releases/latest", metadata)
        release = json.loads(metadata.read_text())
        version = release["tag_name"]
        if not isinstance(version, str) or not version or release.get("draft") or release.get("prerelease"):
            raise InstallError("GitHub did not return a stable release")
        installed = marker.read_text().strip() if marker.is_file() else None
        complete = (
            (runtime / "main.lua").is_file()
            and os.access(runtime / helper, os.X_OK)
            and all((config_dir / "fonts" / font).is_file() for font in fonts)
            and os.path.lexists(configuration)
        )
        if installed == version and complete:
            print(f"uosc {version} is already installed; no update needed.")
            return
        assets = {asset["name"]: asset for asset in release["assets"]}
        needs_configuration = not os.path.lexists(configuration)
        required = ["uosc.zip"] + (["uosc.conf"] if needs_configuration else [])
        for name in required:
            if name not in assets:
                raise InstallError(f"Release {version} is missing {name}")
        print(f"Installing uosc {version}" + (f" (previously {installed})" if installed else ""), flush=True)
        archive_path = work / "uosc.zip"
        download_asset(assets["uosc.zip"], archive_path)
        extracted = work / "extracted"
        unpack(archive_path, extracted)
        source = extracted / "scripts/uosc"
        main_file = source / "main.lua"
        if not main_file.is_file() or not (source / helper).is_file():
            raise InstallError("Release archive is missing uosc's entry point or native helper")
        match = re.search(r"local\s+uosc_version\s*=\s*['\"]([^'\"]+)['\"]", main_file.read_text())
        if not match or match[1] != version.removeprefix("v"):
            raise InstallError("Archived uosc version does not match the release tag")
        (source / helper).chmod(0o755)
        (source / ".release-version").write_text(version + "\n")
        replacements = [(source, runtime)]
        for font in fonts:
            source_font = extracted / "fonts" / font
            if not source_font.is_file():
                raise InstallError(f"Release archive is missing {font}")
            replacements.append((source_font, config_dir / "fonts" / font))
        if needs_configuration:
            default_config = work / "uosc.conf"
            download_asset(assets["uosc.conf"], default_config)
            replacements.append((default_config, configuration))
        backup_dir = work / "backup"
        backup_dir.mkdir()
        replace_installation(replacements, backup_dir)
    print(f"Installed uosc {version} in {runtime}. Restart mpv to load it.")


try:
    main()
except (InstallError, OSError, ValueError, KeyError, subprocess.CalledProcessError, zipfile.BadZipFile) as error:
    print(f"uosc installer: {error}", file=sys.stderr)
    sys.exit(1)
PY
