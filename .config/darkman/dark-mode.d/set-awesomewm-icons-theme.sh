#!/bin/bash

# To change color of an image i.e. the awesomewm icons etc
for i in $(find $HOME/.config/awesome/ -name "*.svg"); do
    sed -i -e "s/fill:#073642/fill:#eee8d5/" $i
    sed -i -e "s/fill=\"#073642\"/fill=\"#eee8d5\"/" $i
done

# To change color of an image i.e. the awesomewm icons etc
# excluding vpn icon and profile picture
for i in $(find $HOME/.config/awesome/ -name "*.png" \
            -not -path "*/widget/vpn/icons/*" \
            -not -path "*/configuration/user-profile/*" \
            -not -path "*/library/*" \
            -not -path "*/widget/playerctl/*"); do
    convert $i -fill "#eee8d5" -colorize 100% $i
done

config_path="$HOME/.config/awesome/theme/init.lua"
sed -i -e "s/-light-/-dark-/" $config_path

notify-send -u critical -a awesome \
    -i ~/.config/awesome/theme/icons/awesome.svg "Reload awesome to load dark theme"
