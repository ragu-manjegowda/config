#!/usr/bin/python3
"""Audio endpoint selection, mute/volume and unavailable-state tests; no hardware."""

import copy
import json
import runpy
import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch

NS = runpy.run_path(
    str(Path(__file__).resolve().parents[1] / "utilities/desktop/audio-control")
)

GLOBALS = NS["control"].__globals__


def node(
    name,
    device,
    kind="sink",
    muted=False,
    volume=50,
    port="Speaker",
    available=True,
):
    return {
        "name": name,
        "description": name,
        "mute": muted,
        "properties": {
            "device.name": device,
            "device.class": "sound",
            "device.profile.description": port,
        },
        "volume": {
            "left": {"value": round(volume * 65536 / 100)},
            "right": {"value": round(volume * 65536 / 100)},
        },
        "ports": [
            {
                "name": port,
                "availability": "available" if available else "not available",
            }
        ],
        "active_port": port,
        "kind": kind,
    }


class AudioControlTests(unittest.TestCase):
    def setUp(self):
        hardware = patch.object(
            subprocess,
            "run",
            side_effect=AssertionError("Unexpected hardware subprocess"),
        )
        hardware.start()
        self.addCleanup(hardware.stop)
        self.primary = node("laptop-speaker", "internal-card", muted=True, volume=34)
        self.monitor = node("monitor-speaker", "usb-Monitor-123")
        self.mic = node("laptop-mic", "internal-card", kind="source", port="Mic")
        self.monitor_mic = node(
            "monitor-mic",
            "usb-Monitor-123",
            kind="source",
            port="Mic",
            muted=True,
        )
        self.nodes = {
            "sink": [self.primary, self.monitor],
            "source": [self.mic, self.monitor_mic],
        }
        self.calls = []
        replacement = patch.dict(GLOBALS, {"run": self.fake_run})
        replacement.start()
        self.addCleanup(replacement.stop)

    def fake_run(self, *args):
        self.calls.append(args)
        if args[:2] == ("--format=json", "list"):
            return json.dumps(self.nodes[args[2][:-1]])
        if args[0].startswith("get-default-"):
            return (
                self.primary["name"] if args[0].endswith("sink") else self.mic["name"]
            )
        name = args[1]
        target = next(
            n for values in self.nodes.values() for n in values if n["name"] == name
        )
        if args[0].endswith("-mute"):
            target["mute"] = not target["mute"]
        elif args[0].endswith("-volume"):
            percent = float(args[2][:-1])
            for channel in target["volume"].values():
                channel["value"] = round(percent * 65536 / 100)
        else:
            raise AssertionError(args)
        return ""

    def control(self, kind="sink", scope="external", action="status", value=None):
        return NS["control"](
            kind,
            scope,
            "usb-Monitor-*" if scope == "external" else "internal-card",
            "usb-Monitor-*",
            action,
            value,
        )

    def test_targeted_volume_preserves_other_device_and_defaults(self):
        before = copy.deepcopy(self.primary)
        state = self.control(action="set", value=70)
        self.assertAlmostEqual(state["volume"], 70, places=2)
        self.assertEqual(self.primary, before)
        self.assertTrue(
            all(not c[0].startswith(("set-default-", "move-")) for c in self.calls)
        )

    def test_microphone_mute_targets_monitor_and_reads_back(self):
        state = self.control(kind="source", action="mute")
        self.assertFalse(state["muted"])
        self.assertFalse(self.mic["mute"])
        self.assertIn(("set-source-mute", "monitor-mic", "toggle"), self.calls)

    def test_missing_external_never_changes_global_default(self):
        self.nodes["source"] = [self.mic]
        self.assertFalse(self.control(kind="source", action="mute")["available"])
        self.assertFalse(any(c[0].startswith("set-") for c in self.calls))

    def test_monitor_sources_and_unavailable_ports_are_excluded(self):
        playback = node("playback.monitor", "usb-Monitor-123", kind="source")
        self.nodes["source"] = [playback]
        self.assertFalse(self.control(kind="source")["available"])
        self.monitor["ports"][0]["availability"] = "not available"
        self.assertFalse(self.control()["available"])

    def test_primary_scope_prefers_laptop_and_generic_desktop_default(self):
        self.assertEqual(self.control(scope="primary")["name"], "laptop-speaker")
        state = NS["control"](
            "sink", "primary", "different-machine", "usb-Monitor-*", "status"
        )
        self.assertEqual(state["name"], "laptop-speaker")
        self.nodes["sink"] = [self.monitor]
        self.assertFalse(self.control(scope="primary")["available"])

    def test_monitor_default_does_not_change_primary_control_target(self):
        original = self.fake_run

        def monitor_default(*args):
            if args[0] == "get-default-sink":
                return self.monitor["name"]
            if args[0] == "get-default-source":
                return self.monitor_mic["name"]
            return original(*args)

        with patch.dict(GLOBALS, {"run": monitor_default}):
            self.assertEqual(
                self.control(scope="primary")["name"], self.primary["name"]
            )
            self.assertEqual(
                self.control(kind="source", scope="primary")["name"],
                self.mic["name"],
            )

    def test_relative_clamping_and_nonfinite_rejection(self):
        self.assertAlmostEqual(self.control(action="adjust", value=-100)["volume"], 0)
        self.assertAlmostEqual(self.control(action="set", value=150)["volume"], 100)
        with self.assertRaises(ValueError):
            self.control(action="set", value=float("nan"))

    def test_removed_device_after_write_returns_unavailable(self):
        original = self.fake_run

        def disappearing(*args):
            result = original(*args)
            if args[0] == "set-sink-volume":
                self.nodes["sink"] = [self.primary]
            return result

        with patch.dict(GLOBALS, {"run": disappearing}):
            self.assertFalse(self.control(action="set", value=40)["available"])


if __name__ == "__main__":
    unittest.main()
