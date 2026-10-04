#!/usr/bin/python3
"""Hardware-free camera selection and bounded capture/fallback tests."""

import io
import os
import runpy
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
NS = runpy.run_path(str(ROOT / "utilities/camera/intruder-capture"))
GLOBALS = NS["camera_devices"].__globals__
REAL_POPEN = subprocess.Popen


class IntruderCaptureTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.internal = self.root / "internal-camera"
        self.internal.touch()
        self.external = self.root / "usb-monitor-camera-video-index0"
        self.external.touch()
        (self.root / "usb-monitor-camera-video-index1").touch()
        self.pattern = str(self.root / "usb-monitor-*-video-index0")
        self.output = self.root / "photos with spaces"
        self.log = self.root / "capture-log"
        self.script = self.root / "fake capture"
        self.script.write_text(
            "#!/usr/bin/python3\n"
            "import os, sys, time\n"
            "from pathlib import Path\n"
            "with open(os.environ['CAMERA_TEST_LOG'], 'a') as log:\n"
            "    log.write(sys.argv[1] + '\\n')\n"
            "Path(sys.argv[2]).write_text('partial image')\n"
            "if os.environ.get('CAMERA_TEST_HANG') == '1': time.sleep(30)\n"
            "if os.environ.get('CAMERA_TEST_FAIL_ALL') == '1': sys.exit(1)\n"
            "if os.environ.get('CAMERA_TEST_FAIL_EXTERNAL') == '1' and 'usb-monitor' in sys.argv[1]: sys.exit(1)\n"
        )
        self.script.chmod(0o700)
        env = patch.dict(os.environ, {"CAMERA_TEST_LOG": str(self.log)})
        env.start()
        self.addCleanup(env.stop)
        hardware = patch.dict(
            GLOBALS,
            {
                "external_output_active": lambda _output: True,
                "camera_available": lambda device: Path(device).exists(),
            },
        )
        hardware.start()
        self.addCleanup(hardware.stop)
        popen = patch.object(subprocess, "Popen", side_effect=self.allow_fixture_only)
        popen.start()
        self.addCleanup(popen.stop)
        run = patch.object(
            subprocess,
            "run",
            side_effect=AssertionError("Unexpected hardware command"),
        )
        run.start()
        self.addCleanup(run.stop)

    def allow_fixture_only(self, argv, **kwargs):
        if argv[0] != str(self.script):
            raise AssertionError(f"Unexpected subprocess: {argv[0]}")
        return REAL_POPEN(argv, **kwargs)

    def capture(self, timeout=7):
        return NS["capture_photo"](
            str(self.internal),
            self.pattern,
            "DP-TEST",
            str(self.script),
            str(self.output),
            timeout,
        )

    def test_external_output_requires_active_geometry(self):
        fixtures = (
            ("DP-TEST connected 1920x1080+0+0\n", True),
            ("DP-TEST connected primary 1920x1080-1920+0\n", True),
            ("DP-TEST connected\n", False),
            ("DP-TEST disconnected\n", False),
            ("DP-OTHER connected 1920x1080+0+0\n", False),
        )
        for stdout, expected in fixtures:
            with (
                self.subTest(stdout=stdout),
                patch.object(
                    subprocess,
                    "run",
                    return_value=subprocess.CompletedProcess([], 0, stdout, ""),
                ),
            ):
                self.assertEqual(NS["external_output_active"]("DP-TEST"), expected)
        with patch.object(
            subprocess,
            "run",
            side_effect=subprocess.TimeoutExpired("xrandr", 3),
        ):
            self.assertFalse(NS["external_output_active"]("DP-TEST"))

    def test_external_color_camera_is_preferred_with_builtin_fallback(self):
        self.assertEqual(
            NS["camera_devices"](str(self.internal), self.pattern, "DP-TEST"),
            [str(self.external), str(self.internal)],
        )
        with patch.dict(GLOBALS, {"external_output_active": lambda _output: False}):
            self.assertEqual(
                NS["camera_devices"](str(self.internal), self.pattern, "DP-TEST"),
                [str(self.internal)],
            )

    def test_selection_rechecks_hotplug_and_ignores_metadata_node(self):
        self.external.unlink()
        self.assertEqual(
            NS["camera_devices"](str(self.internal), self.pattern, "DP-TEST"),
            [str(self.internal)],
        )
        self.external.touch()
        self.assertEqual(
            NS["camera_devices"](str(self.internal), self.pattern, "DP-TEST")[0],
            str(self.external),
        )

    def test_no_available_camera_does_not_create_a_photo(self):
        self.external.unlink()
        self.internal.unlink()
        with self.assertRaisesRegex(RuntimeError, "No intruder capture camera"):
            self.capture()
        self.assertFalse(self.output.exists())

    def test_successful_external_capture_is_private_and_skips_builtin(self):
        photo = self.capture()
        self.assertEqual(self.log.read_text().splitlines(), [str(self.external)])
        self.assertGreater(photo.stat().st_size, 0)
        self.assertEqual(photo.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.output.stat().st_mode & 0o777, 0o700)

    def test_busy_external_falls_back_and_removes_partial_image(self):
        with patch.dict(os.environ, {"CAMERA_TEST_FAIL_EXTERNAL": "1"}):
            photo = self.capture()
        self.assertEqual(
            self.log.read_text().splitlines(),
            [str(self.external), str(self.internal)],
        )
        self.assertEqual(list(self.output.iterdir()), [photo])

    def test_failed_capture_leaves_no_images(self):
        with (
            patch.dict(os.environ, {"CAMERA_TEST_FAIL_ALL": "1"}),
            self.assertRaises(RuntimeError),
        ):
            self.capture()
        self.assertEqual(list(self.output.iterdir()), [])

    def test_timeout_is_bounded_and_cleans_partial_image(self):
        self.external.unlink()
        with (
            patch.dict(os.environ, {"CAMERA_TEST_HANG": "1"}),
            self.assertRaisesRegex(RuntimeError, "timed out"),
        ):
            self.capture(timeout=0.1)
        self.assertEqual(list(self.output.iterdir()), [])

    def test_cli_expands_save_directory_and_reports_only_image_path(self):
        self.external.unlink()
        argv = [
            "intruder-capture",
            "--camera-device",
            str(self.internal),
            "--capture-script",
            str(self.script),
            "--save-dir",
            "$CAMERA_TEST_DIR",
        ]
        with (
            patch.dict(os.environ, {"CAMERA_TEST_DIR": str(self.output)}),
            patch.object(sys, "argv", argv),
            patch.object(sys, "stdout", new_callable=io.StringIO) as out,
        ):
            NS["main"]()
        self.assertTrue(Path(out.getvalue().strip()).is_file())


if __name__ == "__main__":
    unittest.main()
