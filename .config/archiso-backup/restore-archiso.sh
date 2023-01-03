#!/bin/bash

# restore packages
paru -S --needed - < pkglistAll.txt

# Delete those not in pkglist.txt
paru -Rsu $(comm -23 <(paru -Qq | sort) <(sort pkglistAll.txt))
