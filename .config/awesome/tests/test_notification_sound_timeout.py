#!/usr/bin/env python3
"""Exercise the real playback watchdog against a player that ignores SIGTERM."""

import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest


class NotificationSoundTimeoutTest(unittest.TestCase):
    def test_hung_player_is_killed_and_backend_is_explicit(self):
        helper = Path.home() / '.config/awesome/library/notification-sound.lua'
        lua = '''
package.loaded.awful = { spawn = { easy_async = function(argv)
    io.write(table.concat(argv, "\\0")); return 123
end } }
local sound = dofile(arg[1])
assert(sound.play('message', { app_name = 'test', id = 42, title = 'hung player' }))
'''
        command = subprocess.run(
            ['lua', '-', str(helper)], input=lua, text=True,
            capture_output=True, check=True,
        ).stdout.split('\0')
        with tempfile.TemporaryDirectory(prefix='notification-sound-') as directory:
            player = Path(directory) / 'canberra-gtk-play'
            player.write_text('''#!/usr/bin/env python3
import os, signal, time
signal.signal(signal.SIGTERM, signal.SIG_IGN)
print(os.environ.get('CANBERRA_DRIVER'), flush=True)
time.sleep(60)
''')
            player.chmod(0o700)
            started = time.monotonic()
            result = subprocess.run(
                command, env={**os.environ, 'PATH': directory + ':' + os.environ['PATH']},
                capture_output=True, text=True, timeout=10,
            )
            elapsed = time.monotonic() - started
        self.assertEqual(result.stdout.strip(), 'pulse')
        self.assertEqual(result.returncode, -9, result.stderr)
        self.assertGreaterEqual(elapsed, 5)
        self.assertLess(elapsed, 9)


if __name__ == '__main__':
    unittest.main()
