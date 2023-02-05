#!/bin/zsh

git_config_path="$HOME/.config/git/config"
sed -i -e "s#(light)#(dark)#g" $git_config_path
