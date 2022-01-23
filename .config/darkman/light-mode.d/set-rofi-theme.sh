#!/bin/zsh

rofi_config_path="$HOME/.config/rofi/config.rasi"
sed -i -e "s#-dark-#-light-#g" $rofi_config_path

rofi_app_menu_config_path="$HOME/.config/awesome/configuration/rofi/appmenu/rofi.rasi"
sed -i -e "s#-dark#-light#g" $rofi_app_menu_config_path

