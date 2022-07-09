#!/bin/bash

path=/sys/class/leds/smc::kbd_backlight/brightness

case "$1" in
    -inc)
	    var=$(cat $path)
    if [ $(($var + $2)) -lt 255 ]
    then
        echo $(($var + $2)) > $path
    else
        echo 255 > $path
    fi
    ;;
    -dec)
    var=$(cat $path)
    if [ $(($var - $2)) -gt 0 ]
    then
        echo $(($var - $2)) > $path
    else
        echo 0 > $path
    fi
   ;;
esac
