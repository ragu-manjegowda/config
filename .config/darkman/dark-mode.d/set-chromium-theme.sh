#!/bin/zsh

chromium_config_path="$HOME/.config/chrome-flags.conf"
chromium_dark_config_path="$HOME/.config/chrome-flags-dark.conf"

cp $chromium_dark_config_path $chromium_config_path
