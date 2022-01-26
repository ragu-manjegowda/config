#!/bin/bash

# Backup all packages
pacman -Qqe > /var/archiso-backup/pkglistAll.txt

# Backup packman installed packages
pacman -Qqen > /var/archiso-backup/pkglistPacmanInstalled.txt

# Backup AUR/foreign packages
pacman -Qqem > /var/archiso-backup/foreignpkglist.txt
