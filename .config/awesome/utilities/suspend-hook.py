#!/usr/bin/env python3

from os import system
from gi.repository import GLib
from gi.repository import Gio

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
