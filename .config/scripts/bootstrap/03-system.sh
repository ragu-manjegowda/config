#!/usr/bin/env bash
# 03-system.sh - Deploy system config files from ~/.config/misc/

log_step "System Configuration"

log_info "Deploying systemd configs..."
_logind_dropin="/etc/systemd/logind.conf.d/90-local.conf"
if [[ ! -f "$_logind_dropin" ]]; then
    _rendered_config="$(mktemp)"
    package_file_source /etc/systemd/logind.conf "$_rendered_config"
    install_rendered_config "$_rendered_config" /etc/systemd/logind.conf
    rm -f "$_rendered_config"
fi
check_copy "${MISC_DIR}/etc/systemd/logind.conf.d/90-local.conf" "$_logind_dropin"

log_info "Deploying Intel Xe display workaround..."
check_copy "${MISC_DIR}/etc/modprobe.d/xe.conf" /etc/modprobe.d/xe.conf

log_info "Deploying mkinitcpio.conf..."
_mkinitcpio_changed=false
_mkinitcpio_dropin="/etc/mkinitcpio.conf.d/90-resume.conf"
if [[ ! -f "$_mkinitcpio_dropin" ]]; then
    _rendered_config="$(mktemp)"
    package_file_source /etc/mkinitcpio.conf "$_rendered_config"
    install_rendered_config "$_rendered_config" /etc/mkinitcpio.conf
    rm -f "$_rendered_config"
    _mkinitcpio_changed=true
fi
if [[ ! -f "$_mkinitcpio_dropin" ]] || \
   ! cmp -s "${MISC_DIR}/etc/mkinitcpio.conf.d/90-resume.conf" "$_mkinitcpio_dropin"; then
    _mkinitcpio_changed=true
fi
check_copy "${MISC_DIR}/etc/mkinitcpio.conf.d/90-resume.conf" "$_mkinitcpio_dropin"
if [[ "$_mkinitcpio_changed" == true ]]; then
    if prompt_yn "mkinitcpio.conf was updated. Rebuild initramfs now (mkinitcpio -P)?"; then
        sudo mkinitcpio -P
        log_ok "Initramfs rebuilt"
    else
        REMINDERS+=("Run 'sudo mkinitcpio -P' to rebuild initramfs")
    fi
fi

log_info "Deploying PAM config..."
_rendered_config="$(mktemp)"
package_file_source /etc/pam.d/system-local-login "$_rendered_config"
if [[ "$(grep -Ec '^[[:space:]]*auth[[:space:]]+include[[:space:]]+system-login' "$_rendered_config")" != 1 ]]; then
    log_fail "Unsupported system-local-login PAM structure"
    return 1
fi
awk '
    /^[[:space:]]*auth[[:space:]]+include[[:space:]]+system-login/ {
        print "auth      sufficient pam_unix.so try_first_pass likeauth nullok"
        print "auth      sufficient pam_fprintd.so"
    }
    { print }
' "$_rendered_config" > "${_rendered_config}.new"
install_rendered_config "${_rendered_config}.new" /etc/pam.d/system-local-login
rm -f "$_rendered_config" "${_rendered_config}.new"

_rendered_config="$(mktemp)"
package_file_source /etc/pam.d/sudo "$_rendered_config"
if [[ "$(grep -Ec '^[[:space:]]*auth[[:space:]]+include[[:space:]]+system-auth' "$_rendered_config")" != 1 ]]; then
    log_fail "Unsupported sudo PAM structure"
    return 1
fi
awk '
    /^[[:space:]]*auth[[:space:]]+include[[:space:]]+system-auth/ {
        print "auth      sufficient pam_unix.so try_first_pass likeauth nullok"
        print "auth      sufficient pam_fprintd.so max-tries=3 timeout=10"
        print "auth      required   pam_deny.so"
        next
    }
    { print }
' "$_rendered_config" > "${_rendered_config}.new"
install_rendered_config "${_rendered_config}.new" /etc/pam.d/sudo
rm -f "$_rendered_config" "${_rendered_config}.new"

log_info "Deploying NFS exports..."
_validate_exports() {
    local path clients
    while read -r path clients; do
        [[ -z "$path" || "$path" == \#* ]] && continue
        if [[ -z "$clients" || ! -e "$path" ]]; then
            log_fail "Invalid NFS export path: $path"
            return 1
        fi
    done < "$1"
}
install_validated_admin_config "${MISC_DIR}/etc/exports" /etc/exports _validate_exports
sudo exportfs -ra

log_info "Deploying profile.d scripts..."
_libreoffice_override=/etc/profile.d/99-libreoffice-vcl.sh
if [[ ! -f "$_libreoffice_override" ]]; then
    _rendered_config="$(mktemp)"
    package_file_source /etc/profile.d/libreoffice-still.sh "$_rendered_config"
    install_rendered_config "$_rendered_config" /etc/profile.d/libreoffice-still.sh
    rm -f "$_rendered_config"
fi
check_copy "${MISC_DIR}/etc/profile.d/99-libreoffice-vcl.sh" "$_libreoffice_override"

log_info "Deploying X11 input configs..."
check_copy "${MISC_DIR}/etc/X11/xorg.conf.d/30-touchpad.conf" /etc/X11/xorg.conf.d/30-touchpad.conf
check_copy "${MISC_DIR}/etc/X11/xorg.conf.d/31-touchscreen.conf" /etc/X11/xorg.conf.d/31-touchscreen.conf

log_info "Deploying pacman hooks..."
check_copy_dir "${MISC_DIR}/etc/pacman.d/hooks" /etc/pacman.d/hooks

log_info "Setting up archiso-backup symlink..."
check_symlink "${HOME}/.config/archiso-backup" /var/archiso-backup sudo

log_info "Keyboard layout..."
_current_keymap="$(localectl status 2>/dev/null | awk -F: '$1 ~ /VC Keymap/ {gsub(/^[[:space:]]+/, "", $2); print $2}')"
if [[ "$_current_keymap" == "mod-dh-ansi-us" ]]; then
    log_ok "Colemak DH console layout already set"
else
    sudo localectl set-keymap us mod-dh-ansi-us || log_warn "Failed to set console keymap"
fi

_current_x11_variant="$(localectl status 2>/dev/null | awk -F: '$1 ~ /X11 Variant/ {gsub(/^[[:space:]]+/, "", $2); print $2}')"
if [[ "$_current_x11_variant" == "colemak_dh" ]]; then
    log_ok "Colemak DH X11 layout already set"
else
    sudo localectl set-x11-keymap us "" colemak_dh "lv3:ralt_alt" || log_warn "Failed to set X11 keymap"
fi

unset _logind_dropin _mkinitcpio_dropin _mkinitcpio_changed _rendered_config
unset _libreoffice_override
unset -f _validate_exports
