#!/bin/zsh

tmux_config_path="$HOME/.config/tmux/tmux.conf"
tmux_socket="${TMUX_SOCKET:-${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/tmux-$(id -u)/default}"
sed -i -e "s#solarized-light#solarized-dark#g" "$tmux_config_path"

if [[ -S "$tmux_socket" ]] && tmux -S "$tmux_socket" has-session 2>/dev/null; then
    tmux -S "$tmux_socket" source-file "$tmux_config_path"
    tmux -S "$tmux_socket" list-clients -F '#{client_name}' | while IFS= read -r client; do
        tmux -S "$tmux_socket" refresh-client -t "$client" -S
    done
fi
