#!/bin/bash

# restore packages
pacman -S --needed $(comm -12 <(pacman -Slq | sort) <(sort pkglistAll.txt))

# Delete those not in pkglist.txt
pacman -Rsu $(comm -23 <(pacman -Qq | sort) <(sort pkglistAll.txt))
