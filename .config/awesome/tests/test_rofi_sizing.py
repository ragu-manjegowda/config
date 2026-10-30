"""Measure the real Run menu on private Xvfb displays; no user desktop or history."""
import os
import re
import select
import shutil
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

THEME = Path(__file__).resolve().parents[1] / "configuration/rofi/runmenu/rofi.rasi"


def stop(process):
    if process and process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)


@unittest.skipUnless(all(shutil.which(tool) for tool in ("Xvfb", "rofi", "xwininfo")),
                     "requires Xvfb, rofi and xwininfo")
class RofiSizingTests(unittest.TestCase):
    def measure(self, width, height, dpi):
        with tempfile.TemporaryDirectory() as directory:
            read_fd, write_fd = os.pipe()
            server = menu = None
            try:
                server = subprocess.Popen(
                    ["Xvfb", "-displayfd", str(write_fd), "-screen", "0", f"{width}x{height}x24",
                     "-nolisten", "tcp", "-dpi", str(dpi)], pass_fds=(write_fd,),
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                os.close(write_fd)
                write_fd = None
                self.assertTrue(select.select([read_fd], [], [], 10)[0], "Xvfb did not start")
                display = os.read(read_fd, 100).decode().strip()
                env = dict(os.environ, DISPLAY=":" + display, HOME=directory,
                           XDG_CACHE_HOME=directory, XDG_CONFIG_HOME=directory,
                           XDG_DATA_HOME=directory)
                menu = subprocess.Popen(
                    ["rofi", "-no-config", "-dmenu", "-p", "run", "-dpi", str(dpi), "-theme", str(THEME)],
                    stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
                    text=True, env=env)
                menu.stdin.write("Synthetic app\nA longer synthetic application name\nBrowser\nFiles\nSettings\n")
                menu.stdin.close()
                deadline = time.monotonic() + 10
                while time.monotonic() < deadline:
                    if menu.poll() is not None:
                        self.fail("Rofi exited: " + menu.stderr.read())
                    result = subprocess.run(["xwininfo", "-root", "-tree"], env=env,
                                            capture_output=True, text=True, check=False)
                    for line in result.stdout.splitlines():
                        if '"rofi" "Rofi"' not in line:
                            continue
                        match = re.search(r"(\d+)x(\d+)([+-]\d+)([+-]\d+)", line.replace("+-", "-"))
                        if match:
                            return tuple(map(int, match.groups()))
                    time.sleep(0.05)
                self.fail("Run menu window did not appear")
            finally:
                stop(menu)
                stop(server)
                if menu and menu.stderr:
                    menu.stderr.close()
                os.close(read_fd)
                if write_fd is not None:
                    os.close(write_fd)

    def test_menu_fits_small_and_large_screens_at_multiple_dpis(self):
        for width, height, dpi in ((1920, 1200, 96), (1920, 1080, 96),
                                   (2880, 1800, 144), (3440, 1440, 144), (800, 600, 192)):
            with self.subTest(screen=(width, height), dpi=dpi):
                menu_width, menu_height, x, y = self.measure(width, height, dpi)
                self.assertGreaterEqual(menu_width, min(400 * dpi / 96, width * 0.85))
                self.assertGreaterEqual(x, 0)
                self.assertGreaterEqual(y, 0)
                self.assertLessEqual(x + menu_width, width)
                self.assertLessEqual(y + menu_height, height)

    def test_equal_dpi_preserves_readable_width_across_resolutions(self):
        small = self.measure(1920, 1200, 96)[0]
        large = self.measure(2880, 1800, 96)[0]
        self.assertLessEqual(abs(small - large), 2, "Menu width still depends on screen percentage")


if __name__ == "__main__":
    unittest.main()
