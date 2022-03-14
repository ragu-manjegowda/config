#!/bin/bash

# To change color of an image i.e. the awesomewm icons etc
for i in $(find $HOME/.config/awesome/ -name "*.svg"); do
    sed -i -e "s/fill:#ffffff/fill:#000000/" $i
    sed -i -e 's/fill="#ffffff"/fill="#000000"/' $i
done

# To change color of an image i.e. the awesomewm icons etc
# excluding vpn icon
for i in $(find $HOME/.config/awesome/ -name "*.png" -not -path "*/widget/vpn/icons/*"); do
    convert $i -fill "#000000" -colorize 100% $i
done

config_path="$HOME/.config/awesome/theme/init.lua"
sed -i -e "s/-dark-/-light-/" $config_path

notify-send -u critical -a awesome \
    -i ~/.config/awesome/theme/icons/awesome.svg "Reload awesome to load light theme"
