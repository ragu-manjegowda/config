#!/bin/zsh

DIRCOLORS="${XDG_CONFIG_HOME}/zsh/zsh-custom/themes/dircolors-solarized"
dircolors_dark_path="${DIRCOLORS}/dircolors.ansi-dark"
eval `dircolors ${dircolors_dark_path}`
