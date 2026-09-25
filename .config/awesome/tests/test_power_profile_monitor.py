import importlib.machinery
import importlib.util
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

SCRIPT = os.path.join(
    os.environ["HOME"],
    ".config",
    "awesome",
    "utilities",
    "power-profile-monitor",
)


loader = importlib.machinery.SourceFileLoader("power_profile_monitor", SCRIPT)
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


with tempfile.TemporaryDirectory() as temporary:
    module.SOURCE_STATE_FILE = os.path.join(temporary, "power-source")
    module.BOOT_ID_FILE = os.path.join(temporary, "boot-id")
    supply_dir = Path(temporary) / "power_supply"
    ac = supply_dir / "AC"
    usb_source = supply_dir / "usb-source"
    ac.mkdir(parents=True)
    usb_source.mkdir()
    (ac / "type").write_text("Mains\n")
    (ac / "online").write_text("1\n")
    (usb_source / "type").write_text("USB\n")
    (usb_source / "online").write_text("1\n")
    module.SUPPLY_DIR = supply_dir
    with open(module.BOOT_ID_FILE, "w", encoding="utf-8") as boot_file:
        boot_file.write("boot-one\n")
    calls = []

    def successful_run(command, **kwargs):
        calls.append((command, kwargs.get("env")))
        if command[:2] == ["/bin/bash", module.HELPER]:
            profile = "balanced" if kwargs["env"]["POWER_PROFILE_ON_BATTERY"] == "true" else "performance"
            return SimpleNamespace(returncode=0, stdout=profile + "\n", stderr="")
        return SimpleNamespace(returncode=0, stdout="", stderr="")

    with mock.patch.object(module.subprocess, "run", side_effect=successful_run):
        assert module.apply_default(False)
        assert module.read_previous_source() == "ac"
        first_count = len(calls)

        assert not module.apply_default(False)
        assert len(calls) == first_count, "same-source restart reapplied the profile baseline"

        assert module.apply_default(True)
        assert module.read_previous_source() == "battery"
        assert calls[-2][1]["POWER_PROFILE_ON_BATTERY"] == "true"

        with open(module.BOOT_ID_FILE, "w", encoding="utf-8") as boot_file:
            boot_file.write("boot-two\n")
        assert module.read_previous_source() is None, "previous boot suppressed profile initialization"
        assert module.apply_default(True), "new boot did not apply the source baseline"
        assert module.read_previous_source() == "battery"

    def failed_run(_command, **_kwargs):
        return SimpleNamespace(returncode=1, stdout="", stderr="failed")

    def subprocess_timeout(command, **_kwargs):
        raise subprocess.TimeoutExpired(command, 30)

    with mock.patch.object(module.subprocess, "run", side_effect=failed_run):
        assert not module.apply_default(False)
        assert module.read_previous_source() == "battery", "failed transition updated persisted source"

    with mock.patch.object(module.subprocess, "run", side_effect=subprocess_timeout):
        assert not module.apply_default(False)
        assert module.read_previous_source() == "battery", "timed-out transition updated persisted source"

    commands = []

    def battery_policy_run(command, **_kwargs):
        commands.append(command)
        if "query-battery-aware" in command:
            return SimpleNamespace(returncode=0, stdout="Dynamic changes: False\n", stderr="")
        return SimpleNamespace(returncode=0, stdout="", stderr="")

    with mock.patch.object(module.subprocess, "run", side_effect=battery_policy_run):
        module.disable_builtin_battery_policy()
        assert len(commands) == 1, "already disabled battery policy was changed again"

    commands.clear()

    def enabled_policy_run(command, **_kwargs):
        commands.append(command)
        return SimpleNamespace(returncode=0, stdout="Dynamic changes: True\n", stderr="")

    with mock.patch.object(module.subprocess, "run", side_effect=enabled_policy_run):
        module.disable_builtin_battery_policy()
        assert len(commands) == 2 and commands[-1][-1] == "--disable"

    subscription = SimpleNamespace(active=False, callback=None, resume=None, retry=None)

    class FakeProxy:
        def get_cached_property(self, _name):
            assert subscription.active, "initial power source read preceded D-Bus subscription"
            return SimpleNamespace(unpack=lambda: False)

    class FakeBus:
        def signal_subscribe(self, sender, _interface, _member, path, _arg, _flags, callback, _data):
            if sender == "org.freedesktop.UPower":
                assert path is None, "monitor will miss AC device Online changes"
                subscription.active = True
                subscription.callback = callback
            elif sender == "org.freedesktop.login1":
                assert path == "/org/freedesktop/login1"
                subscription.resume = callback
            else:
                raise AssertionError(f"Unexpected D-Bus signal sender: {sender}")

    fake_gio = SimpleNamespace(
        BusType=SimpleNamespace(SYSTEM=0),
        DBusProxyFlags=SimpleNamespace(NONE=0),
        DBusSignalFlags=SimpleNamespace(NONE=0),
        bus_get_sync=lambda *_args: FakeBus(),
        DBusProxy=SimpleNamespace(new_sync=lambda *_args: FakeProxy()),
    )
    fake_glib = SimpleNamespace(
        SOURCE_REMOVE=False,
        SOURCE_CONTINUE=True,
        timeout_add_seconds=lambda _delay, callback: setattr(subscription, "retry", callback) or 1,
        source_remove=lambda _source: setattr(subscription, "retry", None),
        MainLoop=lambda: SimpleNamespace(run=lambda: None),
    )
    fake_repository = SimpleNamespace(Gio=fake_gio, GLib=fake_glib)
    with mock.patch.dict(sys.modules, {"gi": SimpleNamespace(repository=fake_repository),
                                       "gi.repository": fake_repository}), \
            mock.patch.object(module, "disable_builtin_battery_policy"), \
            mock.patch.object(module, "apply_default", side_effect=[False, True, True, True]) as apply:
        assert module.main() == 0
        assert subscription.retry is not None, "failed startup had no bounded retry"
        assert subscription.retry() is False, "successful retry kept running"
        assert apply.call_count == 2
        module.write_source("ac")

        # UPower can report OnBattery=false because an outgoing USB-C power
        # source is online even when the actual mains adapter is unplugged.
        (ac / "online").write_text("0\n")
        assert module.current_on_battery(FakeProxy()) is True
        assert subscription.resume is not None
        subscription.resume(None, None, None, None, None,
                            SimpleNamespace(unpack=lambda: (False,)), None)
        assert apply.call_count == 3 and apply.call_args_list[-1].args == (True,)

        module.write_source("ac")
        subscription.callback(None, None, str(ac), None, None,
                              SimpleNamespace(unpack=lambda: (
                                  "org.freedesktop.UPower.Device", {"Online": False}, [])), None)
        assert apply.call_count == 4 and apply.call_args_list[-1].args == (True,)


print("power profile monitor tests passed")
