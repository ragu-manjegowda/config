#!/usr/bin/python3
"""Honor an explicit machine cursor size without changing toolkit font choices."""
import os
import re
from pathlib import Path


def update(path, pattern, setting, section=None):
    if not path.exists():
        return
    text = path.read_text()
    if re.search(pattern, text, re.MULTILINE):
        rendered = re.sub(pattern, setting, text, flags=re.MULTILINE)
    elif section and section in text:
        rendered = text.replace(section, section + "\n" + setting, 1)
    elif not section:
        rendered = text.rstrip() + "\n" + setting + "\n"
    else:
        return
    if rendered != text:
        path.write_text(rendered)


def main():
    root = Path(os.getenv("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    profile = root / "awesome/configuration/config.lua"
    if not profile.exists():
        return
    matches = re.findall(r"^\s*cursor_size\s*=\s*(\d+)", profile.read_text(), re.MULTILINE)
    if not matches:
        return
    if len(matches) != 1 or not 8 <= int(matches[0]) <= 256:
        raise SystemExit("Set one cursor_size between 8 and 256 in the machine profile")
    size = int(matches[0])
    update(Path.home() / ".gtkrc-2.0", r"^\s*gtk-cursor-theme-size\s*=.*$", f"gtk-cursor-theme-size={size}")
    update(root / "gtk-3.0/settings.ini", r"^\s*gtk-cursor-theme-size\s*=.*$", f"gtk-cursor-theme-size={size}", "[Settings]")
    update(root / "xsettingsd/xsettingsd.conf", r"^\s*Gtk/CursorThemeSize\s+.*$", f"Gtk/CursorThemeSize {size}")


if __name__ == "__main__":
    main()
