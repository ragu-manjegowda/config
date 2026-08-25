#!/bin/bash

if [[ -e /run/arch-bootstrap-package-restore ]]; then
    exit 0
fi

# Backup all packages
paru -Qqe > /var/archiso-backup/pkglistAll.txt

# Backup packman installed packages
paru -Qqen > /var/archiso-backup/pkglistPacmanInstalled.txt

# Backup AUR/foreign packages
paru -Qqem > /var/archiso-backup/foreignpkglist.txt
