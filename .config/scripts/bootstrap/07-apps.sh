#!/usr/bin/env bash
# 07-apps.sh - Application-specific setup

log_step "Application Setup"

log_info "Cargo home..."
_cargo_home="${XDG_DATA_HOME:-${HOME}/.local/share}/cargo"
mkdir -p "$_cargo_home"
for _legacy_cargo_home in "${HOME}/.config/cargo" "${HOME}/.cargo"; do
    if [[ -d "$_legacy_cargo_home" && ! -L "$_legacy_cargo_home" ]]; then
        cp -a -n "${_legacy_cargo_home}/." "$_cargo_home/"
        rm -rf "$_legacy_cargo_home"
        log_ok "Merged legacy Cargo home from $_legacy_cargo_home"
    fi
done
check_symlink "$_cargo_home" "${HOME}/.cargo"
export CARGO_HOME="$_cargo_home"

_rustup_home="${XDG_DATA_HOME:-${HOME}/.local/share}/rustup"
if [[ -d "${HOME}/.config/rustup" && ! -L "${HOME}/.config/rustup" ]]; then
    mkdir -p "$_rustup_home"
    cp -a -n "${HOME}/.config/rustup/." "$_rustup_home/"
    rm -rf "${HOME}/.config/rustup"
    log_ok "Moved Rustup data to $_rustup_home"
fi
export RUSTUP_HOME="$_rustup_home"

log_info "Python virtual environment..."
_venv_dir="${HOME}/.local/share/venv"
if [[ -d "$_venv_dir" ]]; then
    log_ok "Python venv already exists at $_venv_dir"
else
    if check_command uv; then
        uv venv --system-site-packages "$_venv_dir"
        log_ok "Python venv created at $_venv_dir"
        _requirements="${HOME}/.config/pip-backup/packages.in"
        if [[ -f "$_requirements" ]]; then
            uv pip install -r "$_requirements" --python "${_venv_dir}/bin/python" || \
                log_warn "Some pip packages failed to install from requirements.in"
        fi
    else
        log_warn "uv not found, skipping venv creation"
    fi
fi

log_info "Sioyek dictionary extension..."
_sioyek_ext="${HOME}/.config/sioyek/extensions/sioyek-dict"
if [[ -d "$_sioyek_ext" ]] && [[ -f "${_sioyek_ext}/Makefile" ]]; then
    (cd "$_sioyek_ext" && PATH="${_venv_dir}/bin:${PATH}" make install)
    log_ok "Sioyek dict extension installed"
else
    log_warn "Sioyek dict extension not found, skipping"
fi

log_info "Neovim Python provider..."
if "${_venv_dir}/bin/python" -c "import pynvim" &>/dev/null; then
    log_ok "pynvim already installed"
else
    uv pip install --python "${_venv_dir}/bin/python" --upgrade pynvim || \
        log_warn "Failed to install pynvim"
fi

log_info "Firefox extensions..."
_firefox_extension_installer="${HOME}/.config/scripts/firefox-install-extensions.sh"
_xdg_firefox_profiles="${XDG_CONFIG_HOME:-${HOME}/.config}/mozilla/firefox/profiles.ini"
_legacy_firefox_profiles="${HOME}/.mozilla/firefox/profiles.ini"
if [[ ! -x "$_firefox_extension_installer" ]]; then
    log_warn "Firefox extension installer not found"
elif [[ -f "$_xdg_firefox_profiles" || -f "$_legacy_firefox_profiles" ]]; then
    if "$_firefox_extension_installer"; then
        log_ok "Firefox extensions restored"
    else
        log_warn "Some Firefox extensions failed to restore"
        REMINDERS+=("Rerun ~/.config/scripts/firefox-install-extensions.sh after closing Firefox")
    fi
else
    log_warn "Firefox profile not initialized; extension restore deferred"
    REMINDERS+=("Launch Firefox once, close it, then run ~/.config/scripts/firefox-install-extensions.sh")
fi

unset _cargo_home _legacy_cargo_home _rustup_home _firefox_extension_installer
unset _xdg_firefox_profiles _legacy_firefox_profiles
