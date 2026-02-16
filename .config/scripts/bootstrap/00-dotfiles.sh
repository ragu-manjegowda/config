#!/usr/bin/env bash
# 00-dotfiles.sh - Clone dotfiles repo and initialize submodules
# Sourced by bootstrap.sh - do not run directly.

log_step "Dotfiles & Git"

cd ~/ || return 1

if [[ -f ~/LICENSE ]]; then
    log_ok "Dotfiles already cloned"
else
    log_info "Cloning dotfiles repository..."

    [[ -d .config ]] && mv .config .config.bak
    [[ -f .profile ]] && mv .profile .profile.bak
    [[ -d .ssh ]] && mv .ssh .ssh.bak

    git clone https://github.com/ragu-manjegowda/config.git config.git
    mv config.git/.git .config.git
    shopt -s dotglob
    mv -i config.git/* .
    rmdir config.git

    git --git-dir="${HOME}/.config.git" --work-tree="${HOME}" \
        config --local core.worktree "${HOME}"

    log_ok "Dotfiles cloned and configured"
fi

log_info "Updating submodules..."
git --git-dir="${HOME}/.config.git" --work-tree="${HOME}" \
    submodule update --init --recursive

log_info "Setting git assume-unchanged for local config files..."
if [[ -f "${HOME}/.config/scripts/config-ignore-local.sh" ]]; then
    bash "${HOME}/.config/scripts/config-ignore-local.sh"
    log_ok "Local config ignore rules applied"
fi
