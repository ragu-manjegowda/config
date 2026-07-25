#!/bin/zsh

tmux_config_path="$HOME/.config/tmux/tmux.conf"
sed -i -e "s#solarized-dark#solarized-light#g" "$tmux_config_path"

if tmux has-session 2>/dev/null; then
    tmux source-file "$tmux_config_path"
    tmux list-clients -F '#{client_name}' | while IFS= read -r client; do
        tmux refresh-client -t "$client" -S
    done
fi
