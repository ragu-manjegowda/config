#!/bin/zsh

ranger_colors_path="$HOME/.config/ranger/colorschemes/neosolarized.py"
sed -i -e "s#solarized_dark#solarized_light#g" $ranger_colors_path
