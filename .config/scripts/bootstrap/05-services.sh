#!/usr/bin/env bash
# 05-services.sh - Enable system and user systemd services

log_step "Service Enablement"

log_info "System services..."
if [[ "$(systemctl get-default)" == "graphical.target" ]]; then
    log_ok "Default target is already graphical.target"
else
    sudo systemctl set-default graphical.target
    log_ok "Set default target to graphical.target"
fi
enable_system_service sshd
enable_system_service NetworkManager
enable_system_service bluetooth
enable_system_service cups
enable_system_service greetd

log_info "Greeter account hardening..."
_greeter_shell="$(getent passwd greeter 2>/dev/null | cut -d: -f7)"
if [[ -n "$_greeter_shell" && "$_greeter_shell" != "/usr/bin/nologin" ]]; then
    sudo usermod -s /usr/bin/nologin greeter
    log_ok "Set greeter shell to /usr/bin/nologin"
elif [[ -n "$_greeter_shell" ]]; then
    log_ok "greeter shell already set to /usr/bin/nologin"
fi
if systemctl is-enabled ntpd.service &>/dev/null; then
    sudo systemctl disable ntpd.service
    log_ok "Disabled legacy NTP service: ntpd"
fi
enable_system_service systemd-timesyncd
enable_system_service thermald
enable_system_service zramswap

log_info "Legacy NTP network dispatcher..."
_ntpd_dest="${NTPD_DISPATCHER_PATH:-/etc/NetworkManager/dispatcher.d/10-ntpd}"
if [[ -e "$_ntpd_dest" ]]; then
    sudo rm -f -- "$_ntpd_dest"
    log_ok "Removed legacy NTP network dispatcher"
fi

log_info "User services..."
enable_user_service pipewire
enable_user_service pipewire-pulse
enable_user_service wireplumber
enable_user_service darkman
enable_user_service lid-brightness-manager

log_info "User tmpfiles..."
enable_user_service systemd-tmpfiles-setup.service
systemd-tmpfiles --user --create
log_ok "Applied user tmpfiles rules"
