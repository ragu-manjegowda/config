#!/usr/bin/env bash
# 07-apps.sh - Application-specific setup

log_step "Application Setup"

log_info "Sioyek dictionary extension..."
_sioyek_ext="${HOME}/.config/sioyek/extensions/sioyek-dict"
if [[ -d "$_sioyek_ext" ]] && [[ -f "${_sioyek_ext}/Makefile" ]]; then
    (cd "$_sioyek_ext" && make install 2>/dev/null)
    log_ok "Sioyek dict extension installed"
else
    log_warn "Sioyek dict extension not found, skipping"
fi

log_info "Python virtual environment..."
_venv_dir="${HOME}/.local/share/venv"
if [[ -d "$_venv_dir" ]]; then
    log_ok "Python venv already exists at $_venv_dir"
else
    if check_command uv; then
        uv venv --system-site-packages "$_venv_dir"
        log_ok "Python venv created at $_venv_dir"
        _requirements="${HOME}/.config/misc/requirements.in"
        if [[ -f "$_requirements" ]]; then
            uv pip install -r "$_requirements" --python "${_venv_dir}/bin/python" || \
                log_warn "Some pip packages failed to install from requirements.in"
        fi
    else
        log_warn "uv not found, skipping venv creation"
    fi
fi

log_info "Neovim Python provider..."
if python3 -c "import pynvim" &>/dev/null; then
    log_ok "pynvim already installed"
else
    python3 -m pip install --user --upgrade pynvim 2>/dev/null || \
        log_warn "Failed to install pynvim"
fi

REMINDERS+=("Copy rEFInd config to ESP: sudo cp ~/.config/rEFInd/refind.conf /boot/EFI/Boot/ && sudo cp -r ~/.config/rEFInd/refind-theme-regular /boot/EFI/Boot/ && sudo cp ~/.config/rEFInd/refind_linux.conf /boot/EFI/Boot/")
REMINDERS+=("Set up VPN connection in NetworkManager: gateway nvidia.gpcloudservice.com, add DNS servers")
REMINDERS+=("MCP Hub: cd ~/Projects/work/giza_ai/mcp_service/local_proxy/ && npm run auth")
