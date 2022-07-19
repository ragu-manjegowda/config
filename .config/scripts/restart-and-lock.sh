#!/bin/sh

# restart darkman
systemctl --user reload-or-restart --now darkman.service

# Show lock screen
awesome-client "awesome.emit_signal(\"module::lockscreen_show\")"
