"""Run the checked-in unlock script with simulated desktop commands."""

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

HOME = Path(__file__).resolve().parents[3]
SCRIPT = HOME / ".local/bin/unlock"
# Only external commands are replaced. SCRIPT itself is executed unchanged.
MOCK_COMMANDS = r"""#!/usr/bin/python3
import os, pathlib, subprocess, sys
import json
root = pathlib.Path(os.environ['UNLOCK_TEST_ROOT'])
name = pathlib.Path(sys.argv[0]).name
if name == 'xdotool':
    (root / 'keys').write_text(json.dumps(sys.argv[1:]))
elif name == 'sleep':
    pass
elif name == 'awesome-client':
    query = sys.argv[1]
    locked = True
    if 'xdotool_chord' in sys.argv[1]:
        if os.environ['SCENARIO'] == 'chord-error':
            print('string "could not read shortcut"')
            sys.exit(0)
    else:
        count = int((root / 'count').read_text()) + 1
        (root / 'count').write_text(str(count))
        scenario = os.environ['SCENARIO']
        if scenario == 'query-error':
            print('string "boolean true is an invalid query result"')
            sys.exit(0)
        elif scenario == 'query-failure':
            sys.exit(1)
        else:
            unlocked = scenario == 'unlocked' or (scenario == 'transition' and count >= 3)
            locked = not unlocked
    # Execute the real query against the real Lua modules with a simulated
    # screen iterator. No running Awesome instance or X server is required.
    lua = '''
package.path = os.getenv("UNLOCK_TEST_HOME") .. "/.config/awesome/?.lua;" .. package.path
screen = function(_, previous)
    if previous then return nil end
    return { lockscreen = { visible = os.getenv("TEST_LOCKED") == "1" } }
end
local compile = loadstring or load
local result = assert(compile(os.getenv("TEST_QUERY")))()
if type(result) == "string" then
    print("   string " .. string.format("%q", result))
else
    print("   " .. type(result) .. " " .. tostring(result))
end
'''
    result = subprocess.run(['lua', '-e', lua],
        env=dict(os.environ, TEST_QUERY=query, TEST_LOCKED='1' if locked else '0'),
        capture_output=True, text=True, check=False)
    print(result.stdout, end='')
    print(result.stderr, end='', file=sys.stderr)
    sys.exit(result.returncode)
"""


class UnlockTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        query = (
            'package.path=os.getenv("UNLOCK_TEST_HOME").."/.config/awesome/?.lua;"..package.path; '
            'print(require("library.lockscreen-recovery-key").xdotool_chord())'
        )
        cls.chord = subprocess.check_output(
            ["lua", "-e", query],
            env=os.environ | {"UNLOCK_TEST_HOME": str(HOME)},
            text=True,
        ).strip()

    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        (self.root / "count").write_text("0")
        for command in ("awesome-client", "xdotool", "sleep"):
            path = self.root / command
            path.write_text(MOCK_COMMANDS)
            path.chmod(0o755)

    def run_helper(self, scenario):
        result = subprocess.run(
            ["bash", str(SCRIPT)],
            env=os.environ
            | {
                "PATH": str(self.root) + os.pathsep + os.environ["PATH"],
                "UNLOCK_TEST_ROOT": str(self.root),
                "UNLOCK_TEST_HOME": str(HOME),
                "SCENARIO": scenario,
            },
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        keys = self.root / "keys"
        sent = json.loads(keys.read_text()) if keys.exists() else None
        return result, sent

    def test_already_unlocked_sends_no_keys(self):
        result, sent = self.run_helper("unlocked")
        self.assertEqual(result.returncode, 0)
        self.assertIsNone(sent)

    def test_locked_helper_sends_exact_shared_chord_and_confirms_unlock(self):
        result, sent = self.run_helper("transition")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(sent, ["key", "--clearmodifiers", self.chord])
        self.assertIn("Screen unlocked", result.stdout)

    def test_persistently_locked_is_bounded_and_returns_failure(self):
        result, sent = self.run_helper("locked")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(sent, ["key", "--clearmodifiers", self.chord])
        self.assertEqual((self.root / "count").read_text(), "21")

    def test_query_errors_never_send_keys(self):
        for scenario in ("query-error", "query-failure", "chord-error"):
            with self.subTest(scenario=scenario):
                result, sent = self.run_helper(scenario)
                self.assertNotEqual(result.returncode, 0)
                self.assertIsNone(sent)


if __name__ == "__main__":
    unittest.main()
