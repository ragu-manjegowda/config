#!/bin/sh

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
exec "${CX_PYTHON:-$HOME/.local/share/venv/bin/python}" "$config_home/codex/tools.py" theme dark
