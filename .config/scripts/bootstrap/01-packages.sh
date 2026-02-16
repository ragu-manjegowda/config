#!/usr/bin/env bash
# 01-packages.sh - Install paru, restore pacman/AUR packages, homebrew, zsh

log_step "Package Management"

require_package base-devel git curl

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

if [[ -f "${ARCHISO_BACKUP_DIR}/pkglistAll.txt" ]]; then
    log_info "Restoring packages from pkglistAll.txt (this may take a while)..."
    if paru -S --needed - < "${ARCHISO_BACKUP_DIR}/pkglistAll.txt"; then
        log_ok "Package restore complete"
    else
        log_warn "Some packages failed to install -- review output above and install manually"
    fi
else
    log_warn "No package list found at ${ARCHISO_BACKUP_DIR}/pkglistAll.txt"
fi

if ! check_command brew; then
    log_info "Installing Homebrew..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    log_ok "Homebrew installed"
else
    log_ok "Homebrew already installed"
fi

_brew_backup="${HOME}/.config/homebrew-backup"
if [[ -f "${_brew_backup}/Brewfile" ]]; then
    log_info "Restoring Homebrew packages..."
    _homebrew_prefix="/home/linuxbrew/.linuxbrew"
    if [[ -x "${_homebrew_prefix}/bin/brew" ]]; then
        eval "$("${_homebrew_prefix}/bin/brew" shellenv)"
    fi
    if [[ -f "${_brew_backup}/restore-homebrew_linux.sh" ]]; then
        (cd "$_brew_backup" && ./restore-homebrew_linux.sh)
    fi
    log_ok "Homebrew packages restored"
fi

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
