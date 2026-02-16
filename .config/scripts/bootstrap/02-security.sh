#!/usr/bin/env bash
# 02-security.sh - Firewall, SSH hardening, fail2ban, sysctl, apparmor

log_step "Security Hardening"

log_info "Firewall (nftables)..."
require_package nftables
check_copy "${MISC_DIR}/etc/nftables.conf" /etc/nftables.conf
if sudo nft -c -f /etc/nftables.conf &>/dev/null; then
    sudo nft -f /etc/nftables.conf
    log_ok "nftables rules validated and applied"
else
    log_fail "nftables config validation failed -- rules NOT applied"
fi
enable_system_service nftables

log_info "SSH hardening..."
check_copy "${MISC_DIR}/etc/ssh/sshd_config.d/50-hardening.conf" \
    /etc/ssh/sshd_config.d/50-hardening.conf
if sudo sshd -t &>/dev/null; then
    sudo systemctl restart sshd
    log_ok "sshd config validated and service restarted"
else
    log_fail "sshd config validation failed -- service NOT restarted"
fi

log_info "fail2ban..."
require_package fail2ban
check_copy "${MISC_DIR}/etc/fail2ban/jail.local" /etc/fail2ban/jail.local
enable_system_service fail2ban
if systemctl is-active fail2ban &>/dev/null; then
    sudo systemctl restart fail2ban
fi

log_info "Kernel sysctl hardening..."
check_copy "${MISC_DIR}/etc/sysctl.d/99-security.conf" /etc/sysctl.d/99-security.conf
sudo sysctl --system >/dev/null
log_ok "sysctl rules applied"

log_info "Network privacy (MAC randomization, hostname hiding, IPv6 privacy)..."
check_copy "${MISC_DIR}/etc/NetworkManager/conf.d/privacy.conf" \
    /etc/NetworkManager/conf.d/privacy.conf
REMINDERS+=("Restart NetworkManager to apply MAC randomization and hostname hiding: sudo systemctl restart NetworkManager (will briefly disconnect WiFi)")

log_info "DNS-over-TLS (encrypted DNS via Quad9)..."
check_copy "${MISC_DIR}/etc/systemd/resolved.conf.d/dns-privacy.conf" \
    /etc/systemd/resolved.conf.d/dns-privacy.conf
sudo systemctl restart systemd-resolved || log_warn "Failed to restart systemd-resolved"

log_info "SSH file permissions..."
if [[ -f "${HOME}/.ssh/config" ]]; then
    _perms="$(stat -c '%a' "${HOME}/.ssh/config")"
    if [[ "$_perms" == "600" ]]; then
        log_ok "~/.ssh/config permissions already 600"
    else
        chmod 600 "${HOME}/.ssh/config"
        log_ok "Fixed ~/.ssh/config permissions to 600"
    fi
fi

log_info "AppArmor..."
require_package apparmor
enable_system_service apparmor
if [[ -f /sys/module/apparmor/parameters/enabled ]]; then
    _aa_enabled="$(cat /sys/module/apparmor/parameters/enabled 2>/dev/null || echo 'N')"
    if [[ "$_aa_enabled" == "Y" ]]; then
        log_ok "AppArmor is active"
    else
        log_warn "AppArmor installed and enabled but not active (needs reboot with lsm= kernel param)"
    fi
else
    log_warn "AppArmor not active -- ensure lsm=landlock,lockdown,yama,integrity,apparmor,bpf is in rEFInd kernel options"
fi
