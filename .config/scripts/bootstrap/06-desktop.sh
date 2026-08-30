#!/usr/bin/env bash
# 06-desktop.sh - AwesomeWM, greetd, darkman, polkit, symlinks

log_step "Desktop Environment"

log_info "Greetd config..."
_validate_greetd() {
    python -c '
import sys
import tomllib

with open(sys.argv[1], "rb") as config_file:
    config = tomllib.load(config_file)
command = config.get("default_session", {}).get("command", "")
if not command.startswith("tuigreet "):
    raise SystemExit("default_session.command must launch tuigreet")
' "$1"
}
install_validated_admin_config \
    "${MISC_DIR}/etc/greetd/config.toml" /etc/greetd/config.toml _validate_greetd

log_info "Login and lockscreen media keys..."
check_copy "${MISC_DIR}/usr/local/libexec/login-media-keys" \
    /usr/local/libexec/login-media-keys
check_copy "${MISC_DIR}/etc/systemd/system/login-media-keys.service" \
    /etc/systemd/system/login-media-keys.service
enable_system_service login-media-keys.service

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

REMINDERS+=("Allow suspend without a password if needed: sudoedit /etc/sudoers and add 'ragu ALL=(ALL:ALL) NOPASSWD: /usr/bin/systemctl suspend'")

unset -f _validate_greetd
