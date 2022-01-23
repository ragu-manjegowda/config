#!/bin/zsh

xdg_config_path="$HOME/.config/xsettingsd/xsettingsd.conf"
sed -i -e "s#-dark#-light#g" $xdg_config_path

if ! pgrep -x "xsettingsd" > /dev/null
then
    xsettingsd &
else
    killall -HUP xsettingsd
fi

