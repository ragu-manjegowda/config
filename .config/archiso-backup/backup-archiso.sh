#!/bin/bash

# Backup all packages
pacman -Qqe > pkglistAll.txt

# Backup packman installed packages
pacman -Qqen > pkglistPacmanInstalled.txt

# Backup AUR/foreign packages
pacman -Qqem > foreignpkglist.txt
