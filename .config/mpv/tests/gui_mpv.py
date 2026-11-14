"""Exercise the real mpv/uosc window on a private X display."""

import json
import os
import select
import shutil
import socket
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

CONFIG = Path(__file__).resolve().parents[1]
ARTIFACTS = Path(os.environ.get("GUI_ARTIFACTS", "test-logs/mpv-gui")).resolve()


def wait_for(predicate, description, timeout=12):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        result = predicate()
        if result:
            return result
        time.sleep(0.05)
    raise AssertionError("Timed out waiting for " + description)


def stop(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)


class MpvGuiTests(unittest.TestCase):
    def setUp(self):
        for executable in ("Xvfb", "mpv", "xdotool", "ffmpeg"):
            self.assertIsNotNone(
                shutil.which(executable),
                "Missing GUI dependency: " + executable,
            )
        self.temporary = tempfile.TemporaryDirectory(prefix="mpv-gui-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.artifacts = ARTIFACTS / self._testMethodName
        self.artifacts.mkdir(parents=True, exist_ok=True)
        self.environment = dict(os.environ)
        for variable in (
            "DBUS_SESSION_BUS_ADDRESS",
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
        read_fd, write_fd = os.pipe()
        try:
            server = subprocess.Popen(
                [
                    "Xvfb",
                    "-displayfd",
                    str(write_fd),
                    "-screen",
                    "0",
                    "1280x800x24",
                    "-nolisten",
                    "tcp",
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
        source = Path(os.environ.get("MPV_GUI_UOSC", CONFIG / "scripts/uosc")).resolve()
        self.assertTrue(
            (source / "main.lua").is_file(),
            "Set MPV_GUI_UOSC to an extracted uosc 5.13.0 script directory",
        )
        self.assertIn(
            "'5.13.0'",
            (source / "main.lua").read_text(),
            "GUI fixtures target uosc 5.13.0",
        )
        settings = self.root / "mpv"
        settings.mkdir()
        shutil.copyfile(CONFIG / "input.conf", settings / "input.conf")
        shutil.copyfile(CONFIG / "mpv.conf", settings / "mpv.conf")
        shutil.copytree(source, settings / "scripts/uosc")
        with (settings / "scripts/uosc/main.lua").open("a") as script:
            script.write("\n" + Path(__file__).with_name("gui_probe.lua").read_text())
        font_source = source.parents[1] / "fonts"
        self.assertTrue(
            font_source.is_dir(),
            "uosc fonts must accompany the scripts directory",
        )
        shutil.copytree(font_source, settings / "fonts")
        options = settings / "script-opts"
        options.mkdir()
        (options / "uosc.conf").write_text("animation_duration=0\nlanguages=en\n")
        self.requests = self.root / "requests.jsonl"
        self.scenario = self.root / "scenario"
        self.scenario.write_text("success")
        self.environment.update(
            GUI_REQUESTS=str(self.requests),
            GUI_SCENARIO=str(self.scenario),
            MPV_UOSC_ZIGGY=str(Path(__file__).with_name("gui_subtitle_backend.py")),
        )
        media = self.root / "Fixture Movie.mkv"
        chapters = self.root / "chapters.txt"
        chapters.write_text(
            ";FFMETADATA1\n[CHAPTER]\nTIMEBASE=1/1000\nSTART=0\nEND=30000\ntitle=First\n"
            "[CHAPTER]\nTIMEBASE=1/1000\nSTART=30000\nEND=60000\ntitle=Second\n"
        )
        subprocess.run(
            [
                "ffmpeg",
                "-loglevel",
                "error",
                "-f",
                "lavfi",
                "-i",
                "color=c=0x203040:s=640x360:r=5:d=60",
                "-i",
                str(chapters),
                "-map_metadata",
                "1",
                "-map_chapters",
                "1",
                "-c:v",
                "ffv1",
                str(media),
            ],
            check=True,
            timeout=30,
        )
        self.socket_path = self.root / "mpv.sock"
        log = (self.artifacts / "mpv.log").open("w")
        self.addCleanup(log.close)
        self.process = subprocess.Popen(
            [
                "mpv",
                "--config-dir=" + str(settings),
                "--load-scripts=no",
                "--script=" + str(settings / "scripts/uosc"),
                "--vo=x11",
                "--ao=null",
                "--hwdec=no",
                "--display-fps-override=60",
                "--msg-level=all=warn,uosc=info",
                "--pause",
                "--keep-open=yes",
                "--save-position-on-quit=no",
                "--watch-later-directory=" + str(self.root / "watch-later"),
                "--log-file=" + str(self.artifacts / "runtime.log"),
                "--input-ipc-server=" + str(self.socket_path),
                "--title=mpv-gui-test",
                "--geometry=960x600+20+20",
                str(media),
            ],
            env=self.environment,
            stdout=log,
            stderr=log,
        )
        self.addCleanup(stop, self.process)
        wait_for(
            lambda: self.socket_path.exists() or self.process.poll() is not None,
            "mpv IPC",
        )
        self.assertIsNone(self.process.poll(), (self.artifacts / "mpv.log").read_text())
        self.connection = socket.socket(socket.AF_UNIX)
        self.connection.settimeout(8)
        self.connection.connect(str(self.socket_path))
        self.addCleanup(self.connection.close)
        self.stream = self.connection.makefile("rb")
        self.addCleanup(self.stream.close)
        self.request_id = 0
        self.window = wait_for(self.find_window, "mpv window")
        self.xdo("windowfocus", "--sync", self.window)
        wait_for(
            lambda: any(
                binding.get("owner") == "uosc" for binding in self.get("input-bindings")
            ),
            "uosc input bindings",
        )

    def xdo(self, *arguments):
        return subprocess.run(
            ["xdotool", *map(str, arguments)],
            env=self.environment,
            capture_output=True,
            text=True,
            check=True,
            timeout=10,
        ).stdout

    def find_window(self):
        result = subprocess.run(
            ["xdotool", "search", "--onlyvisible", "--name", "^mpv-gui-test$"],
            env=self.environment,
            capture_output=True,
            text=True,
            timeout=5,
        )
        return result.stdout.splitlines()[0] if result.returncode == 0 else None

    def command(self, *arguments):
        self.request_id += 1
        self.connection.sendall(
            (
                json.dumps({"command": arguments, "request_id": self.request_id}) + "\n"
            ).encode()
        )
        while True:
            line = self.stream.readline()
            self.assertTrue(line, "mpv closed its IPC connection")
            response = json.loads(line)
            if response.get("request_id") == self.request_id:
                self.assertEqual(response.get("error"), "success", str(response))
                return response.get("data")

    def get(self, name):
        return self.command("get_property", name)

    def menu(self):
        return self.get("user-data").get("uosc", {}).get("menu", {}).get("type")

    def probe(self):
        generation = str(self.request_id + 1)
        self.command("script-message-to", "uosc", "gui-probe", generation)

        def observed():
            result = self.get("user-data").get("gui-probe", {})
            return result if result.get("generation") == generation else None

        return wait_for(observed, "GUI observation")

    def wait_results(self, expected):
        return wait_for(
            lambda: any(
                expected in item.get("title", "") for item in self.probe()["items"]
            ),
            "subtitle results: " + expected,
        )

    def key(self, key):
        self.xdo("key", "--clearmodifiers", key)

    def requests_for(self, command):
        if not self.requests.exists():
            return []
        return [
            entry
            for line in self.requests.read_text().splitlines()
            if (entry := json.loads(line))[0] == command
        ]

    def capture(self):
        if hasattr(self, "connection") and self.process.poll() is None:
            try:
                self.command(
                    "screenshot-to-file",
                    str(self.artifacts / "window.png"),
                    "window",
                )
            except (OSError, AssertionError):
                pass
        if self.requests.exists():
            shutil.copyfile(self.requests, self.artifacts / "requests.jsonl")
        if hasattr(self, "connection") and self.process.poll() is None:
            (self.artifacts / "state.json").write_text(
                json.dumps(self.probe(), indent=2)
            )

    def tearDown(self):
        self.capture()
        self.assertIsNone(self.process.poll(), "mpv unexpectedly exited")
        runtime = (self.artifacts / "runtime.log").read_text()
        self.assertNotIn("Lua error", runtime)
        self.assertNotIn("stack traceback", runtime)

    def open_search(self):
        self.key("shift+d")
        wait_for(
            lambda: self.menu() == "download-subtitles",
            "Shift+D subtitle search",
        )
        wait_for(
            lambda: self.requests_for("search-subtitles"),
            "suggested-title search",
        )

    def search(self, query):
        self.key("shift+BackSpace")
        self.xdo("type", "--clearmodifiers", "--delay", "15", query)
        self.key("Return")
        wait_for(
            lambda: self.probe()["query"] == query,
            "edited query in search input",
        )
        return wait_for(
            lambda: next(
                (
                    request
                    for request in self.requests_for("search-subtitles")
                    if "--query" in request
                    and request[request.index("--query") + 1] == query
                ),
                None,
            ),
            "edited search query",
        )

    def test_subtitle_search_edit_select_and_load(self):
        self.open_search()
        self.search("Edited GUI Movie")
        self.wait_results("GUI Fixture English")
        self.key("Down")
        self.key("Return")
        downloads = wait_for(
            lambda: self.requests_for("download-subtitles"),
            "selected subtitle download",
        )
        self.assertEqual(downloads[-1][downloads[-1].index("--file-id") + 1], "42")
        wait_for(
            lambda: any(
                track["type"] == "sub" and track.get("selected")
                for track in self.get("track-list")
            ),
            "selected subtitle track",
        )
        self.assertTrue(self.get("sub-visibility"))
        self.key("Escape")
        wait_for(lambda: not self.menu(), "subtitle result closes")

    def test_search_failure_empty_results_and_recovery(self):
        self.scenario.write_text("failure")
        self.open_search()
        self.search("Failure")
        self.wait_results("Something went wrong")
        self.scenario.write_text("empty")
        self.search("No matches")
        self.wait_results("no results")
        self.assertFalse(self.requests_for("download-subtitles"))
        self.scenario.write_text("success")
        self.search("Recovered")
        self.wait_results("GUI Fixture English")
        self.key("Down")
        self.key("Return")
        wait_for(
            lambda: self.requests_for("download-subtitles"),
            "download after recovery",
        )

    def test_menu_navigation_resize_and_mouse(self):
        self.key("alt+m")
        wait_for(lambda: bool(self.menu()), "main menu")
        self.key("Down")
        self.key("Up")
        self.xdo("windowsize", "--sync", self.window, "640", "480")
        wait_for(lambda: self.probe()["width"] == 640, "resized UI viewport")
        self.assertTrue(self.menu(), "Resize unexpectedly closed the menu")
        state = self.probe()
        self.assertGreater(state["bx"] - state["ax"], 0)
        self.assertGreaterEqual(state["ax"], 0)
        self.assertGreaterEqual(state["ay"], 0)
        self.assertLessEqual(state["bx"], state["width"])
        self.assertLessEqual(state["by"], state["height"])
        self.command(
            "screenshot-to-file",
            str(self.artifacts / "resized-menu.png"),
            "window",
        )
        self.key("Escape")
        wait_for(lambda: not self.menu(), "menu closes")
        self.xdo("mousemove", "--window", self.window, "300", "180", "click", "3")
        wait_for(lambda: bool(self.menu()), "right-click menu")
        self.key("Escape")
        wait_for(lambda: not self.menu(), "mouse menu closes")

    def test_playback_keymaps_and_search_do_not_leak(self):
        initial_volume = self.get("volume")
        self.key("j")
        wait_for(lambda: self.get("volume") > initial_volume, "j raises volume")
        self.key("k")
        wait_for(
            lambda: abs(self.get("volume") - initial_volume) < 0.1,
            "k restores volume",
        )
        initial_visibility = self.get("sub-visibility")
        self.key("v")
        wait_for(
            lambda: self.get("sub-visibility") != initial_visibility,
            "v toggles subtitles",
        )
        self.command("set_property", "time-pos", 20)
        self.key("shift+j")
        wait_for(lambda: self.get("chapter") == 1, "J selects next chapter")
        self.key("shift+k")
        wait_for(lambda: self.get("chapter") == 0, "K selects previous chapter")
        self.command("set_property", "time-pos", 20)
        self.key("l")
        wait_for(lambda: self.get("time-pos") >= 24, "l seeks forward")
        self.key("h")
        wait_for(lambda: self.get("time-pos") < 24, "h seeks backward")
        self.open_search()
        self.search("jkhvl")
        self.assertAlmostEqual(self.get("volume"), initial_volume)

    def test_late_search_does_not_reopen_closed_menu(self):
        self.scenario.write_text("slow")
        self.open_search()
        self.key("Escape")
        wait_for(lambda: not self.menu(), "close pending search")
        self.scenario.write_text("success")
        self.open_search()
        self.wait_results("GUI Fixture English")
        self.assertEqual(self.probe()["menu"], "download-subtitles")

    def test_uosc_keymaps_are_unique_and_present(self):
        mappings = {}
        for line in (CONFIG / "input.conf").read_text().splitlines():
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            key, command = stripped.split(None, 1)
            self.assertNotIn(key, mappings, "Duplicate configured key: " + key)
            mappings[key] = " ".join(command.split())
        self.assertEqual(mappings["D"], "script-binding uosc/download-subtitles")
        self.assertEqual(mappings["alt+m"], "script-binding uosc/menu")
        active = {
            " ".join(binding.get("cmd", "").split())
            for binding in self.get("input-bindings")
        }
        for command in mappings.values():
            if command.startswith("script-binding uosc/"):
                self.assertIn(command, active, "Missing live uosc keymap: " + command)


if __name__ == "__main__":
    unittest.main(verbosity=2)
