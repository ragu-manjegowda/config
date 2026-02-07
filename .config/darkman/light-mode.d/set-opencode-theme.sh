#!/bin/sh

opencode_config_path="$HOME/.config/opencode/opencode.json"
sed -i -e 's/"theme": "solarized-dark"/"theme": "solarized-light"/g' $opencode_config_path
