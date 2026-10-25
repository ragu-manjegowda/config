#!/usr/bin/python3
"""Capture dispatch and real PNG encoding tests using synthetic camera frames."""

import io
import json
import os
import runpy
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image, ImageStat

ROOT = Path(__file__).resolve().parents[1]
CAMERA = ROOT / "utilities/camera"
NATIVE = runpy.run_path(str(CAMERA / "capture-native"))


class NativeCaptureTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="intruder photo ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.photo = self.root / "photo with spaces.png"

    def test_full_sensor_is_requested_before_downscaling(self):
        pipeline = NATIVE["PIPELINE"]
        self.assertLess(pipeline.index("width=3840,height=2160"), pipeline.index("videoscale"))
        self.assertLess(pipeline.index("videoscale"), pipeline.index("width=848,height=480"))
        self.assertIn("add-borders=true", pipeline)
        self.assertIn("pixel-aspect-ratio=1/1", pipeline)

    def test_real_encoder_lifts_dark_midtones_without_clipping_highlights(self):
        width, height = 848, 480
        frame = bytes((32, 32, 32)) * (width * height // 2)
        frame += bytes((240, 240, 240)) * (width * height // 2)
        NATIVE["encode_frame"](frame, width, height, self.photo)
        with Image.open(self.photo) as image:
            self.assertEqual(image.format, "PNG")
            self.assertEqual(image.size, (width, height))
            dark = ImageStat.Stat(image.crop((0, 0, width, height // 2)).convert("L")).mean[0]
            bright = ImageStat.Stat(image.crop((0, height // 2, width, height)).convert("L")).mean[0]
            self.assertGreater(dark, 40)
            self.assertGreater(bright, 235)
            self.assertLess(bright, 255)

    def test_incomplete_frame_cannot_be_encoded(self):
        with self.assertRaisesRegex(ValueError, "Incomplete"):
            NATIVE["encode_frame"](b"partial", 848, 480, self.photo)
        self.assertFalse(self.photo.exists())

    def test_encoder_errors_are_reported(self):
        with self.assertRaises(RuntimeError):
            NATIVE["encode_frame"](b"\x20" * 12, 2, 2, self.root / "missing/photo.png")

    def test_cli_creates_private_photo_without_printing_protocol_noise(self):
        old_mask = os.umask(0o077)
        try:
            with (
                patch.dict(NATIVE["main"].__globals__, {
                    "capture_rgb": lambda: (b"\x20" * (848 * 480 * 3), 848, 480),
                }),
                patch.object(sys, "argv", ["capture-native", str(self.photo)]),
                patch.object(sys, "stdout", new_callable=io.StringIO) as output,
            ):
                NATIVE["main"]()
                self.assertEqual(output.getvalue(), "")
            self.assertEqual(self.photo.stat().st_mode & 0o777, 0o600)
        finally:
            os.umask(old_mask)


class CaptureDispatchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="capture dispatch ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.device = self.root / "camera"
        self.device.touch()
        self.name = self.root / "camera-name"
        self.name.write_text("Prisma Compatibility Camera\n")
        source = (CAMERA / "capture").read_text().replace(
            "/sys/class/video4linux/video90/name", str(self.name)
        ).replace("/dev/video90", str(self.device))
        # Test substitutions are quoted, just like the original production paths.
        source = source.replace(f"-r {self.name}", f'-r "{self.name}"')
        source = source.replace(f"$(<{self.name})", f'$(<"{self.name}")')
        source = source.replace(f"== {self.device}", f'== "{self.device}"')
        self.script = self.root / "capture"
        self.script.write_text(source)
        (self.root / "capture-native").write_text(
            "import os, pathlib, sys\n"
            "pathlib.Path(os.environ['CAPTURE_NATIVE_LOG']).write_text(sys.argv[1])\n"
            "if os.environ.get('FAIL_NATIVE') == '1': sys.exit(1)\n"
            "pathlib.Path(sys.argv[1]).write_bytes(b'native photo')\n"
        )
        ffmpeg = self.root / "ffmpeg"
        ffmpeg.write_text(
            "#!/usr/bin/python3\nimport json, os, pathlib, sys\n"
            "pathlib.Path(os.environ['CAPTURE_FFMPEG_LOG']).write_text(json.dumps(sys.argv[1:]))\n"
            "pathlib.Path(sys.argv[-1]).write_bytes(b'v4l2 photo')\n"
        )
        ffmpeg.chmod(0o700)
        self.photo = self.root / "photo.png"
        self.native_log = self.root / "native.log"
        self.ffmpeg_log = self.root / "ffmpeg.log"

    def capture(self, **extra):
        return subprocess.run(
            ["bash", str(self.script), str(self.device), str(self.photo)],
            env=os.environ | {
                "PATH": f"{self.root}:{os.environ['PATH']}",
                "CAPTURE_NATIVE_LOG": str(self.native_log),
                "CAPTURE_FFMPEG_LOG": str(self.ffmpeg_log),
            } | extra,
            capture_output=True, text=True, timeout=8, check=False,
        )

    def test_compatibility_camera_uses_native_full_frame(self):
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.photo.read_bytes(), b"native photo")
        self.assertFalse(self.ffmpeg_log.exists())

    def test_busy_or_missing_native_backend_falls_back_to_v4l2(self):
        result = self.capture(FAIL_NATIVE="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.native_log.exists())
        self.assertEqual(self.photo.read_bytes(), b"v4l2 photo")
        arguments = json.loads(self.ffmpeg_log.read_text())
        self.assertIn(r"select=gte(t\,2)", arguments[arguments.index("-vf") + 1])

    def test_other_cameras_keep_the_v4l2_capture_path(self):
        self.name.write_text("USB color camera\n")
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.native_log.exists())
        self.assertEqual(self.photo.read_bytes(), b"v4l2 photo")


if __name__ == "__main__":
    unittest.main()
