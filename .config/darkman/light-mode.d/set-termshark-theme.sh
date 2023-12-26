#!/bin/zsh

#------------------------------------------------------------------------------
#- Author       : Ragu Manjegowda
#- Github       : @ragu-manjegowda
#------------------------------------------------------------------------------

termshark_config_path="$HOME/.config/termshark/termshark.toml"
sed -i -e "s#^dark-mode = true#dark-mode = false#g" $termshark_config_path
