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


class CenterGuiFixture(unittest.TestCase):
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
            GSETTINGS_BACKEND="memory",
        )
        if self._testMethodName.startswith("test_live_theme"):
            self.environment["GUI_INITIAL_SCHEME"] = "prefer-light"
        if self._testMethodName == "test_live_theme_notifications":
            self.environment["GUI_NOTIFICATIONS"] = "1"
            for theme in ("Solarized-FLAT-Blue", "Solarized-Dark-Green-Numix"):
                directory = Path(self.environment["XDG_DATA_HOME"]) / "icons" / theme
                apps = directory / "32x32/apps"
                apps.mkdir(parents=True)
                (directory / "index.theme").write_text(
                    f"[Icon Theme]\nName={theme}\nDirectories=32x32/apps\n"
                    "[32x32/apps]\nSize=32\nType=Fixed\nContext=Applications\n"
                )
                for name in ("gui-notify", "gui-action"):
                    shutil.copyfile(settings / "theme/icons/close.svg", apps / f"{name}.svg")
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


class CenterGuiTests(CenterGuiFixture):
    def test_playerctl_displays_plain_metadata(self):
        self.lua("""
            local player = require('widget.playerctl')
            local title, artist = 'Rock <Live>', 'Hall & Oates'
            require('library.playerctl'):emit_signal('metadata', title, artist, '', '', 'fixture')
            local displayed = {}
            for _, widget in ipairs(player:get_all_children()) do
                if widget.get_text then displayed[widget.text] = true end
            end
            assert(displayed[title] and displayed[artist], 'Playerctl reinterpreted plain metadata as markup')
        """)

    def test_live_theme_notifications(self):
        self.lua("gui_test.check_notifications = require('tests.gui_notification_theme')")
        for mode in ("prefer-light", "prefer-dark", "prefer-light"):
            self.lua(f"assert(gui_test.settings:set_string('color-scheme', '{mode}'))")
            self.lua("gui_test.check_notifications()")

    def test_email_popup_fits_unread_icon(self):
        self.lua("""
            local widgets = require('wibox').widget
            local alpha = require('lgi').cairo.Format.A8
            local popup = require('widget.notification-icon').popup
            local path = require('gears.filesystem').get_configuration_dir() .. 'widget/email/icons/email-unread.svg'
            local reference = widgets.imagebox(path)
            local function save_mask(view, size, name)
                local mask = widgets.draw_to_image_surface(view, size, size, alpha)
                mask:write_to_png(os.getenv('XDG_RUNTIME_DIR') .. '/' .. name .. size .. '.png')
            end
            for _, size in ipairs({ 32, 64 }) do
                local message = require('naughty').notification {
                    app_name = 'Email', icon = path, icon_size = size, ignore = true,
                }
                assert(reference.source_width > size)
                save_mask(reference, size, 'expected')
                save_mask(popup(message), size, 'popup')
                message:destroy()
            end
        """)
        runtime = Path(self.environment["XDG_RUNTIME_DIR"])
        for size in (32, 64):
            self.assertTrue(
                (runtime / f"popup{size}.png").read_bytes()
                == (runtime / f"expected{size}.png").read_bytes(),
                f"Unread envelope clipped at {size}px",
            )

    def test_live_theme_preserves_open_center(self):
        self.open("info")
        self.lua("""
            local panel = screen.primary.info_center
            local section = gui_test.targets.email_section
            local surface = assert(panel.widget:get_children_by_id('info_center')[1])
            local colors = require('gears.color')
            local theme = require('beautiful')
            local indicator = require('awful').widget.layoutbox { screen = screen.primary }
            require('widget.layoutbox')(screen.primary)
            local tip = indicator._layoutbox_tooltip
            local visible_tip = require('theme.tooltip').new { text = 'Open during appearance changes' }
            visible_tip.visible = true
            local scheduled = require('gears.filesystem').get_configuration_dir() .. 'theme/wallpapers/pm_02.jpg'
            theme.wallpaper = scheduled
            local layout_icon = indicator.imagebox
            local png = theme.layout_tile
            local native = require('wibox').widget.imagebox(png)
            local alert = require('widget.notification-icon')
            local root_dir = require('gears.filesystem').get_configuration_dir()
            local touchpad = root_dir .. 'theme/icons/touchpad/input-touchpad-disabled.svg'
            local message = require('gears.object')()
            message.icon = touchpad
            local icon_view = alert.popup(message)
            local own_icon = icon_view.widget
            assert(own_icon._private.symbolic_source == touchpad)
            message.icon = png
            message:emit_signal('property::icon')
            assert(icon_view.widget ~= own_icon and icon_view.widget.set_notification)
            message.icon = touchpad
            message:emit_signal('property::icon')
            assert(icon_view.widget == own_icon and not alert.source('/usr/share/icons/firefox.svg'))
            local widget = require('wibox').widget
            local function image_bytes(box)
                local pixels = widget.draw_to_image_surface(box, 32, 32)
                local path = os.getenv('XDG_RUNTIME_DIR') .. '/theme-probe.png'
                pixels:write_to_png(path)
                local file = assert(io.open(path, 'rb'))
                local bytes = file:read('*a')
                file:close()
                return bytes
            end
            local original_art = image_bytes(native)
            local expected = {}
            local alert_ink = {}
            function gui_test.check_theme(ink, background)
                assert(panel == screen.primary.info_center and panel.visible and panel.opened)
                assert(section == require('widget.email') and section == gui_test.targets.email_section)
                assert(theme.fg_normal == ink and theme.background == background)
                assert(theme.wallpaper == scheduled, 'Theme change discarded the scheduled wallpaper')
                assert(colors.to_rgba_string(tip.backgroundbox.bg) == colors.to_rgba_string(theme.tooltip_bg))
                assert(colors.to_rgba_string(tip.backgroundbox.fg) == colors.to_rgba_string(theme.tooltip_fg))
                assert(visible_tip.visible and colors.to_rgba_string(visible_tip.backgroundbox.bg)
                    == colors.to_rgba_string(theme.tooltip_bg), 'Open tooltip was hidden or kept its old background')
                assert(colors.to_rgba_string(surface.bg) == colors.to_rgba_string(background))
                assert(colors.to_rgba_string(section.bg) == colors.to_rgba_string(theme.groups_bg))
                local bytes = image_bytes(layout_icon)
                assert(image_bytes(native) == original_art)
                if expected[ink] then assert(bytes == expected[ink]) end
                for other, previous in pairs(expected) do
                    if other ~= ink then
                        assert(bytes ~= previous and image_bytes(own_icon) ~= alert_ink[other])
                    end
                end
                expected[ink] = bytes
                alert_ink[ink] = image_bytes(own_icon)
            end
            gui_test.check_theme('#073642', '#fdf6e366')
        """)
        for mode, ink, background in (
            ("prefer-dark", "#eee8d5", "#002b3666"),
            ("prefer-light", "#073642", "#fdf6e366"),
        ):
            self.lua(f"assert(gui_test.settings:set_string('color-scheme', '{mode}'))")
            self.lua(f"gui_test.check_theme('{ink}', '{background}')")

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

    def test_profile_avatar_crop_and_square_slot(self):
        self.open("control")
        self.lua(
            """
            local cairo = require('lgi').cairo
            local profile = require('library.profile-image')
            local panel = require('awful').screen.focused().control_center
            local avatar
            local size = require('beautiful').xresources.apply_dpi(28)
            for _, widget in ipairs(panel.widget:get_all_children()) do
                if widget.get_source_width and widget.forced_height == size and widget._private.clip_shape then
                    avatar = widget
                    break
                end
            end
            assert(avatar, 'Control Center avatar not found')
            assert(avatar.forced_width == avatar.forced_height, 'Avatar slot is not square')
            assert(avatar:get_source_width() == avatar:get_source_height(), 'Default avatar is not square')
            local original = avatar._private.original_image
            local directory = assert(os.getenv('XDG_CACHE_HOME')) .. '/'
            local function contents(path)
                local input = assert(io.open(path, 'rb'))
                local data = input:read('*a')
                input:close()
                return data
            end
            local expected = cairo.ImageSurface.create(cairo.Format.ARGB32, 60, 60)
            local expected_context = cairo.Context(expected)
            expected_context:set_source_rgb(0, 1, 0)
            expected_context:paint()
            expected:write_to_png(directory .. 'avatar-expected.png')
            for _, dimensions in ipairs({ { 60, 100 }, { 100, 60 }, { 60, 60 } }) do
                local width, height = dimensions[1], dimensions[2]
                local image = cairo.ImageSurface.create(cairo.Format.ARGB32, width, height)
                local context = cairo.Context(image)
                context:set_source_rgb(1, 0, 0)
                context:paint()
                context:set_source_rgb(0, 1, 0)
                context:rectangle((width - 60) / 2, (height - 60) / 2, 60, 60)
                context:fill()
                image:write_to_png(directory .. 'avatar-source.png')
                local cropped = profile.square(directory .. 'avatar-source.png')
                assert(cropped:get_width() == 60 and cropped:get_height() == 60)
                cropped:write_to_png(directory .. 'avatar-actual.png')
                assert(contents(directory .. 'avatar-actual.png') == contents(directory .. 'avatar-expected.png'),
                    'Avatar is not center-cropped or reuses stale pixels')
                avatar:set_image(cropped)
                assert(avatar:get_source_width() == avatar:get_source_height())
            end
            avatar:set_image(original)
            """
        )
        self.assert_bounds(self.state(), "control")

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
