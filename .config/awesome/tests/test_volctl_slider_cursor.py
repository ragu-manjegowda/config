"""Exercise Volctl's interactive controls without starting GTK or audio."""

import importlib.util
import sys
from pathlib import Path
from types import ModuleType, SimpleNamespace
from unittest.mock import patch


class Control:
    def __init__(self):
        self.handlers = {}
        self.events = 0
        self.value = None

    def connect(self, name, callback):
        self.handlers[name] = callback

    def add_events(self, events):
        self.events |= events

    def set_value(self, value):
        self.value = value

    def __getattr__(self, name):
        if name.startswith("set_"):
            return lambda *_: None
        raise AttributeError(name)


def load_slider_window():
    repository = ModuleType("gi.repository")

    class ScaleFactory:
        @staticmethod
        def new(_orientation):
            return Control()

    repository.Gtk = SimpleNamespace(
        Window=object,
        Scale=ScaleFactory,
        Image=Control,
        ToggleButton=Control,
        Orientation=SimpleNamespace(VERTICAL=1),
        IconSize=SimpleNamespace(SMALL_TOOLBAR=1),
        ReliefStyle=SimpleNamespace(NONE=0),
    )
    pointer = object()
    repository.Gdk = SimpleNamespace(
        EventMask=SimpleNamespace(ENTER_NOTIFY_MASK=1, LEAVE_NOTIFY_MASK=2),
        Cursor=SimpleNamespace(new_from_name=lambda _display, _name: pointer),
    )
    repository.GLib = SimpleNamespace()
    gi = ModuleType("gi")
    gi.repository = repository
    pulsectl = ModuleType("pulsectl")
    pulse_module = ModuleType("pulsectl.pulsectl")
    pulse_module.c = SimpleNamespace(pa=SimpleNamespace(CallError=Exception))
    source = Path(__file__).resolve().parents[1] / "library/volctl/volctl/slider_win.py"
    spec = importlib.util.spec_from_file_location("slider_win_under_test", source)
    module = importlib.util.module_from_spec(spec)
    with patch.dict(
        sys.modules,
        {"gi": gi, "gi.repository": repository,
         "pulsectl": pulsectl, "pulsectl.pulsectl": pulse_module},
    ):
        spec.loader.exec_module(module)
    return module.VolumeSliders, pointer


def main():
    window_type, pointer = load_slider_window()
    popup = object.__new__(window_type)
    popup._volctl = SimpleNamespace(
        settings=SimpleNamespace(get_boolean=lambda _: False),
        mouse_wheel_step=10,
    )
    popup._show_percentage = False
    popup._grid = SimpleNamespace(attach=lambda *_: None)
    scale, mute = popup._add_scale(0, ("Speaker", "audio-card", 0.5, False))

    class EventWindow:
        def __init__(self):
            self.cursors = []

        def get_display(self):
            return object()

        def set_cursor(self, cursor):
            self.cursors.append(cursor)

    for control in (scale, mute):
        assert control.events & 3 == 3
        event_window = EventWindow()
        event = SimpleNamespace(window=event_window)
        assert control.handlers["enter-notify-event"](control, event) is False
        assert control.handlers["leave-notify-event"](control, event) is False
        assert event_window.cursors == [pointer, None]

    assert scale.value == 0.5, "cursor handlers changed the volume"
    print("Volctl slider cursor tests passed")


if __name__ == "__main__":
    main()
