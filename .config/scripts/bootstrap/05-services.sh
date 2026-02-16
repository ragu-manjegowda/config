#!/usr/bin/env bash
# 05-services.sh - Enable system and user systemd services

log_step "Service Enablement"

log_info "System services..."
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
enable_system_service ntpd
enable_system_service thermald
enable_system_service zramswap

log_info "NTP network dispatcher..."
_ntpd_dispatcher="${MISC_DIR}/etc/NetworkManager/dispatcher.d/10-ntpd"
_ntpd_dest="/etc/NetworkManager/dispatcher.d/10-ntpd"
check_copy "$_ntpd_dispatcher" "$_ntpd_dest"
if [[ -f "$_ntpd_dest" ]]; then
    sudo chmod 700 "$_ntpd_dest"
    sudo chown root:root "$_ntpd_dest"
    log_ok "NTP dispatcher permissions set"
fi

log_info "User services..."
enable_user_service pipewire
enable_user_service pipewire-pulse
enable_user_service wireplumber
enable_user_service noisetorch
enable_user_service lid-brightness-manager
