#!/bin/zsh

tmux_config_path="$HOME/.config/tmux/tmux.conf"
sed -i -e "s#solarized-light#solarized-dark#g" $tmux_config_path
