#!/bin/bash

# --overwrite '*' whereby * means every file path;
# reinstall everything otherwise you might get "exists in file system" errors
pacman -Syyu "$(pacman -Qnq)" --overwrite '*'
