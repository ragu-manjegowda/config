#!/bin/zsh

alacritty_config_path="$HOME/.config/alacritty/colors.yml"
sed -i -e "s#^colors: \*.*#colors: *solarized-dark#g" $alacritty_config_path

export BAT_THEME="Solarized (dark)"

