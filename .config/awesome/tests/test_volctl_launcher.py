"""Run the real launcher with bare venvs, real schema compilation, and no GUI."""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

LAUNCHER = (
    Path(sys.argv.pop(1)).resolve()
    if len(sys.argv) > 1
    else Path(__file__).resolve().parents[1] / "utilities/desktop/volctl"
)
SCHEMA = """<schemalist>
  <schema id="apps.volctl" path="/apps/volctl/">
    <key name="enabled" type="b"><default>true</default></key>
  </schema>
</schemalist>
"""
ENTRYPOINT = """#!/usr/bin/env python3
import json, os
from pathlib import Path
schemas = Path(os.environ["GSETTINGS_SCHEMA_DIR"])
assert (schemas / "apps.volctl.gschema.xml").is_file()
assert (schemas / "gschemas.compiled").is_file()
Path(os.environ["LAUNCH_LOG"]).write_text(json.dumps({
    "cwd": os.getcwd(), "schemas": str(schemas),
    "data_dirs": os.environ["XDG_DATA_DIRS"],
}))
"""
UV = """#!/usr/bin/env python3
import json, os, shutil, sys
from pathlib import Path
args = sys.argv[1:]
with open(os.environ["UV_LOG"], "a") as log:
    log.write(json.dumps(args) + "\\n")
if args[0] == "venv":
    target = Path(args[-1])
    (target / "bin").mkdir(parents=True)
    (target / "bin/python").symlink_to(sys.executable)
elif args[:2] == ["pip", "install"]:
    python = Path(args[args.index("--python") + 1])
    assert python.is_file()
    if "--editable" in args:
        entrypoint = python.parent / "volctl"
        shutil.copyfile(os.environ["MOCK_ENTRYPOINT"], entrypoint)
        entrypoint.chmod(0o755)
else:
    raise AssertionError(args)
"""


def executable(path, content):
    path.write_text(content)
    path.chmod(0o755)


class LauncherTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="volctl-launcher-")
        self.addCleanup(self.tmp.cleanup)
        root = Path(self.tmp.name)
        self.home = root / "home with spaces"
        self.source = self.home / ".config/awesome/library/volctl"
        (self.source / "data").mkdir(parents=True)
        (self.source / "data/apps.volctl.gschema.xml").write_text(SCHEMA)
        self.bin = root / "bin"
        self.bin.mkdir()
        self.cwd = root / "unrelated working directory"
        self.cwd.mkdir()
        self.launch_log = root / "launched.json"
        self.uv_log = root / "uv.jsonl"
        entrypoint = root / "mock-volctl"
        executable(entrypoint, ENTRYPOINT)
        executable(self.bin / "uv", UV)
        executable(self.bin / "pgrep", '#!/bin/sh\nexit "${MOCK_RUNNING:-1}"\n')
        executable(self.bin / "sleep", "#!/bin/sh\nexit 0\n")
        self.env = dict(
            os.environ,
            HOME=str(self.home),
            PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
            LAUNCH_LOG=str(self.launch_log),
            UV_LOG=str(self.uv_log),
            MOCK_ENTRYPOINT=str(entrypoint),
            GSETTINGS_BACKEND="memory",
        )

    def bare_venv(self):
        binary = self.source / "venv/bin"
        binary.mkdir(parents=True)
        (binary / "python").symlink_to(sys.executable)

    def launch(self):
        return subprocess.run(
            ["bash", str(LAUNCHER)],
            cwd=self.cwd,
            env=self.env,
            capture_output=True,
            text=True,
            timeout=20,
            check=False,
        )

    def assert_started(self):
        result = self.launch()
        self.assertEqual(result.returncode, 0, result.stderr)
        record = json.loads(self.launch_log.read_text())
        schemas = self.source / "venv/share/glib-2.0/schemas"
        self.assertEqual(record["cwd"], str(self.source))
        self.assertEqual(record["schemas"], str(schemas))
        self.assertEqual(record["data_dirs"], "/usr/local/share:/usr/share")
        self.assertEqual((schemas / "apps.volctl.gschema.xml").read_text(), SCHEMA)
        settings = subprocess.run(
            [
                "gsettings",
                "--schemadir",
                str(schemas),
                "get",
                "apps.volctl",
                "enabled",
            ],
            env=self.env,
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        self.assertEqual(settings.returncode, 0, settings.stderr)
        self.assertEqual(settings.stdout.strip(), "true")

    def test_fresh_venv_without_share_parents(self):
        self.assert_started()
        commands = [json.loads(line) for line in self.uv_log.read_text().splitlines()]
        self.assertEqual(commands[0][0], "venv")

    def test_existing_bare_venv_and_repeated_launch(self):
        self.bare_venv()
        self.assert_started()
        self.assert_started()
        commands = [json.loads(line) for line in self.uv_log.read_text().splitlines()]
        self.assertTrue(all(command[0] == "pip" for command in commands))

    def test_running_instance_skips_installation(self):
        self.env["MOCK_RUNNING"] = "0"
        result = self.launch()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.uv_log.exists())
        self.assertFalse(self.launch_log.exists())

    def test_invalid_schema_stops_before_app_launch(self):
        self.bare_venv()
        (self.source / "venv/share/glib-2.0/schemas").mkdir(parents=True)
        (self.source / "data/apps.volctl.gschema.xml").write_text("<invalid>")
        result = self.launch()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.launch_log.exists())


if __name__ == "__main__":
    for tool in ("glib-compile-schemas", "gsettings"):
        if not shutil.which(tool):
            raise SystemExit(f"Required test dependency missing: {tool}")
    unittest.main()
