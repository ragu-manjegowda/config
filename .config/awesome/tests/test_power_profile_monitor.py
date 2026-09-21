import importlib.machinery
import importlib.util
import os
import tempfile
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

    def failed_run(_command, **_kwargs):
        return SimpleNamespace(returncode=1, stdout="", stderr="failed")

    with mock.patch.object(module.subprocess, "run", side_effect=failed_run):
        assert not module.apply_default(False)
        assert module.read_previous_source() == "battery", "failed transition updated persisted source"


print("power profile monitor tests passed")
