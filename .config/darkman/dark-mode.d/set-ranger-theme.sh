#!/bin/zsh

ranger_colors_path="$HOME/.config/ranger/colorschemes/neosolarized.py"
sed -i -e "s#solarized_light#solarized_dark#g" $ranger_colors_path
