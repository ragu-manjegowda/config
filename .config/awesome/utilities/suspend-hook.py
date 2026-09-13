#!/usr/bin/env python3

###############################################################################
# This script uses dbus to detect when the system returns from hibernation
# or suspend.
#
# Reference - https://github.com/CatoMaior/Dotfiles/blob/main/Scripts/moveVitals
# Modified by - Ragu Manjegowda
# Github - @ragu-manjegowda
###############################################################################


import subprocess
import sys


def onPrepareForSleep(conn, sender, obj, interface, signal, parameters, data):
    if not parameters[0]:  # True just before sleep, false just after wake.
        result = subprocess.run(
            [
                "/usr/bin/awesome-client",
                "awesome.emit_signal('module::sleep_resumed', true)",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            print(f"Failed to notify Awesome after resume: {result.stderr.strip()}", flush=True)


def main():
    from gi.repository import Gio, GLib

    # The current shell pipeline and this process both match pgrep.
    process_count = subprocess.run(
        "pgrep -f suspend-hook.py | wc -l",
        capture_output=True,
        shell=True,
        check=False,
    )
    if process_count.stdout.strip().decode('utf-8') != '2':
        return

    system_bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
    system_bus.signal_subscribe('org.freedesktop.login1',
                                'org.freedesktop.login1.Manager',
                                'PrepareForSleep',
                                '/org/freedesktop/login1',
                                None,
                                Gio.DBusSignalFlags.NONE,
                                onPrepareForSleep,
                                None)

    GLib.MainLoop().run()


if __name__ == '__main__':
    sys.exit(main())
