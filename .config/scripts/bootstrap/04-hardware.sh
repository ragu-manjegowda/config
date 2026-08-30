#!/usr/bin/env bash
# 04-hardware.sh - Power management, boot, backlight, USB wakeup

log_step "Hardware Configuration"

log_info "Zram configuration..."
_validate_zramswap() {
    bash -n "$1" || return 1
    [[ "$(grep -Ec '^SIZE=[0-9]+$' "$1")" == 1 ]] &&
        [[ "$(grep -Ec '^RAM_PERCENT=[0-9]+$' "$1")" == 1 ]] &&
        [[ "$(grep -Ec '^ZRAM_COMPRESSION_ALGO=[[:alnum:]_-]+$' "$1")" == 1 ]]
}
install_validated_admin_config \
    "${MISC_DIR}/etc/zramswap.conf" /etc/zramswap.conf _validate_zramswap

_root_uuid="$(findmnt -no UUID /)"
if [[ -z "$_root_uuid" ]]; then
    log_fail "Unable to determine root filesystem UUID"
    return 1
fi

log_info "Fallback initramfs presets..."
_refresh_fallback=false
for _kernel in linux linux-lts; do
    _preset_destination="/etc/mkinitcpio.d/${_kernel}.preset"
    _rendered_preset="$(mktemp)"
    if [[ "$(grep -Ec "^PRESETS=\\('default'\\)$" /usr/share/mkinitcpio/hook.preset)" != 1 ]] || \
       [[ "$(grep -Ec '^#fallback_image=' /usr/share/mkinitcpio/hook.preset)" != 1 ]] || \
       [[ "$(grep -Ec '^#fallback_options=' /usr/share/mkinitcpio/hook.preset)" != 1 ]]; then
        log_fail "Unsupported upstream mkinitcpio preset template"
        return 1
    fi
    sed \
        -e "s/%PKGBASE%/${_kernel}/g" \
        -e "s/^PRESETS=('default')$/PRESETS=('default' 'fallback')/" \
        -e 's/^#fallback_image=/fallback_image=/' \
        -e 's/^#fallback_options=/fallback_options=/' \
        /usr/share/mkinitcpio/hook.preset > "$_rendered_preset"
    if [[ ! -f "$_preset_destination" ]] || \
       ! cmp -s "$_rendered_preset" "$_preset_destination"; then
        _refresh_fallback=true
    fi
    check_copy "$_rendered_preset" "$_preset_destination"
    rm -f "$_rendered_preset"
    if [[ ! -f "/boot/initramfs-${_kernel}-fallback.img" ]]; then
        _refresh_fallback=true
    fi
done
if [[ "$_refresh_fallback" == true ]]; then
    sudo mkinitcpio -p linux
    sudo mkinitcpio -p linux-lts
    log_ok "Generated default and fallback initramfs images"
else
    log_ok "Fallback initramfs images already current"
fi

log_info "rEFInd configuration..."
_rendered_refind="$(mktemp)"
awk -v uuid="$_root_uuid" '
    /^[[:space:]]*options.*lsm=landlock/ {
        gsub(/root=UUID=[^ ]+/, "root=UUID=" uuid)
        gsub(/ resume=UUID=[^ ]+/, "")
        gsub(/ resume_offset=[^ ]+/, "")
        if ($0 !~ / nohibernate([ \"]|$)/) sub(/ rw /, " rw nohibernate ")
    }
    { print }
' "${HOME}/.config/rEFInd/refind.conf" > "$_rendered_refind"
check_copy "$_rendered_refind" /boot/EFI/BOOT/refind.conf
rm -f "$_rendered_refind"
check_copy \
    "${HOME}/.config/rEFInd/refind-theme-regular/theme.conf" \
    /boot/EFI/BOOT/themes/refind-theme-regular/theme.conf
check_copy_dir \
    "${HOME}/.config/rEFInd/refind-theme-regular/icons/128-48" \
    /boot/EFI/BOOT/themes/refind-theme-regular/icons/128-48
check_copy_dir \
    "${HOME}/.config/rEFInd/refind-theme-regular/icons/256-96" \
    /boot/EFI/BOOT/themes/refind-theme-regular/icons/256-96
check_copy_dir \
    "${HOME}/.config/rEFInd/refind-theme-regular/fonts" \
    /boot/EFI/BOOT/themes/refind-theme-regular/fonts
if [[ -d /boot/EFI/BOOT/refind-theme-regular ]]; then
    sudo rm -rf /boot/EFI/BOOT/refind-theme-regular
    log_ok "Removed legacy rEFInd theme path"
fi

log_info "Suspend-only config..."
check_copy "${MISC_DIR}/etc/systemd/sleep.conf.d/90-disable-hibernation.conf" \
    /etc/systemd/sleep.conf.d/90-disable-hibernation.conf
if [[ -e /etc/systemd/sleep.conf.d/hibernatemode.conf ]]; then
    sudo rm -f /etc/systemd/sleep.conf.d/hibernatemode.conf
    log_ok "Removed obsolete hibernate mode config"
fi
sudo systemctl mask \
    systemd-hibernate.service \
    systemd-suspend-then-hibernate.service \
    systemd-hybrid-sleep.service >/dev/null
log_ok "Masked hibernation services"

check_copy "${MISC_DIR}/etc/systemd/system/awesome-lock-before-sleep.service" \
    /etc/systemd/system/awesome-lock-before-sleep.service
enable_system_service awesome-lock-before-sleep.service

log_info "USB wakeup disable service..."
check_copy "${MISC_DIR}/etc/systemd/system/disable-USB-wakeup.service" \
    /etc/systemd/system/disable-USB-wakeup.service
enable_system_service disable-USB-wakeup.service

log_info "Backlight udev rules..."
check_copy "${MISC_DIR}/etc/udev/rules.d/90-backlight.rules" \
    /etc/udev/rules.d/90-backlight.rules

log_info "On-demand IPU7 compatibility camera..."
if [[ -e /etc/modprobe.d/v4l2loopback.conf ]]; then
    sudo rm -f /etc/modprobe.d/v4l2loopback.conf
    log_ok "Removed legacy v4l2loopback configuration"
fi
enable_system_service v4l2-relayd-ipu7.service

log_info "Reloading udev rules..."
sudo udevadm control --reload || log_warn "Failed to reload udev rules"

log_info "Video group membership for backlight..."
if user_in_group video; then
    log_ok "User already in video group"
else
    sudo usermod -aG video "$(whoami)"
    log_ok "Added user to video group"
fi

unset _swapfile _swap_size_gib _swap_fstab_entry _swap_priority
unset _root_uuid _resume_offset _rendered_refind
unset _refresh_fallback _kernel _preset_destination _rendered_preset
unset -f _validate_zramswap
