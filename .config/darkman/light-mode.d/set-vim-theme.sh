#!/bin/zsh

vim_config_path="$HOME/.config/nvim/lua/user/colorscheme.lua"
sed -i -e "s#background=dark#background=light#g" $vim_config_path
