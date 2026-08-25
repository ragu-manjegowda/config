#!/usr/bin/env bash
# 04-hardware.sh - Power management, hibernate, backlight, USB wakeup

log_step "Hardware Configuration"

log_info "Zram configuration..."
_validate_zramswap() {
    bash -n "$1" || return 1
    [[ "$(grep -Ec '^SIZE=[0-9]+$' "$1")" == 1 ]] &&
        [[ "$(grep -Ec '^RAM_PERCENT=[0-9]+$' "$1")" == 1 ]] &&
        [[ "$(grep -Ec '^ZRAM_COMPRESSION_ALGO=[[:alnum:]_-]+$' "$1")" == 1 ]] &&
        [[ "$(grep -Ec '^KERNEL_SWAP_DEVICE=/swapfile$' "$1")" == 1 ]]
}
install_validated_admin_config \
    "${MISC_DIR}/etc/zramswap.conf" /etc/zramswap.conf _validate_zramswap

log_info "Hibernate swapfile..."
_swapfile=/swapfile
_swap_size_gib=40
if [[ ! -f "$_swapfile" ]]; then
    log_info "Creating ${_swap_size_gib} GiB swapfile..."
    if ! sudo fallocate -l "${_swap_size_gib}G" "$_swapfile"; then
        sudo rm -f "$_swapfile"
        log_fail "Failed to allocate hibernate swapfile"
        return 1
    fi
    sudo chmod 600 "$_swapfile"
    sudo chown root:root "$_swapfile"
    sudo mkswap "$_swapfile"
    log_ok "Created hibernate swapfile"
else
    log_ok "Hibernate swapfile already exists"
fi

_swap_fstab_entry="/swapfile none swap defaults,pri=10 0 0"
if grep -qE '^/swapfile[[:space:]]' /etc/fstab; then
    log_ok "Swapfile already present in /etc/fstab"
else
    printf '%s\n' "$_swap_fstab_entry" | sudo tee -a /etc/fstab >/dev/null
    log_ok "Added swapfile to /etc/fstab"
fi

_swap_priority="$(swapon --show=NAME,PRIO --noheadings | awk '$1 == "/swapfile" {print $2}')"
if [[ "$_swap_priority" == 10 ]]; then
    log_ok "Hibernate swapfile already active at priority 10"
else
    if [[ -n "$_swap_priority" ]]; then
        sudo swapoff "$_swapfile"
    fi
    sudo swapon --priority 10 "$_swapfile"
    log_ok "Activated hibernate swapfile at priority 10"
fi

_root_uuid="$(findmnt -no UUID /)"
_resume_offset="$(sudo filefrag -v "$_swapfile" | awk '$1 == "0:" {sub(/\.\..*/, "", $4); print $4; exit}')"
if [[ -z "$_root_uuid" || -z "$_resume_offset" ]]; then
    log_fail "Unable to determine hibernate resume parameters"
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
awk -v uuid="$_root_uuid" -v offset="$_resume_offset" '
    /^[[:space:]]*options.*lsm=landlock/ {
        gsub(/root=UUID=[^ ]+/, "root=UUID=" uuid)
        gsub(/ resume=UUID=[^ ]+/, "")
        gsub(/ resume_offset=[^ ]+/, "")
        sub(/ rw /, " rw resume=UUID=" uuid " resume_offset=" offset " ")
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
