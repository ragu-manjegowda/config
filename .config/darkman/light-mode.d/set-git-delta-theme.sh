#!/bin/zsh

git_config_path="$HOME/.config/git/config"
sed -i -e "s#(dark)#(light)#g" $git_config_path
