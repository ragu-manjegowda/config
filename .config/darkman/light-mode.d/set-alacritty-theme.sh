#!/bin/zsh

alacritty_config_path="$HOME/.config/alacritty/alacritty.toml"
sed -i -e "s#solarized_dark#solarized_light#g" $alacritty_config_path

export BAT_THEME="Solarized (light)"

