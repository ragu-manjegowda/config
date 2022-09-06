#!/usr/bin/env python3

###############################################################################
# This script uses dbus to detect when the system returns from hibernation
# or suspend.
#
# Reference - https://github.com/CatoMaior/Dotfiles/blob/main/Scripts/moveVitals
# Modified by - Ragu Manjegowda
# Github - @ragu-manjegowda
###############################################################################


from os import system
from gi.repository import GLib, Gio
from subprocess import run

# Check if this is already running, if so exit
p = run("pgrep -f suspend-hook.py | wc -l", capture_output=True, shell=True)

# Check for length 2 as current instance of process creates a PID as well
# and wc -l above counts extra '\n' from pgrep output.
if p.stdout.strip().decode('utf-8') != '2':
    # print(p.stdout.strip().decode('utf-8'))
    exit()

def onPrepareForSleep(conn, sender, obj, interface, signal, parameters, data):
    if not parameters[0]: # parameters[0] is True just before sleep, False just after wake
        system(""" echo "awesome.emit_signal(\'module::sleep_resumed\', true)" | awesome-client """)

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
