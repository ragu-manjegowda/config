"""volctl application"""

from subprocess import Popen
from os import system
import sys
from gi.repository import Gdk, Gio, Gtk
import shlex

from volctl.meta import (
    PROGRAM_NAME,
    COPYRIGHT,
    LICENSE,
    COMMENTS,
    WEBSITE,
    VERSION,
)
from volctl.status_icon import StatusIcon

from volctl.prefs import PreferencesDialog
from volctl.pulsemgr import PulseManager
from volctl.slider_win import VolumeSliders


DEFAULT_MIXER_CMD = "pavucontrol"

VOLCTL_CSS = b"""
/* Keep the popup legible while inheriting the active GTK theme palette. */
window#volctl {
    background-color: @VOLCTL_BACKGROUND@;
    background-image: none;
    color: @theme_fg_color;
}
window#volctl frame {
    background-color: @VOLCTL_BACKGROUND@;
    background-image: none;
    color: @theme_fg_color;
    border: 1px solid @borders;
    border-radius: 8px;
    padding: 8px;
}
window#volctl scale trough {
    background-color: @VOLCTL_TRACK_BACKGROUND@;
    min-width: 12px;
    min-height: 10px;
    border-radius: 5px;
}
window#volctl scale highlight {
    background-color: @VOLCTL_ACCENT@;
    border-radius: 5px;
}
window#volctl scale slider {
    background-color: @VOLCTL_ACCENT@;
    border-radius: 50%;
}
window#volctl scale {
    background-color: @VOLCTL_CONTROL_BACKGROUND@;
    background-image: none;
    border-radius: 12px;
    padding: 6px;
}
window#volctl button {
    background-color: @VOLCTL_CONTROL_BACKGROUND@;
    background-image: none;
    color: @theme_fg_color;
    min-width: 24px;
    min-height: 24px;
    border-radius: 12px;
}
window#volctl button.toggle {
    padding: 0;
    margin-bottom: -5px;
}
window#volctl button.toggle:hover {
    background-color: @VOLCTL_CONTROL_BACKGROUND@;
    border-color: @borders;
}
window#volctl button.toggle:checked {
    background-color: @VOLCTL_CONTROL_BACKGROUND@;
    border-color: @borders;
}
window#volctl button.toggle:checked image {
    -gtk-icon-effect: dim;
}
"""


