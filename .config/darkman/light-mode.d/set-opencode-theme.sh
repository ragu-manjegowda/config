#!/bin/sh

opencode_tui_config_path="$HOME/.config/opencode/tui.json"

sed -i -e 's/"theme": "solarized-dark"/"theme": "solarized-light"/g' "$opencode_tui_config_path"
