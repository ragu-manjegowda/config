#!/bin/bash

TMUX_BIN_PATH=/localhome/local-rmanjegowda/.config/tmux-downloads/tmux.appimage
TMUX_INSTALL_DIR=$(dirname "$TMUX_BIN_PATH")

if [ ! -f "$TMUX_BIN_PATH" ]; then
    mkdir -p "$TMUX_INSTALL_DIR"
    cd "$TMUX_INSTALL_DIR" || { echo "Failed to change directory to $TMUX_INSTALL_DIR"; exit 1; }

    curl -s https://api.github.com/repos/nelsonenzo/tmux-appimage/releases/latest \
    | grep "browser_download_url.*appimage" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | wget -qi - \
    && chmod +x tmux.appimage
fi

### rsync command to copy tmux config
# rsync -avz --no-perms --no-owner --no-group --no-links -e \
# "ssh -F /home/ragu/.ssh/config" ~/.config/tmux/ \
# nv_ovx_local_lovelace:/localhome/local-rmanjegowda/.config/tmux


$TMUX_BIN_PATH -L "appimage" "$@"
