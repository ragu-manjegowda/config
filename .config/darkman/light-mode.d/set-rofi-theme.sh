#!/bin/zsh

rofi_config_path="$HOME/.config/rofi/config.rasi"
sed -i -e "s#-dark-#-light-#g" $rofi_config_path

rofi_app_menu_config_path="$HOME/.config/awesome/configuration/rofi/appmenu/rofi.rasi"
sed -i -e "s#-dark#-light#g" $rofi_app_menu_config_path

rofi_emoji_menu_config_path="$HOME/.config/awesome/configuration/rofi/emojimenu/rofi.rasi"
sed -i -e "s#-dark#-light#g" $rofi_emoji_menu_config_path

rofi_run_menu_config_path="$HOME/.config/awesome/configuration/rofi/runmenu/rofi.rasi"
sed -i -e "s#-dark#-light#g" $rofi_run_menu_config_path

rofi_show_time_config_path="$HOME/.config/awesome/configuration/rofi/time/rofi.rasi"
sed -i -e "s#-dark#-light#g" $rofi_show_time_config_path
