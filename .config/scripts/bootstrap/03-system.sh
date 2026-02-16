#!/usr/bin/env bash
# 03-system.sh - Deploy system config files from ~/.config/misc/

log_step "System Configuration"

log_info "Deploying systemd configs..."
check_copy "${MISC_DIR}/etc/systemd/logind.conf" /etc/systemd/logind.conf

log_info "Deploying mkinitcpio.conf..."
_mkinitcpio_changed=false
if [[ -f /etc/mkinitcpio.conf ]] && diff -q "${MISC_DIR}/etc/mkinitcpio.conf" /etc/mkinitcpio.conf &>/dev/null; then
    log_ok "Already up to date: /etc/mkinitcpio.conf"
else
    _mkinitcpio_changed=true
    check_copy "${MISC_DIR}/etc/mkinitcpio.conf" /etc/mkinitcpio.conf
fi
if [[ "$_mkinitcpio_changed" == true ]]; then
    if prompt_yn "mkinitcpio.conf was updated. Rebuild initramfs now (mkinitcpio -P)?"; then
        sudo mkinitcpio -P
        log_ok "Initramfs rebuilt"
    else
        REMINDERS+=("Run 'sudo mkinitcpio -P' to rebuild initramfs")
    fi
fi

log_info "Deploying PAM config..."
check_copy "${MISC_DIR}/etc/pam.d/system-local-login" /etc/pam.d/system-local-login

log_info "Deploying NFS exports..."
check_copy "${MISC_DIR}/etc/exports" /etc/exports

log_info "Deploying profile.d scripts..."
check_copy "${MISC_DIR}/etc/profile.d/libreoffice-still.sh" /etc/profile.d/libreoffice-still.sh

log_info "Deploying X11 input configs..."
check_copy "${MISC_DIR}/etc/X11/xorg.conf.d/30-touchpad.conf" /etc/X11/xorg.conf.d/30-touchpad.conf
check_copy "${MISC_DIR}/etc/X11/xorg.conf.d/31-touchscreen.conf" /etc/X11/xorg.conf.d/31-touchscreen.conf

log_info "Deploying xsessions..."
check_copy "${MISC_DIR}/usr/share/xsessions/awesome.desktop" /usr/share/xsessions/awesome.desktop

log_info "Deploying pacman hooks..."
check_copy_dir "${MISC_DIR}/usr/share/libalpm/hooks" /usr/share/libalpm/hooks

log_info "Setting up archiso-backup symlink..."
check_symlink "${HOME}/.config/archiso-backup" /var/archiso-backup sudo

log_info "Keyboard layout..."
_current_keymap="$(localectl status 2>/dev/null | grep 'VC Keymap' | awk '{print $3}')"
if [[ "$_current_keymap" == "mod-dh-ansi-us" ]]; then
    log_ok "Colemak DH console layout already set"
else
    sudo localectl set-keymap us mod-dh-ansi-us || log_warn "Failed to set console keymap"
fi

_current_x11_variant="$(localectl status 2>/dev/null | grep 'X11 Variant' | awk '{print $3}')"
if [[ "$_current_x11_variant" == "colemak_dh" ]]; then
    log_ok "Colemak DH X11 layout already set"
else
    sudo localectl set-x11-keymap us "" colemak_dh "lv3:ralt_alt" || log_warn "Failed to set X11 keymap"
fi
