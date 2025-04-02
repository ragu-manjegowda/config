#!/bin/zsh

tmux_config_path="$HOME/.config/tmux/tmux.conf"
sed -i -e "s#solarized-dark#solarized-light#g" $tmux_config_path
