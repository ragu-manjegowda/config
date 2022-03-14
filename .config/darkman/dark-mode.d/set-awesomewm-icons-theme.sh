#!/bin/bash

# To change color of an image i.e. the awesomewm icons etc
for i in $(find $HOME/.config/awesome/ -name "*.svg"); do
    sed -i -e "s/fill:#000000/fill:#ffffff/" $i
    sed -i -e "s/fill=\"#000000\"/fill=\"#ffffff\"/" $i
done

# To change color of an image i.e. the awesomewm icons etc
# excluding vpn icon
for i in $(find $HOME/.config/awesome/ -name "*.png" -not -path "*/widget/vpn/icons/*"); do
    convert $i -fill "#ffffff" -colorize 100% $i
done

config_path="$HOME/.config/awesome/theme/init.lua"
sed -i -e "s/-light-/-dark-/" $config_path

notify-send -u critical -a awesome \
    -i ~/.config/awesome/theme/icons/awesome.svg "Reload awesome to load dark theme"
