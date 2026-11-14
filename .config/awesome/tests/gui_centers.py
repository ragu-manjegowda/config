"""Test real Awesome center widgets and keymaps on an isolated desktop."""

import json
import os
import select
import shutil
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

CONFIG = Path(__file__).resolve().parents[1]
ARTIFACTS = Path(os.environ.get("GUI_ARTIFACTS", "test-logs/awesome-gui")).resolve()


def stop(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)


class CenterGuiTests(unittest.TestCase):
    def setUp(self):
        for executable in (
            "Xvfb",
            "awesome",
            "awesome-client",
            "dbus-daemon",
            "xdotool",
            "import",
        ):
            self.assertIsNotNone(
                shutil.which(executable),
                "Missing GUI dependency: " + executable,
            )
        self.temporary = tempfile.TemporaryDirectory(prefix="awesome-gui-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.artifacts = ARTIFACTS / self._testMethodName
        self.artifacts.mkdir(parents=True, exist_ok=True)
        self.environment = dict(os.environ)
        self.environment.update(USER="gui-fixture", LOGNAME="gui-fixture")
        for variable in (
            "DBUS_SESSION_BUS_ADDRESS",
            "DBUS_SYSTEM_BUS_ADDRESS",
            "PULSE_SERVER",
            "PIPEWIRE_REMOTE",
        ):
            self.environment.pop(variable, None)
        for variable in (
            "HOME",
            "XDG_CONFIG_HOME",
            "XDG_CACHE_HOME",
            "XDG_DATA_HOME",
            "XDG_RUNTIME_DIR",
        ):
            directory = self.root / variable.lower()
            directory.mkdir(mode=0o700)
            self.environment[variable] = str(directory)
        settings = Path(self.environment["XDG_CONFIG_HOME"]) / "awesome"
        (Path(self.environment["HOME"]) / ".config").symlink_to(
            self.environment["XDG_CONFIG_HOME"]
        )
        shutil.copytree(
            CONFIG,
            settings,
            symlinks=True,
            ignore=shutil.ignore_patterns(
                ".git", ".venv", "__pycache__", "*.log", "mails.txt"
            ),
        )
        self.state_file = self.root / "state.json"
        width, height, dpi = (
            os.environ.get("GUI_SCREEN", "1920x1080@96").replace("@", "x").split("x")
        )
        self.environment.update(
            GUI_CONFIG=str(settings),
            GUI_STATE=str(self.state_file),
            GUI_DPI=dpi,
        )
        if self._testMethodName == "test_offline_missing_hardware_and_recovery":
            self.environment["GUI_SCENARIO"] = "offline"
        read_fd, write_fd = os.pipe()
        try:
            server = subprocess.Popen(
                [
                    "Xvfb",
                    "-displayfd",
                    str(write_fd),
                    "-screen",
                    "0",
                    f"{width}x{height}x24",
                    "-nolisten",
                    "tcp",
                    "-dpi",
                    dpi,
                ],
                pass_fds=(write_fd,),
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            self.addCleanup(stop, server)
            self.assertTrue(
                select.select([read_fd], [], [], 10)[0], "Xvfb failed to start"
            )
            self.environment["DISPLAY"] = ":" + os.read(read_fd, 100).decode().strip()
        finally:
            os.close(read_fd)
            os.close(write_fd)
        bus = subprocess.Popen(
            ["dbus-daemon", "--session", "--nofork", "--print-address=1"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            env=self.environment,
        )
        self.addCleanup(bus.stdout.close)
        self.addCleanup(stop, bus)
        self.assertTrue(
            select.select([bus.stdout], [], [], 10)[0],
            "Session D-Bus failed to start",
        )
        self.environment["DBUS_SESSION_BUS_ADDRESS"] = bus.stdout.readline().strip()
        log = (self.artifacts / "awesome.log").open("w")
        self.addCleanup(log.close)
        self.process = subprocess.Popen(
            ["awesome", "--config", str(settings / "tests/gui_fixture.lua")],
            env=self.environment,
            stdout=log,
            stderr=log,
        )
        self.addCleanup(stop, self.process)
        self.wait(lambda: self.state_file.exists(), "Awesome center initialization")
        self.wait(lambda: self.state()["ready"], "Awesome startup and key grabs")
        self.assertIsNone(
            self.process.poll(), (self.artifacts / "awesome.log").read_text()
        )

    def wait(self, predicate, description, timeout=12):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            self.assertIsNone(
                self.process.poll(),
                (self.artifacts / "awesome.log").read_text(),
            )
            result = predicate()
            if result:
                return result
            time.sleep(0.05)
        self.fail(
            "Timed out waiting for "
            + description
            + "\n"
            + (self.artifacts / "awesome.log").read_text()
        )

    def lua(self, expression):
        result = subprocess.run(
            ["awesome-client"],
            input=expression,
            env=self.environment,
            capture_output=True,
            text=True,
            check=True,
            timeout=10,
        )
        self.assertNotIn("Error", result.stdout + result.stderr)

    def state(self):
        self.lua("gui_test.dump()")
        return json.loads(self.state_file.read_text())

    def xdo(self, *arguments):
        subprocess.run(
            ["xdotool", *map(str, arguments)],
            env=self.environment,
            capture_output=True,
            text=True,
            check=True,
            timeout=10,
        )

    def super_key(self, key):
        self.xdo("keydown", "Super_L", "key", key, "keyup", "Super_L")

    def open(self, name):
        self.super_key("c" if name == "control" else "i")
        return self.wait(
            lambda: (state := self.state())[name]["visible"] and state,
            name + " opens",
        )

    def widget(self, panel, identifier):
        return self.wait(
            lambda: next(
                (
                    widget
                    for widget in self.state()[panel]["widgets"]
                    if widget.get("id") == identifier and widget["width"] > 0
                ),
                None,
            ),
            identifier + " allocation",
        )

    def assert_bounds(self, state, name):
        panel, area = state[name], state["workarea"]
        self.assertTrue(panel["visible"])
        self.assertGreaterEqual(panel["x"], area["x"])
        self.assertGreaterEqual(panel["y"], area["y"])
        self.assertLessEqual(panel["x"] + panel["width"], area["x"] + area["width"])
        self.assertLessEqual(panel["y"] + panel["height"], area["y"] + area["height"])
        expected = min(
            max(state["screen"]["width"] / 6, 480 * state["dpi"] / 96),
            area["width"] - 4 * state["gap"],
        )
        self.assertAlmostEqual(panel["width"], int(expected), delta=2)

    def assert_widget_inside(self, state, name, widget):
        panel = state[name]
        self.assertGreater(widget["height"], 0)
        self.assertGreater(widget["width"], 0)
        self.assertGreaterEqual(widget["x"], panel["x"] - 1)
        self.assertGreaterEqual(widget["y"], panel["y"] - 1)
        self.assertLessEqual(
            widget["x"] + widget["width"], panel["x"] + panel["width"] + 1
        )
        self.assertLessEqual(
            widget["y"] + widget["height"], panel["y"] + panel["height"] + 1
        )

    def capture(self, label):
        subprocess.run(
            [
                "import",
                "-window",
                "root",
                str(self.artifacts / (label + ".png")),
            ],
            env=self.environment,
            capture_output=True,
            timeout=10,
            check=True,
        )
        (self.artifacts / (label + ".json")).write_text(
            json.dumps(self.state(), indent=2)
        )

    def tearDown(self):
        if self.process.poll() is None and self.state_file.exists():
            self.capture("final")
            self.assertFalse(
                self.state()["errors"],
                "Runtime error or unexpected external command: "
                + str(self.state()["errors"]),
            )

    def test_centers_fit_and_real_keymaps_are_exclusive(self):
        for name, other in (("control", "info"), ("info", "control")):
            state = self.open(name)
            self.assert_bounds(state, name)
            self.assertFalse(state[other]["visible"])
            self.capture(name)
        state = self.state()
        for height in state["sections"].values():
            self.assertGreater(
                height,
                0,
                "Info section collapsed to an unreachable zero-height viewport",
            )
        for title in (
            "Notification Center",
            "Email",
            "Stocks",
            "Calendar",
            "Weather",
        ):
            header = self.wait(
                lambda: next(
                    (
                        widget
                        for widget in self.state()["info"]["widgets"]
                        if widget.get("text") == title
                    ),
                    None,
                ),
                title + " header",
            )
            self.assert_widget_inside(self.state(), "info", header)
        for identifier in ("volume_slider", "brightness_slider", "mode_switch"):
            if not self.state()["control"]["visible"]:
                self.open("control")
            self.assert_widget_inside(
                self.state(), "control", self.widget("control", identifier)
            )

    def test_slider_drag_mode_switch_and_outside_click(self):
        self.open("control")
        for identifier, field in (
            ("volume_slider", "volume"),
            ("brightness_slider", "brightness"),
        ):
            widget = self.widget("control", identifier)
            self.assert_widget_inside(self.state(), "control", widget)
            initial = self.state()[field]
            self.xdo(
                "mousemove",
                int(widget["x"] + widget["width"] * 0.4),
                int(widget["y"] + widget["height"] / 2),
                "mousedown",
                "1",
                "mousemove",
                int(widget["x"] + widget["width"] * 0.8),
                int(widget["y"] + widget["height"] / 2),
                "mouseup",
                "1",
            )
            self.wait(
                lambda: abs(self.state()[field] - initial) > 5,
                field + " backend receives drag",
            )
        switch = self.widget("control", "mode_switch")
        self.xdo(
            "mousemove",
            int(switch["x"] + switch["width"] / 2),
            int(switch["y"] + switch["height"] / 2),
            "click",
            "1",
        )
        monitor = self.widget("control", "monitor_control")
        self.assertTrue(monitor["visible"])
        self.assert_widget_inside(self.state(), "control", monitor)
        self.capture("monitor-mode")
        self.xdo("mousemove", "20", "200", "click", "1")
        self.wait(
            lambda: not self.state()["control"]["visible"],
            "outside click closes control center",
        )

    def test_offline_missing_hardware_and_recovery(self):
        self.assertFalse(self.state()["machine"]["battery"])
        self.assertFalse(self.state()["machine"]["keyboard_backlight"])
        self.open("control")
        self.wait(
            lambda: any(
                widget.get("text") == "Unavailable"
                for widget in self.state()["control"]["widgets"]
            ),
            "unavailable hardware state rendered",
        )
        self.open("info")
        self.lua(
            "awesome.emit_signal('widget::update_stocks'); awesome.emit_signal('widget::weather_fetch'); "
            "awesome.emit_signal('module::email:show')"
        )
        self.wait(
            lambda: any(
                widget.get("text") == "Error"
                for widget in self.state()["info"]["widgets"]
            ),
            "offline stocks error rendered",
        )
        self.assert_bounds(self.state(), "info")
        self.wait(
            lambda: any(
                widget.get("text") == "Failed to fetch"
                for widget in self.state()["info"]["widgets"]
            ),
            "weather unavailable state rendered",
        )
        self.wait(
            lambda: any(
                "Check network connection!" in widget.get("text", "")
                for widget in self.state()["info"]["widgets"]
            ),
            "email offline state rendered",
        )
        self.capture("offline")
        self.lua(
            "gui_test.scenario = 'success'; awesome.emit_signal('widget::update_stocks'); "
            "awesome.emit_signal('widget::weather_fetch'); awesome.emit_signal('module::email:show')"
        )
        self.wait(
            lambda: any(
                "123.45" in widget.get("text", "")
                for widget in self.state()["info"]["widgets"]
            ),
            "stocks recover after service returns",
        )
        self.assert_bounds(self.state(), "info")

    def test_populated_lists_scroll_to_last_item(self):
        self.open("info")
        self.wait(
            lambda: any(
                "123.45" in widget.get("text", "")
                for widget in self.state()["info"]["widgets"]
            ),
            "populated stocks",
        )
        for identifier, marker in (
            ("stocks_section", "GUI_LAST"),
            ("email_section", "café 8"),
        ):
            section = self.widget("info", identifier)
            self.assert_widget_inside(self.state(), "info", section)
            self.xdo(
                "mousemove",
                int(section["x"] + section["width"] / 2),
                int(section["y"] + section["height"] * 0.75),
                "click",
                "--repeat",
                "25",
                "--delay",
                "20",
                "5",
            )

            def last_visible():
                state = self.state()
                current = next(
                    widget
                    for widget in state["info"]["widgets"]
                    if widget.get("id") == identifier
                )
                return next(
                    (
                        widget
                        for widget in state["info"]["widgets"]
                        if marker in widget.get("text", "")
                        and widget["height"] > 0
                        and widget["y"] >= current["y"]
                        and widget["y"] + widget["height"]
                        <= current["y"] + current["height"] + 1
                    ),
                    None,
                )

            self.wait(last_visible, marker + " reachable by mouse-wheel scrolling")
        self.capture("last-list-items")

    def test_weather_fallback_and_close_during_refresh(self):
        self.lua("gui_test.scenario = 'fallback'")
        self.open("info")
        self.wait(
            lambda: any(
                "Fixture fallback sunshine" in widget.get("text", "")
                for widget in self.state()["info"]["widgets"]
            ),
            "weather provider fallback",
        )
        self.lua("gui_test.scenario = 'slow'")
        initial = self.state()["completed"]
        self.lua("awesome.emit_signal('widget::update_stocks')")
        self.super_key("i")
        self.wait(
            lambda: not self.state()["info"]["visible"],
            "close during pending refresh",
        )
        self.wait(
            lambda: self.state()["completed"] > initial,
            "pending refresh completes",
        )
        self.assertFalse(
            self.state()["info"]["visible"], "Late response reopened the panel"
        )
        self.lua("gui_test.scenario = 'success'")
        self.assert_bounds(self.open("info"), "info")


if __name__ == "__main__":
    unittest.main(verbosity=2)
