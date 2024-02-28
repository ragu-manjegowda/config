#!/bin/bash

sioyek_config_path="$HOME/.config/sioyek/prefs_user.config"
sed -i -e "s#-light#-dark#g" $sioyek_config_path


