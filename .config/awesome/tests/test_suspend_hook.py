import contextlib
import importlib.util
import io
import os
import types
from unittest import mock

path = os.path.join(
    os.environ['HOME'], '.config', 'awesome', 'utilities', 'suspend-hook.py'
)
spec = importlib.util.spec_from_file_location('suspend_hook', path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

with mock.patch.object(module.subprocess, 'run') as run:
    module.onPrepareForSleep(None, None, None, None, None, (True,), None)
    run.assert_not_called()

success = types.SimpleNamespace(returncode=0, stderr='')
with mock.patch.object(module.subprocess, 'run', return_value=success) as run:
    module.onPrepareForSleep(None, None, None, None, None, (False,), None)
    run.assert_called_once_with(
        [
            '/usr/bin/awesome-client',
            "awesome.emit_signal('module::sleep_resumed', true)",
        ],
        capture_output=True,
        text=True,
        check=False,
    )

failure = types.SimpleNamespace(returncode=1, stderr='D-Bus unavailable')
output = io.StringIO()
with (
    mock.patch.object(module.subprocess, 'run', return_value=failure),
    contextlib.redirect_stdout(output),
):
    module.onPrepareForSleep(None, None, None, None, None, (False,), None)
assert 'D-Bus unavailable' in output.getvalue()

print('suspend hook tests passed')
