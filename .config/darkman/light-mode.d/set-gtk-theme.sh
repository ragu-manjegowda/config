#!/bin/zsh

xdg_config_path="$HOME/.config/xsettingsd/xsettingsd.conf"
sed -i -e "s#-dark#-light#g" $xdg_config_path
killall -HUP xsettingsd

