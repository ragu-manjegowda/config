#!/usr/bin/env bash
# 06-desktop.sh - AwesomeWM, greetd, darkman, polkit, symlinks

log_step "Desktop Environment"

log_info "Greetd config..."
check_copy "${MISC_DIR}/etc/greetd/config.toml" /etc/greetd/config.toml

log_info "Polkit rules..."
check_copy "${MISC_DIR}/etc/polkit-1/rules.d/00-early-checks.rules" \
    /etc/polkit-1/rules.d/00-early-checks.rules

log_info "Darkman symlinks..."
check_symlink "${HOME}/.config/darkman/light-mode.d" "${HOME}/.local/share/light-mode.d"
check_symlink "${HOME}/.config/darkman/dark-mode.d" "${HOME}/.local/share/dark-mode.d"

log_info "Battery widget symlink..."
check_symlink \
    "${HOME}/.config/awesome/library/battery/src/awesome-battery_widget/init.lua" \
    "${HOME}/.config/awesome/library/battery/init.lua"

log_info "Font cache..."
fc-cache &>/dev/null || true
log_ok "Font cache updated"

REMINDERS+=("Add sudoers NOPASSWD lines for suspend/hibernate: sudoedit /etc/sudoers and add 'ragu ALL=(ALL:ALL) NOPASSWD: /usr/bin/systemctl suspend' and 'ragu ALL=(ALL:ALL) NOPASSWD: /usr/bin/systemctl hibernate'")
