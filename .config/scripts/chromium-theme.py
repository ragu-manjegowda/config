#!/usr/bin/python3
"""Render Chromium theme flags with the active machine's optional scale."""
import os
import re
import sys
from pathlib import Path


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("dark", "light"):
        raise SystemExit("Usage: chromium-theme.py dark|light")
    root = Path(os.getenv("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    text = (root / f"chrome-flags-{sys.argv[1]}.conf").read_text()
    profile = root / "awesome/configuration/config.lua"
    if profile.exists():
        matches = re.findall(r"^\s*browser_scale\s*=\s*(\d+(?:\.\d+)?)", profile.read_text(), re.MULTILINE)
        if len(matches) > 1:
            raise SystemExit("Multiple browser_scale settings in machine profile")
        if matches:
            scale = float(matches[0])
            if not 0.5 <= scale <= 4:
                raise SystemExit("browser_scale must be between 0.5 and 4")
            lines = [line for line in text.splitlines() if not line.startswith("--force-device-scale-factor=")]
            lines.append(f"--force-device-scale-factor={scale:g}")
            text = "\n".join(lines) + "\n"
    (root / "chrome-flags.conf").write_text(text)


if __name__ == "__main__":
    main()
