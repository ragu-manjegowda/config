#!/usr/bin/env bash
# 02-01-firejail.sh - Firejail sandboxing for high-risk applications
#
# Sourced by 02-security.sh after AppArmor is set up. Firejail layers
# namespace isolation + seccomp on top of the existing AppArmor MAC.
#
# Currently sandboxes:
#   * firefox (Mozilla's browser, Gecko)
#     Uses upstream /etc/firejail/firefox.profile. Local overrides in
#     firefox.local expose /dev/hidraw* and /run/pcscd for YubiKey.
#   * prisma-access-browser-stable (AUR: prisma-access-browser-bin)
#     Palo Alto Networks' Chromium-based enterprise browser. Custom
#     profile inheriting chromium-common, whitelists the spaced
#     "Palo Alto Networks" vendor directory.
#
# Enforcement mechanism: surgical firecfg-style symlink
#   /usr/local/bin/<app> -> /usr/bin/firejail
# /usr/local/bin precedes /usr/bin in PATH, so the shell resolves the
# app name to firejail, which reads argv[0] and loads the matching
# /etc/firejail/<app>.profile. Desktop files in ~/.local/share/applications
# are also rewritten so GUI launches go through firejail too.
#
# Entry schema for _fj_apps:
#   "binary_name:desktop1,desktop2[:exec_path_regex]"
# exec_path_regex defaults to "/usr/bin/<binary_name>" but some packages
# (e.g. firefox) ship desktop files that call the real binary directly
# bypassing /usr/bin, so an override pattern is needed to match the Exec= line.

log_info "Firejail sandboxing..."
require_package firejail

# pcscd is the PC/SC smart-card daemon used by YubiKey PIN entry, PIV, and
# other smart-card flows in sandboxed browsers. The sandbox exposes its
# socket (/run/pcscd) via each app's .local override; the daemon itself
# must be running on the host.
require_package pcsclite ccid
enable_system_service pcscd.socket

# ---------------------------------------------------------------------------
# Deploy profiles from ~/.config/misc/etc/firejail/ to /etc/firejail/
# ---------------------------------------------------------------------------
_fj_src_dir="${MISC_DIR}/etc/firejail"
if [[ -d "$_fj_src_dir" ]]; then
    check_copy_dir "$_fj_src_dir" /etc/firejail
else
    log_warn "No firejail profile directory at $_fj_src_dir (skipping profile deploy)"
fi

# ---------------------------------------------------------------------------
# Per-application enforcement
# ---------------------------------------------------------------------------
# Define sandboxed apps as "binary_name:desktop_file1,desktop_file2"
# Binary must exist at /usr/bin/<binary_name> and a matching profile must
# exist at /etc/firejail/<binary_name>.profile.
_fj_apps=(
    "prisma-access-browser-stable:prisma-access-browser.desktop,com.paloaltonetworks.PrismaAccessBrowser.desktop"
)

for entry in "${_fj_apps[@]}"; do
    _bin="${entry%%:*}"
    _desktops_csv="${entry#*:}"

    # Skip if binary isn't installed (app may be optional)
    if [[ ! -x "/usr/bin/${_bin}" ]]; then
        log_warn "Firejail: /usr/bin/${_bin} not installed, skipping"
        continue
    fi

    # Skip if no profile exists
    if [[ ! -f "/etc/firejail/${_bin}.profile" ]]; then
        log_fail "Firejail: /etc/firejail/${_bin}.profile missing (no profile to enforce)"
        continue
    fi

    # 1. System-wide: /usr/local/bin/<bin> -> /usr/bin/firejail
    check_symlink /usr/bin/firejail "/usr/local/bin/${_bin}" sudo

    # 2. Per-user desktop file overrides: copy from /usr/share/applications
    #    to ~/.local/share/applications and prepend `firejail ` to every Exec=
    mkdir -p "${HOME}/.local/share/applications"
    IFS=',' read -r -a _desktops <<<"$_desktops_csv"
    for _desktop in "${_desktops[@]}"; do
        _src="/usr/share/applications/${_desktop}"
        _dest="${HOME}/.local/share/applications/${_desktop}"

        if [[ ! -f "$_src" ]]; then
            log_warn "Firejail: desktop source ${_src} missing, skipping override"
            continue
        fi

        # Generate firejail-wrapped version. Match only Exec= lines that
        # start with the absolute binary path; leave anything already
        # wrapped alone.
        _tmp="$(mktemp)"
        sed -E "s|^Exec=/usr/bin/${_bin}(.*)$|Exec=firejail /usr/bin/${_bin}\1|" \
            "$_src" > "$_tmp"

        if [[ -f "$_dest" ]] && diff -q "$_tmp" "$_dest" &>/dev/null; then
            log_ok "Firejail desktop override already up to date: $_dest"
        else
            mv "$_tmp" "$_dest"
            log_ok "Firejail desktop override written: $_dest"
        fi
        rm -f "$_tmp"
    done
done

# ---------------------------------------------------------------------------
# Refresh the desktop database so the new entries are picked up
# ---------------------------------------------------------------------------
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null \
        && log_ok "Refreshed user desktop database"
fi

unset _fj_src_dir _fj_apps entry _bin _desktops_csv _desktops _desktop _src _dest _tmp
