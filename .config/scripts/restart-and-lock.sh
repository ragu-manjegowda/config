#!/bin/sh

# restart darkman
systemctl --user reload-or-restart --now darkman.service

# give darkman sometime to run scripts
sleep 0.5

# Show lock screen
awesome-client "awesome.emit_signal(\"module::lockscreen_show\")"
