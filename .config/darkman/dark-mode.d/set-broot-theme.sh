#!/bin/zsh

broot_config_path="$HOME/.config/broot/conf.hjson"
broot_dark_config_path="$HOME/.config/broot/conf-dark.hjson"

mv $broot_dark_config_path $broot_config_path
