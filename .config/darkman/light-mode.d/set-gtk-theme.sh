#!/bin/zsh

# https://github.com/derat/xsettingsd/wiki/Settings
gtk2_config_path="$HOME/.gtkrc-2.0"
gtk3_config_path="$HOME/.config/gtk-3.0/settings.ini"
icon_config_path="$HOME/.icons/default/index.theme"
xdg_config_path="$HOME/.config/xsettingsd/xsettingsd.conf"

sed -i -e "s#DarkGreen#LightBlue#g" $gtk2_config_path
sed -i -e "s#Solarized-Dark-Green-Numix#Solarized-FLAT-Blue#g" $gtk2_config_path

sed -i -e "s#DarkGreen#LightBlue#g" $gtk3_config_path
sed -i -e "s#Solarized-Dark-Green-Numix#Solarized-FLAT-Blue#g" $gtk3_config_path

sed -i -e "s#DarkGreen#LightBlue#g" $xdg_config_path
sed -i -e "s#Solarized-Dark-Green-Numix#Solarized-FLAT-Blue#g" $xdg_config_path

# Following two has to be dealt differently since not checking end of string
# will keep appending -Light repeatedly
sed -i -e 's/"Numix-Cursor"/"Numix-Cursor-Light"/g' $gtk2_config_path
sed -i -e 's/Numix-Cursor$/Numix-Cursor-Light/g' $gtk3_config_path
sed -i -e 's/Numix-Cursor$/Numix-Cursor-Light/g' $icon_config_path
sed -i -e 's/"Numix-Cursor"/"Numix-Cursor-Light"/g' $xdg_config_path

if ! pgrep -x "xsettingsd" > /dev/null
then
    xsettingsd &
else
    killall -HUP xsettingsd
fi

# Mouse cursor theme is not updated on the root window (background) or
# in some programs. Opening lxappearance at least helps for the root window,
# so quickly open and kill that as a work around for now.
if command -v lxappearance &> /dev/null
then
    lxappearance&
    sleep 0.2
    killall lxappearance
fi
