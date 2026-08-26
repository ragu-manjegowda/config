#!/usr/bin/env bash
# 01-packages.sh - Install paru, restore pacman/AUR packages, homebrew, zsh

log_step "Package Management"

require_package base-devel git curl gnupg

_restore_sentinel=/run/arch-bootstrap-package-restore
_manifest_dir="$(mktemp -d)"
_manifest_repo="${HOME}/.config.git"

_package_cleanup() {
    sudo rm -f "$_restore_sentinel"
    rm -rf "$_manifest_dir"
}

sudo touch "$_restore_sentinel"
trap _package_cleanup EXIT

log_info "Loading package manifests from Git HEAD..."
if ! git --git-dir="$_manifest_repo" show \
    HEAD:.config/archiso-backup/pkglistPacmanInstalled.txt \
    > "${_manifest_dir}/pkglistPacmanInstalled.txt" ||
   ! git --git-dir="$_manifest_repo" show \
    HEAD:.config/archiso-backup/foreignpkglist.txt \
    > "${_manifest_dir}/foreignpkglist.txt" ||
   ! git --git-dir="$_manifest_repo" show \
    HEAD:.config/archiso-backup/pkglistAll.txt \
    > "${_manifest_dir}/pkglistAll.txt"; then
    log_fail "Unable to read committed package manifests"
    return 1
fi

if ! check_command brew; then
    log_info "Installing Homebrew..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    log_ok "Homebrew installed"
else
    log_ok "Homebrew already installed"
fi

_homebrew_prefix="/home/linuxbrew/.linuxbrew"
if [[ -x "${_homebrew_prefix}/bin/brew" ]]; then
    eval "$("${_homebrew_prefix}/bin/brew" shellenv)"
fi

_brew_backup="${HOME}/.config/homebrew-backup"
if [[ -f "${_brew_backup}/Brewfile" ]]; then
    log_info "Restoring Homebrew packages..."
    brew bundle install --file="${_brew_backup}/Brewfile"
    log_ok "Homebrew packages restored"
fi

export GNUPGHOME="${GNUPGHOME:-${XDG_CONFIG_HOME:-${HOME}/.config}/gnupg}"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

_has_gpg_secret_key() {
    gpg --batch --with-colons --list-secret-keys 2>/dev/null | grep -q '^sec:'
}

_git_crypt_deferred=false
while ! _has_gpg_secret_key; do
    log_warn "No GPG secret key is available in ${GNUPGHOME}"
    printf '%s\n' \
        "  1) Import a secret-key file" \
        "  2) Re-check after importing from another terminal or token" \
        "  3) Defer encrypted dotfiles"
    read -r -p "Choose [1-3, default 3]: " _gpg_choice

    case "$_gpg_choice" in
        1)
            read -r -p "Secret-key file path: " _gpg_key_file
            _gpg_key_file="${_gpg_key_file/#\~/${HOME}}"
            if [[ -f "$_gpg_key_file" ]]; then
                gpg --import "$_gpg_key_file"
            else
                log_warn "Key file not found: $_gpg_key_file"
            fi
            ;;
        2)
            ;;
        3|"")
            _git_crypt_deferred=true
            REMINDERS+=("Import your GPG secret key into ${GNUPGHOME}, then run: GIT_DIR=~/.config.git GIT_WORK_TREE=~ git-crypt unlock")
            break
            ;;
        *)
            log_warn "Choose 1, 2, or 3"
            ;;
    esac
done

if [[ "$_git_crypt_deferred" == false ]]; then
    if ! command -v git-crypt &>/dev/null; then
        log_fail "git-crypt was not installed by the Homebrew bundle"
        return 1
    fi
    log_info "Unlocking encrypted dotfiles..."
    GIT_DIR="${HOME}/.config.git" GIT_WORK_TREE="${HOME}" git-crypt unlock
    log_ok "Encrypted dotfiles unlocked"

    log_info "OpenCode configuration..."
    _opencode_source="${HOME}/.omo/omo.terra.jsonc"
    _opencode_destination="${HOME}/.omo/omo.jsonc"
    if [[ ! -f "$_opencode_source" ]]; then
        log_fail "OpenCode source config not found: $_opencode_source"
        return 1
    fi
    mkdir -p "${HOME}/.omo"
    if [[ -f "$_opencode_destination" ]] && \
       cmp -s "$_opencode_source" "$_opencode_destination"; then
        chmod 600 "$_opencode_destination"
        log_ok "OpenCode configuration already current"
    else
        install -m 600 "$_opencode_source" "$_opencode_destination"
        log_ok "Installed OpenCode Terra configuration"
    fi
else
    log_warn "Encrypted dotfiles deferred; continuing with unencrypted configuration"
fi

if command -v paru &>/dev/null; then
    log_ok "paru already installed"
else
    log_info "Installing paru..."
    _paru_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru.git "$_paru_dir"
    (cd "$_paru_dir" && makepkg -si --noconfirm)
    rm -rf "$_paru_dir"
    log_ok "paru installed"
fi

_pacman_packages="${_manifest_dir}/pkglistPacmanInstalled.txt"
_aur_packages="${_manifest_dir}/foreignpkglist.txt"

