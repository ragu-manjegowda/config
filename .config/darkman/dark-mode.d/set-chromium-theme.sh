#!/bin/zsh

exec /usr/bin/python3 "${XDG_CONFIG_HOME:-$HOME/.config}/scripts/chromium-theme.py" dark
