#!/bin/zsh

opencode_config_path="$HOME/.config/opencode/opencode.json"
sed -i -e "s#solarized-light#solarized-dark#g" $opencode_config_path
