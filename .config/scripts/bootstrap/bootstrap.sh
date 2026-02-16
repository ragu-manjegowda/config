#!/usr/bin/env bash
# Arch Linux system bootstrap - orchestrator

set -euo pipefail

BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${BOOTSTRAP_DIR}/lib.sh"

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --from N    Start from step N (0-7), skipping earlier steps
  --only N    Run only step N
  --help      Show this help

Steps:
  0  Dotfiles     Clone repo, submodules, git worktree config
  1  Packages     paru, pacman restore, homebrew, zsh
  2  Security     Firewall, SSH hardening, fail2ban, sysctl, apparmor
  3  System       Deploy system config files from ~/.config/misc/
  4  Hardware     Power management, hibernate, backlight, USB wakeup
  5  Services     Enable system and user systemd services
  6  Desktop      AwesomeWM, greetd, darkman, polkit, symlinks
  7  Apps         Sioyek, python venv, neovim, VPN reminders
EOF
}

if [[ "$(grep -Po '(?<=^ID=).+' /etc/os-release 2>/dev/null | tr -d '"')" != "arch" ]]; then
    log_fail "This script is for Arch Linux only."
    exit 1
fi

FROM_STEP=0
ONLY_STEP=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --from)  FROM_STEP="$2"; shift 2 ;;
        --only)  ONLY_STEP="$2"; shift 2 ;;
        --help)  usage; exit 0 ;;
        *)       log_fail "Unknown option: $1"; usage; exit 1 ;;
    esac
done

STEPS=(
    "00-dotfiles.sh"
    "01-packages.sh"
    "02-security.sh"
    "03-system.sh"
    "04-hardware.sh"
    "05-services.sh"
    "06-desktop.sh"
    "07-apps.sh"
)

REMINDERS=()

run_step() {
    local idx="$1" script="${STEPS[$1]}"
    local path="${BOOTSTRAP_DIR}/${script}"

    if [[ ! -f "$path" ]]; then
        log_fail "Script not found: $path"
        return 1
    fi

    log_step "Step ${idx}: ${script%.sh}"
    source "$path"
}

if [[ -n "$ONLY_STEP" ]]; then
    run_step "$ONLY_STEP"
else
    for i in "${!STEPS[@]}"; do
        if [[ "$i" -ge "$FROM_STEP" ]]; then
            run_step "$i"
        fi
    done
fi

echo ""
log_step "Bootstrap complete"

if [[ ${#REMINDERS[@]} -gt 0 ]]; then
    echo ""
    log_step "Manual steps remaining"
    for reminder in "${REMINDERS[@]}"; do
        log_reminder "$reminder"
    done
fi
