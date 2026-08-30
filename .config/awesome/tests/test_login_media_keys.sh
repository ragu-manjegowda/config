#!/usr/bin/env bash

set -euo pipefail

repo_home="${HOME}"
listener="$repo_home/.config/misc/usr/local/libexec/login-media-keys"
service="$repo_home/.config/misc/etc/systemd/system/login-media-keys.service"
bootstrap="$repo_home/.config/scripts/bootstrap/06-desktop.sh"
lockscreen="$repo_home/.config/awesome/module/lockscreen.lua"

python -c 'compile(open(__import__("sys").argv[1]).read(), __import__("sys").argv[1], "exec")' "$listener"
grep -Fq 'ExecStart=/usr/local/libexec/login-media-keys' "$service"
grep -Fq 'Before=greetd.service' "$service"
grep -Fq 'enable_system_service login-media-keys.service' "$bootstrap"
grep -Fq "XF86MonBrightnessUp = 'widget::brightness'" "$lockscreen"
grep -Fq "XF86MonBrightnessDown = 'widget::brightness'" "$lockscreen"
grep -Fq "XF86AudioRaiseVolume = 'widget::volume'" "$lockscreen"
grep -Fq "XF86AudioLowerVolume = 'widget::volume'" "$lockscreen"
grep -Fq "XF86AudioMute = 'widget::volume'" "$lockscreen"
grep -Fq "XF86AudioMicMute = 'widget::microphone'" "$lockscreen"

LOGIN_MEDIA_KEYS_PATH="$listener" python <<'PY'
import importlib.util
import os
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace
from importlib.machinery import SourceFileLoader

sys.dont_write_bytecode = True
loader = SourceFileLoader("login_media_keys", os.environ["LOGIN_MEDIA_KEYS_PATH"])
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)

with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    module.PROC_ROOT = root / "proc"
    module.LOCK_FILE = root / "awesome-lockscreen.locked"
    module.PROC_ROOT.mkdir()

    assert not module.controls_enabled()
    module.LOCK_FILE.touch()
    assert module.controls_enabled()
    module.LOCK_FILE.unlink()

    process = module.PROC_ROOT / "123"
    process.mkdir()
    (process / "comm").write_text("tuigreet\n")
    (process / "status").write_text("Uid:\t1000\t1000\t1000\t1000\n")
    assert module.controls_enabled()

calls = []

def successful_run(command, **_):
    calls.append(command)
    return SimpleNamespace(returncode=0)

module.subprocess.run = successful_run
assert module.run_action(module.KEY_BRIGHTNESSUP)
assert calls == [["/usr/bin/light", "-A", "10"]]

calls.clear()
assert module.run_action(module.KEY_VOLUMEUP)
assert calls[0][-3:] == ["set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"]
assert not any("amixer" in command for command in calls)

calls.clear()
assert module.run_action(module.KEY_MICMUTE)
assert calls[0][-3:] == ["set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]

calls.clear()

def failing_wpctl(command, **_):
    calls.append(command)
    return SimpleNamespace(returncode=1 if "/usr/bin/wpctl" in command else 0)

module.subprocess.run = failing_wpctl
assert module.run_action(module.KEY_MUTE)
assert any("/usr/bin/systemctl" in command for command in calls)
assert calls[-1][-5:] == ["/usr/bin/amixer", "-q", "set", "Master", "toggle"]

calls.clear()
assert module.run_action(module.KEY_MICMUTE)
assert calls[-1][-5:] == ["/usr/bin/amixer", "-q", "set", "Capture", "toggle"]

events = []
module.controls_enabled = lambda: True
module.run_action = events.append
event = module.INPUT_EVENT.pack(0, 0, module.EV_KEY, module.KEY_VOLUMEDOWN, 1)
module.process_events(event)
assert events == [module.KEY_VOLUMEDOWN]
PY

printf 'login media key tests passed\n'
