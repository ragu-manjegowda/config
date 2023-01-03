#!/bin/zsh

DIRCOLORS="${XDG_CONFIG_HOME}/zsh/zsh-custom/themes/dircolors-solarized"
dircolors_light_path="${DIRCOLORS}/dircolors.ansi-light"
eval `dircolors ${dircolors_light_path}`
