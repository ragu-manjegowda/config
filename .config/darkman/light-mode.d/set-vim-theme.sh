#!/bin/zsh

vim_config_path="$HOME/.config/nvim/lua/user/colorscheme.lua"
sed -i -e "s#background=dark#background=light#g" $vim_config_path

lualine_config_path="$HOME/.config/nvim/lua/user/lualine.lua"
sed -i -e "s#solarized_dark#solarized_light#g" $lualine_config_path
