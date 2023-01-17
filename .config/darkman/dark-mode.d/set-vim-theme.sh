#!/bin/zsh

vim_config_path="$HOME/.config/nvim/lua/user/colorscheme.lua"
sed -i -e "s#background=light#background=dark#g" $vim_config_path
sed -i -e "s#theme = \"light\"#theme = \"dark\"#g" $vim_config_path
