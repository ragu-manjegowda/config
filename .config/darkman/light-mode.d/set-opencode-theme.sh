#!/bin/sh

opencode_config_path="$HOME/.config/opencode/opencode.json"
opencode_tui_config_path="$HOME/.config/opencode/tui.json"

sed -i -e 's/"theme": "solarized-dark"/"theme": "solarized-light"/g' "$opencode_config_path"
sed -i -e 's/"theme": "solarized-dark"/"theme": "solarized-light"/g' "$opencode_tui_config_path"
