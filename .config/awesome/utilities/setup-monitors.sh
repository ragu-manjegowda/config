#!/bin/bash

# make everything on highDPI monitor not look teeny-tiny
xrandr --dpi 144

# set up high DPI monitor
xrandr --output eDP-1 --mode 2560x1440 --pos 0x0

# Following fixes low res monitor cursor and resolution issue
# xrandr --output DP-2 --mode 1920x1080 --pos 2048x0 --scale 2x2

# Following turns off TV output, change the output ID as needed
# xrandr --output HDMI-1 --off