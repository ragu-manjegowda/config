#!/bin/zsh

broot_config_path="$HOME/.config/broot/conf.hjson"
broot_light_config_path="$HOME/.config/broot/conf-light.hjson"

mv $broot_light_config_path $broot_config_path
