#!/usr/bin/env bash
# 04-hardware.sh - Power management, hibernate, backlight, USB wakeup

log_step "Hardware Configuration"

log_info "Sleep/hibernate config..."
check_copy "${MISC_DIR}/etc/systemd/sleep.conf.d/hibernatemode.conf" \
    /etc/systemd/sleep.conf.d/hibernatemode.conf

log_info "USB wakeup disable service..."
check_copy "${MISC_DIR}/etc/systemd/system/disable-USB-wakeup.service" \
    /etc/systemd/system/disable-USB-wakeup.service
enable_system_service disable-USB-wakeup.service

log_info "Backlight udev rules..."
check_copy "${MISC_DIR}/etc/udev/rules.d/90-backlight.rules" \
    /etc/udev/rules.d/90-backlight.rules

log_info "Low battery hibernate udev rule..."
check_copy "${MISC_DIR}/etc/udev/rules.d/98-discharging.rules" \
    /etc/udev/rules.d/98-discharging.rules

log_info "Reloading udev rules..."
sudo udevadm control --reload || log_warn "Failed to reload udev rules"

log_info "Video group membership for backlight..."
if user_in_group video; then
    log_ok "User already in video group"
else
    sudo usermod -aG video "$(whoami)"
    log_ok "Added user to video group"
fi

REMINDERS+=("Ensure resume=UUID=... and resume_offset=... are set in rEFInd kernel options for hibernate support")
