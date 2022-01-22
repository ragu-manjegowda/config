#!/bin/zsh

alacritty_config_path="$HOME/.config/alacritty/colors.yml"
sed -i -e "s#^colors: \*.*#colors: *solarized-light#g" $alacritty_config_path