log_info "Refreshing configured GitHub PKGBUILD repositories..."
if paru -Sy --noconfirm --pkgbuilds; then
    log_ok "GitHub PKGBUILD repositories refreshed"
else
    log_warn "Some GitHub PKGBUILD repositories failed to refresh"
fi

if [[ -f "$_pacman_packages" ]]; then
    log_info "Restoring official packages (this may take a while)..."
    if sudo pacman -S --needed --noconfirm - < "$_pacman_packages"; then
        mapfile -t _explicit_packages < "$_pacman_packages"
        sudo pacman -D --asexplicit "${_explicit_packages[@]}"
        log_ok "Official package restore complete"
    else
        log_warn "Some official packages failed to install -- review output above"
    fi
else
    log_warn "No official package list found at $_pacman_packages"
fi

if [[ -f "$_aur_packages" ]]; then
    log_info "Restoring AUR packages (this may take a while)..."
    _failed_aur_packages=()
    while IFS= read -r _aur_package <&3 || [[ -n "$_aur_package" ]]; do
        [[ -z "$_aur_package" || "$_aur_package" == \#* ]] && continue
        if [[ "$_aur_package" == "intel-vision-drivers-dkms-ipu7-ov08x40" ||
              "$_aur_package" == "libcamera-ipu7-ov08x40" ||
              "$_aur_package" == "libcamera-ipu7-ov08x40-ipa" ]]; then
            if paru -Qi "$_aur_package" &>/dev/null; then
                continue
            fi
            if ! paru -S --needed --pkgbuilds \
                intel-vision-drivers-dkms-ipu7-ov08x40 \
                libcamera-ipu7-ov08x40 \
                libcamera-ipu7-ov08x40-ipa; then
                _failed_aur_packages+=("$_aur_package")
            fi
        elif ! paru -S --needed "$_aur_package"; then
            _failed_aur_packages+=("$_aur_package")
        fi
    done 3< "$_aur_packages"

    if [[ ${#_failed_aur_packages[@]} -eq 0 ]]; then
        log_ok "AUR package restore complete"
    else
        log_warn "Unavailable AUR packages: ${_failed_aur_packages[*]}"
        REMINDERS+=("Review unavailable AUR packages: ${_failed_aur_packages[*]}")
    fi
else
    log_warn "No AUR package list found at $_aur_packages"
fi

if [[ "${PRUNE_PACKAGES:-false}" == true ]]; then
    log_info "Comparing installed packages with committed manifests..."
    sort -u "${_manifest_dir}/pkglistAll.txt" > "${_manifest_dir}/desired.txt"
    pacman -Qq | sort -u > "${_manifest_dir}/installed-all.txt"
    comm -12 \
        "${_manifest_dir}/desired.txt" \
        "${_manifest_dir}/installed-all.txt" \
        > "${_manifest_dir}/installed-desired.txt"
    mapfile -t _desired_packages < "${_manifest_dir}/installed-desired.txt"
    sudo pacman -D --asexplicit "${_desired_packages[@]}"

    pacman -Qqe | sort -u > "${_manifest_dir}/installed-explicit.txt"
    comm -23 \
        "${_manifest_dir}/installed-explicit.txt" \
        "${_manifest_dir}/desired.txt" \
        > "${_manifest_dir}/extras.txt"

    mapfile -t _extra_packages < "${_manifest_dir}/extras.txt"
    if [[ ${#_extra_packages[@]} -eq 0 ]]; then
        log_ok "No extra explicit packages found"
    else
        printf '%s\n' "${_extra_packages[@]}"
        if prompt_yn "Demote these extra packages and remove resulting orphans?"; then
            sudo pacman -D --asdeps "${_extra_packages[@]}"
            mapfile -t _orphan_packages < <(pacman -Qdttq)
            if [[ ${#_orphan_packages[@]} -eq 0 ]]; then
                log_ok "No orphaned packages to remove"
            elif ! sudo pacman -Rns "${_orphan_packages[@]}"; then
                sudo pacman -D --asexplicit "${_extra_packages[@]}"
                log_warn "Removal cancelled; restored original explicit install reasons"
            fi
        else
            log_info "Package pruning skipped"
        fi
    fi
fi

if [[ -x "${HOME}/.local/bin/topgrade" ]]; then
    log_info "Restoring profile-managed packages..."
    "${HOME}/.local/bin/topgrade"
    log_ok "Profile-managed packages restored"
fi

unset _pacman_packages _aur_packages _aur_package _failed_aur_packages
unset _explicit_packages _desired_packages _brew_backup _homebrew_prefix
unset _extra_packages _orphan_packages
unset _git_crypt_deferred _gpg_choice _gpg_key_file
unset _opencode_source _opencode_destination
unset -f _has_gpg_secret_key

_package_cleanup
trap - EXIT
unset -f _package_cleanup
unset _restore_sentinel _manifest_dir _manifest_repo

if [[ "$SHELL" == *"zsh"* ]]; then
    log_ok "Default shell is already zsh"
else
    _zsh_path="$(which zsh 2>/dev/null || true)"
    if [[ -n "$_zsh_path" ]]; then
        chsh -s "$_zsh_path"
        log_ok "Default shell changed to zsh"
    else
        log_warn "zsh not found, skipping shell change"
    fi
fi
