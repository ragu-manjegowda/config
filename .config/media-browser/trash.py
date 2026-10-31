"""Confirm and trash one selected media file using the desktop trash backend."""

import os
import sys

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, Gio, GLib, Gtk


def confirm(path):
    dialog = Gtk.MessageDialog(
        title="Media browser — Move to Trash?",
        modal=True,
        message_type=Gtk.MessageType.QUESTION,
        text="Move this file to Trash?",
    )
    dialog.format_secondary_text(f"{path}\n\nPress y to confirm or n to cancel.")
    dialog.add_buttons("_No", Gtk.ResponseType.NO, "_Yes", Gtk.ResponseType.YES)
    dialog.set_default_response(Gtk.ResponseType.NO)
    dialog.set_position(Gtk.WindowPosition.CENTER)

    def key_pressed(widget, event):
        key = Gdk.keyval_to_lower(event.keyval)
        if key == Gdk.KEY_y:
            widget.response(Gtk.ResponseType.YES)
        elif key in (Gdk.KEY_n, Gdk.KEY_Escape):
            widget.response(Gtk.ResponseType.NO)
        else:
            return False
        return True

    dialog.connect("key-press-event", key_pressed)
    result = dialog.run()
    dialog.destroy()
    return result == Gtk.ResponseType.YES


def main():
    if len(sys.argv) != 2:
        return 64
    path = os.path.abspath(sys.argv[1])
    if not confirm(path):
        return 0
    try:
        # Same freedesktop Trash specification used by Yazi's normal remove.
        # GIO chooses the home or per-filesystem trash and records restore metadata.
        Gio.File.new_for_path(path).trash(None)
    except GLib.Error as error:
        dialog = Gtk.MessageDialog(
            title="Media browser — Trash failed",
            modal=True,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.CLOSE,
            text="Could not move the file to Trash.",
        )
        dialog.format_secondary_text(error.message)
        dialog.run()
        dialog.destroy()
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
