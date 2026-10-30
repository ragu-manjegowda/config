"""Exercise per-machine Chrome scaling across light/dark mode changes."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[2] / "scripts/chromium-theme.py"


class ChromiumThemeTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name) / "config with spaces"
        self.profile = self.root / "awesome/configuration/config.lua"
        self.profile.parent.mkdir(parents=True)
        self.profile.write_text("return {\n display = {\n browser_scale = 1,\n },\n}\n")
        (self.root / "chrome-flags-dark.conf").write_text("--force-dark-mode\n--enable-features=WebUIDarkMode\n--force-device-scale-factor=2\n")
        (self.root / "chrome-flags-light.conf").write_text("--force-device-scale-factor=2\n")
        self.output = self.root / "chrome-flags.conf"

    def run_theme(self, mode):
        return subprocess.run(["python3", str(SCRIPT), mode], check=False, text=True,
                              capture_output=True, env=dict(os.environ, XDG_CONFIG_HOME=str(self.root)))

    def test_dark_mode_preserves_theme_flags_with_lenovo_scale(self):
        result = self.run_theme("dark")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--force-dark-mode", self.output.read_text())
        self.assertIn("--force-device-scale-factor=1\n", self.output.read_text())

    def test_light_mode_uses_lenovo_scale(self):
        self.assertEqual(self.run_theme("light").returncode, 0)
        self.assertEqual(self.output.read_text(), "--force-device-scale-factor=1\n")

    def test_profiles_without_override_keep_their_template_scale(self):
        self.profile.write_text("return { machine = 'laptop' }\n")
        self.assertEqual(self.run_theme("light").returncode, 0)
        self.assertEqual(self.output.read_text(), "--force-device-scale-factor=2\n")

    def test_repeated_theme_changes_do_not_duplicate_scale_flags(self):
        for mode in ("dark", "light", "dark"):
            self.assertEqual(self.run_theme(mode).returncode, 0)
        self.assertEqual(self.output.read_text().count("--force-device-scale-factor="), 1)

    def test_invalid_scale_preserves_previous_flags(self):
        self.profile.write_text("return {\n browser_scale = 0,\n}\n")
        self.output.write_text("previous flags\n")
        self.assertNotEqual(self.run_theme("dark").returncode, 0)
        self.assertEqual(self.output.read_text(), "previous flags\n")


if __name__ == "__main__":
    unittest.main()
