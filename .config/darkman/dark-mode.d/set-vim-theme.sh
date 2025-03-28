#!/bin/zsh

vim_config_path="$HOME/.config/nvim/lua/user/colorscheme.lua"
sed -i -e "s#background=light#background=dark#g" $vim_config_path

lualine_config_path="$HOME/.config/nvim/lua/user/lualine.lua"
sed -i -e "s#solarized_light#solarized_dark#g" $lualine_config_path
