#!/bin/bash

# make everything on highDPI monitor not look teeny-tiny
xrandr --dpi 144

# set up high DPI monitor
xrandr --output LVDS1 --mode 1920x1200 --pos 0x0

# Following fixes low res monitor cursor and resolution issue
# xrandr --output DP-2 --mode 1920x1080 --pos 2048x0 --scale 2x2

# Following turns off
xrandr --output DPI1 --off
xrandr --output HDMI1 --off
xrandr --output VGA1 --off
