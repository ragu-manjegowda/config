#!/bin/zsh

#------------------------------------------------------------------------------
#- Author       : Ragu Manjegowda
#- Github       : @ragu-manjegowda
#------------------------------------------------------------------------------

termshark_config_path="$HOME/.config/termshark/termshark.toml"
sed -i -e "s#^dark-mode = false#dark-mode = true#g" $termshark_config_path
