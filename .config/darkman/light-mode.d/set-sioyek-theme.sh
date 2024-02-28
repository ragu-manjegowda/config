#!/bin/bash

sioyek_config_path="$HOME/.config/sioyek/prefs_user.config"
sed -i -e "s#-dark#-light#g" $sioyek_config_path


