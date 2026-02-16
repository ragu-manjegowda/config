#!/usr/bin/env bash
# lib.sh - Shared helper functions for Arch Linux bootstrap scripts
# Source this file, do not execute directly.

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
_RED='\033[1;31m'
_GREEN='\033[1;32m'
_YELLOW='\033[1;33m'
_BLUE='\033[1;34m'
_BOLD='\033[1m'
_RESET='\033[0m'

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
log_ok()   { printf "${_GREEN}[OK]${_RESET}   %s\n" "$*"; }
log_warn() { printf "${_YELLOW}[WARN]${_RESET} %s\n" "$*"; }
log_fail() { printf "${_RED}[FAIL]${_RESET} %s\n" "$*"; }
log_info() { printf "${_BLUE}[INFO]${_RESET} %s\n" "$*"; }
log_step() { printf "\n${_BOLD}==> %s${_RESET}\n" "$*"; }
log_reminder() { printf "${_YELLOW}[MANUAL]${_RESET} %s\n" "$*"; }

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
MISC_DIR="${HOME}/.config/misc"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHISO_BACKUP_DIR="${HOME}/.config/archiso-backup"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Compare two files; copy source → dest (with sudo) only if different.
# Usage: check_copy <source> <dest>
# Returns 0 if copied/already matching, 1 on failure.
check_copy() {
    local src="$1" dest="$2"

    if [[ ! -f "$src" ]]; then
        log_fail "Source file not found: $src"
        return 1
    fi

    # Create destination directory if it doesn't exist
    local dest_dir
    dest_dir="$(dirname "$dest")"
    if [[ ! -d "$dest_dir" ]]; then
        sudo mkdir -p "$dest_dir"
    fi

    if [[ -f "$dest" ]] && diff -q "$src" "$dest" &>/dev/null; then
        log_ok "Already up to date: $dest"
        return 0
    fi

    sudo cp "$src" "$dest"
    log_ok "Copied: $src → $dest"
}

# Copy all files from a source directory to a dest directory (preserving structure).
# Usage: check_copy_dir <src_dir> <dest_dir>
check_copy_dir() {
    local src_dir="$1" dest_dir="$2"

    if [[ ! -d "$src_dir" ]]; then
        log_fail "Source directory not found: $src_dir"
        return 1
    fi

    local src_file rel_path
    while IFS= read -r -d '' src_file; do
        rel_path="${src_file#"$src_dir"/}"
        check_copy "$src_file" "${dest_dir}/${rel_path}"
    done < <(find "$src_dir" -type f -print0)
}

# Enable a system service if not already enabled.
# Usage: enable_system_service <service_name>
enable_system_service() {
    local svc="$1"
    if ! systemctl cat "$svc" &>/dev/null 2>&1; then
        log_warn "Service unit not found: $svc (package not installed?)"
        return 0
    fi
    if systemctl is-enabled "$svc" &>/dev/null; then
        log_ok "System service already enabled: $svc"
    else
        sudo systemctl enable "$svc"
        log_ok "Enabled system service: $svc"
    fi
}

# Enable a user service if not already enabled.
# Usage: enable_user_service <service_name>
enable_user_service() {
    local svc="$1"
    if ! systemctl --user cat "$svc" &>/dev/null 2>&1; then
        log_warn "User service unit not found: $svc (not installed?)"
        return 0
    fi
    if systemctl --user is-enabled "$svc" &>/dev/null; then
        log_ok "User service already enabled: $svc"
    else
        systemctl --user enable "$svc"
        log_ok "Enabled user service: $svc"
    fi
}

# Install pacman packages if not already installed.
# Usage: require_package pkg1 pkg2 ...
require_package() {
    local missing=()
    for pkg in "$@"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_ok "Packages already installed: $*"
        return 0
    fi

    log_info "Installing packages: ${missing[*]}"
    sudo pacman -S --needed --noconfirm "${missing[@]}"
    log_ok "Installed: ${missing[*]}"
}

# Install AUR packages via paru if not already installed.
# Usage: require_aur_package pkg1 pkg2 ...
require_aur_package() {
    local missing=()
    for pkg in "$@"; do
        if ! paru -Qi "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_ok "AUR packages already installed: $*"
        return 0
    fi

    log_info "Installing AUR packages: ${missing[*]}"
    paru -S --needed --noconfirm "${missing[@]}"
    log_ok "Installed AUR: ${missing[*]}"
}

# Prompt yes/no. Returns 0 for yes, 1 for no. Default is No.
# Usage: prompt_yn "Rebuild initramfs?" && mkinitcpio -P
prompt_yn() {
    local prompt="$1"
    local reply
    printf "${_YELLOW}%s [y/N]${_RESET} " "$prompt"
    read -r reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

# Create a symlink if it doesn't already exist or points elsewhere.
# Usage: check_symlink <target> <link_path> [use_sudo]
check_symlink() {
    local target="$1" link_path="$2" use_sudo="${3:-}"

    if [[ -L "$link_path" ]]; then
        local current_target
        current_target="$(readlink "$link_path")"
        if [[ "$current_target" == "$target" ]]; then
            log_ok "Symlink already correct: $link_path → $target"
            return 0
        fi
        # Wrong target, remove and recreate
        if [[ -n "$use_sudo" ]]; then
            sudo rm "$link_path"
        else
            rm "$link_path"
        fi
    fi

    if [[ -e "$link_path" ]]; then
        log_warn "Path exists but is not a symlink: $link_path (skipping)"
        return 1
    fi

    local link_dir
    link_dir="$(dirname "$link_path")"
    if [[ ! -d "$link_dir" ]]; then
        if [[ -n "$use_sudo" ]]; then
            sudo mkdir -p "$link_dir"
        else
            mkdir -p "$link_dir"
        fi
    fi

    if [[ -n "$use_sudo" ]]; then
        sudo ln -s "$target" "$link_path"
    else
        ln -s "$target" "$link_path"
    fi
    log_ok "Created symlink: $link_path → $target"
}

# Check if user is in a group.
# Usage: user_in_group <group>
user_in_group() {
    id -nG | grep -qw "$1"
}

# Check that a command exists.
# Usage: check_command <cmd> || return 1
check_command() {
    if command -v "$1" &>/dev/null; then
        return 0
    fi
    log_fail "Command not found: $1"
    return 1
}