class VolctlApp:
    """GUI application for volctl."""

    def __init__(self):
        self._style_provider = Gtk.CssProvider()
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            self._style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )
        self._interface_settings = Gio.Settings.new("org.gnome.desktop.interface")
        self._interface_settings.connect("changed::gtk-theme", self._set_style)
        self._set_style()
        Gtk.Settings.get_default().connect("notify::gtk-theme-name", self._set_style)
        self.settings = Gio.Settings("apps.volctl", path="/apps/volctl/")
        self.settings.connect("changed", self._cb_settings_changed)
        self.mouse_wheel_step = self.settings.get_int("mouse-wheel-step")
        self._first_volume_update = True
        self.pulsemgr = PulseManager(self)

        self.status_icon = None
        self.sliders_win = None
        self._about_win = None
        self._preferences = None
        self._osd = None
        self._mixer_process = None

        # Remembered main volume, mute
        self._volume, self._mute = 0.0, False

    def create_status_icon(self):
        """Create status icon."""
        if self.status_icon is None:
            prefer_gtksi = self.settings.get_boolean("prefer-gtksi")
            self.status_icon = StatusIcon(self, prefer_gtksi)

    def quit(self):
        """Gracefully shut down application."""
        try:
            self.pulsemgr.close()
        except AttributeError:
            pass
        if Gtk.main_level() > 0:
            if self.sliders_win:
                self.sliders_win.destroy()
            if self._about_win:
                self._about_win.destroy()
            if self._preferences:
                self._preferences.destroy()
            if self._osd:
                self._osd.destroy()
            Gtk.main_quit()
        else:
            sys.exit(1)

    def _set_style(self, *_):
        """Keep the popup fully transparent for Picom's blur treatment."""
        # Darkman updates GSettings even when an existing GTK process does not
        # receive a gtk-theme-name notification through XSettings.
        theme_name = self._interface_settings.get_string("gtk-theme") or (
            Gtk.Settings.get_default().get_property("gtk-theme-name") or ""
        )
        control_background = (
            b"#073642" if "dark" in theme_name.lower() else b"#eee8d5"
        )
        track_background = (
            b"#002b36" if "dark" in theme_name.lower() else b"#fdf6e3"
        )
        accent = b"#859900" if "dark" in theme_name.lower() else b"#268bd2"
        background = b"transparent"
        self._style_provider.load_from_data(
            VOLCTL_CSS.replace(b"@VOLCTL_BACKGROUND@", background).replace(
                b"@VOLCTL_CONTROL_BACKGROUND@", control_background
            ).replace(
                b"@VOLCTL_TRACK_BACKGROUND@", track_background
            ).replace(
                b"@VOLCTL_ACCENT@", accent
            )
        )

    def update_main(self, volume, mute):
        """Default sink update."""

        # Ignore events that don't change anything (prevents OSD from showing)
        if volume == self._volume and mute == self._mute:
            return
        self._volume = volume
        self._mute = mute

        self.status_icon.update(volume, mute)
        # OSD - use AwesomeWM's OSD instead of built-in
        if self._first_volume_update:
            self._first_volume_update = False  # Avoid showing on program start
            return
        system("echo \"awesome.emit_signal('widget::volume')\" | awesome-client")
        system(
            "echo \"awesome.emit_signal('module::volume_osd:show', true)\" | awesome-client"
        )

    # Updates coming from pulseaudio

    def sink_update(self, idx, volume, mute):
        """A sink update is coming from PulseAudio."""
        if idx == self.pulsemgr.default_sink_idx:
            self.update_main(volume, mute)
        if self.sliders_win:
            self.sliders_win.update_sink_scale(idx, volume, mute)

    def sink_input_update(self, idx, volume, mute):
        """A sink input update is coming from PulseAudio."""
        if self.sliders_win:
            self.sliders_win.update_sink_input_scale(idx, volume, mute)

    def peak_update(self, idx, val):
        """Notify scale when update is coming from pulseaudio."""
        if self.sliders_win:
            self.sliders_win.update_scale_peak(idx, val)

    def slider_count_changed(self):
        """Amount of sliders changed."""
        if self.status_icon and self.sliders_win:
            self.sliders_win.recreate_sliders()
            if self.settings.get_boolean("vu-enabled"):
                self.pulsemgr.start_peak_monitor()

    def on_connected(self):
        """PulseAudio connection was established."""
        self.create_status_icon()

    def on_disconnected(self):
        """PulseAudio connection was lost."""
        self.close_slider()

    # Gsettings callback

    def _cb_settings_changed(self, settings, key):
        if key == "mouse-wheel-step":
            self.mouse_wheel_step = settings.get_int("mouse-wheel-step")
            if self.sliders_win:
                self.sliders_win.set_increments()

    # GUI

    def show_preferences(self):
        """Bring preferences to focus or create if it doesn't exist."""
        if self._preferences:
            self._preferences.present()
        else:
            self._preferences = PreferencesDialog(self.settings, DEFAULT_MIXER_CMD)
            self._preferences.run()
            self._preferences.destroy()
            del self._preferences
            self._preferences = None

    def show_about(self):
        """Bring about window to focus or create if it doesn't exist."""
        if self._about_win is not None:
            self._about_win.present()
        else:
            self._about_win = Gtk.AboutDialog()
            self._about_win.set_program_name(PROGRAM_NAME)
            self._about_win.set_version(VERSION)
            self._about_win.set_copyright(COPYRIGHT)
            self._about_win.set_license_type(LICENSE)
            self._about_win.set_comments(COMMENTS)
            self._about_win.set_website(WEBSITE)
            self._about_win.set_logo_icon_name("audio-volume-high")
            self._about_win.run()
            self._about_win.destroy()
            del self._about_win
            self._about_win = None

    def launch_mixer(self):
        """Launch external mixer."""
        mixer_cmd = self.settings.get_string("mixer-command")
        mixer_cmd_str = self.settings.get_string("mixer-command")
        if mixer_cmd_str == "":
            mixer_cmd = DEFAULT_MIXER_CMD
        else:
            mixer_cmd = shlex.split(mixer_cmd_str)
        if self._mixer_process is None or not self._mixer_process.poll() is None:
            self._mixer_process = Popen(mixer_cmd)
        # TODO: bring mixer win to front otherwise

    def show_slider(self, xpos, ypos):
        """Show mini window with application volume sliders."""
        self.sliders_win = VolumeSliders(self, xpos, ypos)
        if self.settings.get_boolean("vu-enabled"):
            self.pulsemgr.start_peak_monitor()

    def close_slider(self):
        """Close mini window with application volume sliders."""
        if self.sliders_win:
            self.sliders_win.destroy()
            del self.sliders_win
            self.sliders_win = None
            self.pulsemgr.stop_peak_monitor()
            return True
        return False
