#!/bin/bash

# Based on https://stackoverflow.com/a/21756612
# following files are ignored for local changes
git --git-dir="$HOME/.config.git" --work-tree="$HOME" update-index --assume-unchanged \
    .config/alacritty/alacritty.toml \
    .config/awesome/configuration/rofi/appmenu/rofi.rasi \
    .config/awesome/configuration/rofi/calc/rofi.rasi \
    .config/awesome/configuration/rofi/emojimenu/rofi.rasi \
    .config/awesome/configuration/rofi/help/rofi.rasi \
    .config/awesome/configuration/rofi/runmenu/rofi.rasi \
    .config/awesome/configuration/rofi/time/rofi.rasi \
    .config/awesome/widget/dont-disturb/disturb_status \
    .config/chrome-flags.conf \
    .config/codex/config.toml \
    .config/git/config \
    .config/gtk-3.0/settings.ini \
    .config/gtk-4.0/gtk.css \
    .config/neomutt/config/colors.muttrc \
    .config/nvim/lua/user/colorscheme.lua \
    .config/opencode/opencode.json \
    .config/opencode/tui.json \
    .config/ranger/colorschemes/neosolarized.py \
    .config/rofi/config.rasi \
    .config/sioyek/prefs_user.config \
    .config/termshark/termshark.toml \
    .config/tmux/tmux.conf \
    .config/xsettingsd/xsettingsd.conf \
    .config/yazi/theme.toml \
    .gtkrc-2.0 \
    .icons/default/index.theme \
    .local/bin/render-wiki.sh
