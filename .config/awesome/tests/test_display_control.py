#!/usr/bin/python3
"""Hardware-free routing and RGB recovery tests; unexpected subprocesses fail."""

import io
import os
import runpy
import signal
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[1]
NS = runpy.run_path(str(ROOT / "utilities/display/display-control"))
Control = NS["DisplayControl"]
GLOBALS = Control.ddc.__globals__


class DisplayControlTests(unittest.TestCase):
    def setUp(self):
        # Tests must explicitly mock each subprocess entrypoint they exercise.
        # An accidental fall-through must never invoke the laptop's hardware.
        for name in ("run", "Popen"):
            guard = patch.object(
                subprocess,
                name,
                side_effect=AssertionError(f"Unexpected unmocked subprocess.{name}"),
            )
            guard.start()
            self.addCleanup(guard.stop)
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.env = patch.dict(
            os.environ,
            {
                "XDG_STATE_HOME": self.temp.name,
                "XDG_RUNTIME_DIR": self.temp.name,
            },
        )
        self.env.start()
        self.addCleanup(self.env.stop)

    def test_unmocked_hardware_commands_are_rejected(self):
        with self.assertRaisesRegex(
            AssertionError, "Unexpected unmocked subprocess.run"
        ):
            NS["run"](["ddcutil", "getvcp", "10"])
        with self.assertRaisesRegex(
            AssertionError, "Unexpected unmocked subprocess.Popen"
        ):
            subprocess.Popen(["redshift", "-m", "randr"])

    def test_edid_matches_requested_output_and_rejects_missing_display(self):
        edid = "ab" * 128
        text = "eDP-1 connected 100x100+0+0\n"
        text += (
            "DP-1 connected 100x100+100+0\n\tEDID:\n"
            + "\n".join("\t" + edid[n : n + 32] for n in range(0, 256, 32))
            + "\nHDMI-1 disconnected\n"
        )
        with patch.dict(GLOBALS, {"run": lambda _argv: text}):
            self.assertEqual(NS["output_edid"]("DP-1"), edid)
            with self.assertRaises(RuntimeError):
                NS["output_edid"]("HDMI-1")

    def test_connector_warning_is_not_failure_but_nonzero_status_is(self):
        result = subprocess.CompletedProcess(
            [], 0, "VCP 10 C 75 100\n", "Failed to find connector name\n"
        )
        with patch.object(subprocess, "run", return_value=result):
            self.assertEqual(NS["parse_vcp"](NS["run"](["ddcutil"]), "10"), (75, 100))
        result.returncode = 1
        with (
            patch.object(subprocess, "run", return_value=result),
            self.assertRaises(RuntimeError),
        ):
            NS["run"](["ddcutil"])
        with self.assertRaises(RuntimeError):
            NS["parse_vcp"]("VCP 10 C 99 0", "10")

    def test_laptop_uses_light_and_does_not_touch_ddc(self):
        calls = []

        def run(argv):
            calls.append(argv)
            return "65.00\n"

        control = Control("eDP-1")
        with patch.dict(GLOBALS, {"run": run}), control.lock():
            self.assertEqual(control.get_brightness(), 65)
            control.set_brightness(-10, relative=True)
        self.assertEqual(calls[2][-2:], ["-S", "55.0"])
        self.assertTrue(all(argv[0].endswith("/light") for argv in calls))
        with (
            patch.dict(GLOBALS, {"run": lambda _argv: "nan"}),
            self.assertRaises(RuntimeError),
        ):
            control.get_brightness()

    def test_ddc_native_range_relative_steps_clamp_and_nan(self):
        control = Control("DP-1", "ab" * 128)
        calls = []

        def ddc(*args):
            calls.append(args)
            return "VCP 10 C 32768 65535\n"

        with patch.object(control, "ddc", side_effect=ddc):
            self.assertAlmostEqual(control.get_brightness(), 50, places=2)
            control.set_brightness(50)
            self.assertEqual(calls[-1], ("setvcp", "10", "32768"))
            control.set_brightness(10, relative=True)
            self.assertEqual(calls[-1], ("setvcp", "10", "39322"))
            control.set_brightness(0)
            self.assertEqual(calls[-1], ("setvcp", "10", "3277"))
            with self.assertRaises(ValueError):
                control.set_brightness(float("nan"))

    def test_color_preserves_baseline_deduplicates_and_restores_after_failure(
        self,
    ):
        control = Control("DP-1", "ab" * 128)
        calls = []
        baseline = "VCP 14 SNC x0b\nVCP 16 C 90 100\nVCP 18 C 80 100\nVCP 1A C 70 100\n"

        def ddc(*args):
            calls.append(args)
            return baseline

        with patch.object(control, "ddc", side_effect=ddc), control.lock():
            control.set_temperature(4500)
            count = len(calls)
            control.set_temperature(4500)
            self.assertEqual(len(calls), count)
            self.assertIn(("setvcp", "16", "90"), calls)
            self.assertNotIn(("setvcp", "10", "90"), calls)
            self.assertEqual(control.state_file.stat().st_mode & 0o777, 0o600)
            with (
                patch.object(control, "ddc", side_effect=RuntimeError("unplugged")),
                self.assertRaises(RuntimeError),
            ):
                control.restore_color()
            self.assertTrue(control.state_file.exists())
            control.restore_color()
        self.assertFalse(control.state_file.exists())
        self.assertEqual(
            calls[-4:],
            [
                ("setvcp", "16", "90"),
                ("setvcp", "18", "80"),
                ("setvcp", "1A", "70"),
                ("setvcp", "14", "0x0b"),
            ],
        )

    def test_neutral_temperature_and_saved_profile_survive_worker_restart(self):
        self.assertEqual(NS["temperature_gains"](6500), (1, 1, 1))
        first = Control("DP-1", "ab" * 128)
        baseline = (
            "VCP 14 SNC x05\nVCP 16 C 100 100\nVCP 18 C 95 100\nVCP 1A C 90 100\n"
        )
        with patch.object(first, "ddc", return_value=baseline):
            first.set_temperature(4500)
        second = Control("DP-1", "ab" * 128)
        with patch.object(second, "ddc") as ddc:
            second.set_temperature(5500)
            self.assertEqual(second.save_color()["preset"], 5)
            second.restore_color()
            self.assertEqual(ddc.call_args.args, ("setvcp", "14", "0x05"))

    def test_schedule_worker_uses_dummy_redshift_and_restores_on_child_failure(
        self,
    ):
        worker = runpy.run_path(str(ROOT / "utilities/display/monitor-color"))
        control = Control("DP-1", "ab" * 128)
        baseline = (
            "VCP 14 SNC x0b\nVCP 16 C 100 100\nVCP 18 C 100 100\nVCP 1A C 100 100\n"
        )
        process = Mock()
        process.stdout = io.StringIO(
            "Color temperature: 6500K\nColor temperature: 4500K\nTemperature: 4500\n"
        )
        process.wait.return_value = 1
        process.poll.return_value = 1
        ready = str(Path(self.temp.name) / "ready")
        argv = [
            "monitor-color",
            "--output",
            "DP-1",
            "--config",
            "schedule.conf",
            "--ready-file",
            ready,
        ]
        with (
            patch("sys.argv", argv),
            patch.object(subprocess, "Popen", return_value=process) as popen,
            patch.object(
                runpy,
                "run_path",
                return_value={"DisplayControl": lambda _output: control},
            ),
            patch.object(signal, "signal"),
            patch.object(control, "ddc", return_value=baseline) as ddc,
        ):
            with self.assertRaisesRegex(RuntimeError, "stopped unexpectedly"):
                worker["main"]()
            self.assertIn("dummy", popen.call_args.args[0])
            self.assertEqual(ddc.call_args.args, ("setvcp", "14", "0x0b"))
        self.assertFalse(control.state_file.exists())
        self.assertFalse(Path(ready).exists())


if __name__ == "__main__":
    unittest.main()
