#!/bin/bash

set -euo pipefail

APP_NAMES=(Click Zim)

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_root="${script_dir}/.build"
machine="$(uname -m)"

[ "$(uname -s)" = "Darwin" ] || die 'this installer must be run on macOS'

case "${machine}" in
    arm64|x86_64)
        arch="${machine}"
        ;;
    *)
        die "unsupported Mac architecture: ${machine}"
        ;;
esac

require_command clang
require_command ditto
require_command plutil
require_command sudo

printf 'Detected macOS architecture: %s\n' "${arch}"
printf 'Building app wrappers for: %s\n' "${arch}"

rm -rf "${build_root}"
mkdir -p "${build_root}"

for app_name in "${APP_NAMES[@]}"; do
    app="${app_name}.app"
    source_app="${script_dir}/${app}"
    staged_app="${build_root}/${app}"
    source_file="${source_app}/Contents/Resources/${app_name}.m"
    executable="${staged_app}/Contents/MacOS/${app_name}"

    [ -d "${source_app}" ] || die "missing app bundle: ${source_app}"
    [ -f "${source_file}" ] || die "missing wrapper source: ${source_file}"

    printf '\nStaging %s\n' "${app}"
    ditto "${source_app}" "${staged_app}"

    printf 'Validating %s Info.plist\n' "${app}"
    plutil -lint "${staged_app}/Contents/Info.plist"

    printf 'Compiling %s\n' "${app}"
    mkdir -p "$(dirname "${executable}")"
    clang -fobjc-arc -framework Cocoa -arch "${arch}" -o "${executable}" "${source_file}"
    chmod 755 "${executable}"

    printf 'Removing existing /Applications/%s\n' "${app}"
    sudo rm -rf "/Applications/${app}"

    printf 'Installing %s to /Applications\n' "${app}"
    sudo ditto "${staged_app}" "/Applications/${app}"
done

printf '\nInstalled: %s\n' "${APP_NAMES[*]}"
