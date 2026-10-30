"""Ensure per-profile cursor rendering preserves themes and font preferences."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[2] / "scripts/toolkit-cursor.py"


class ToolkitCursorTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)
        self.config = self.home / ".config"
        self.profile = self.config / "awesome/configuration/config.lua"
        self.profile.parent.mkdir(parents=True)
        self.profile.write_text("return {\n cursor_size = 32,\n}\n")
        self.gtk = self.config / "gtk-3.0/settings.ini"
        self.gtk.parent.mkdir()
        self.gtk.write_text("[Settings]\ngtk-font-name=Hack Nerd Font 11\ngtk-cursor-theme-size=48\n")
        self.xsettings = self.config / "xsettingsd/xsettingsd.conf"
        self.xsettings.parent.mkdir()
        self.xsettings.write_text('Net/ThemeName "ExistingTheme"\n')
        (self.home / ".gtkrc-2.0").write_text("gtk-cursor-theme-size=48\n")

    def run_helper(self):
        return subprocess.run(["python3", str(SCRIPT)], check=False, capture_output=True, text=True,
                              env=dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.config)))

    def test_profile_cursor_is_shared_without_changing_fonts_or_theme(self):
        result = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("gtk-cursor-theme-size=32", self.gtk.read_text())
        self.assertIn("gtk-font-name=Hack Nerd Font 11", self.gtk.read_text())
        self.assertIn("Gtk/CursorThemeSize 32", self.xsettings.read_text())
        self.assertIn('Net/ThemeName "ExistingTheme"', self.xsettings.read_text())
        self.assertIn("gtk-cursor-theme-size=32", (self.home / ".gtkrc-2.0").read_text())

    def test_repeated_runs_do_not_duplicate_xsettings(self):
        for _ in range(2):
            self.assertEqual(self.run_helper().returncode, 0)
        self.assertEqual(self.xsettings.read_text().count("Gtk/CursorThemeSize"), 1)

    def test_legacy_profiles_without_override_are_preserved(self):
        self.profile.write_text("return { machine = 'laptop' }\n")
        before = self.gtk.read_text(), self.xsettings.read_text()
        self.assertEqual(self.run_helper().returncode, 0)
        self.assertEqual((self.gtk.read_text(), self.xsettings.read_text()), before)

    def test_invalid_cursor_size_does_not_rewrite_settings(self):
        self.profile.write_text("return {\n cursor_size = 0,\n}\n")
        before = self.gtk.read_text()
        self.assertNotEqual(self.run_helper().returncode, 0)
        self.assertEqual(self.gtk.read_text(), before)


if __name__ == "__main__":
    unittest.main()
