#!/bin/zsh

chromium_config_path="$HOME/.config/chrome-flags.conf"
chromium_light_config_path="$HOME/.config/chrome-flags-light.conf"

cp $chromium_light_config_path $chromium_config_path
