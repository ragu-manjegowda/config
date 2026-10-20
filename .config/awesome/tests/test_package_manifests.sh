#!/usr/bin/env bash

set -euo pipefail

for tool in cmp diff; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'missing package-manifest test dependency: %s (install diffutils)\n' "$tool" >&2
        exit 1
    fi
done

manifest_dir="${HOME}/.config/archiso-backup"
minimal="$manifest_dir/pkglistMinimal.txt"
official="$manifest_dir/pkglistPacmanInstalled.txt"
foreign="$manifest_dir/foreignpkglist.txt"
all="$manifest_dir/pkglistAll.txt"
temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT

for manifest in "$minimal" "$official" "$foreign" "$all"; do
    if [[ ! -s "$manifest" ]]; then
        printf 'package manifest is missing or empty: %s\n' "$manifest" >&2
        exit 1
    fi
    if ! LC_ALL=C sort -cu "$manifest"; then
        printf 'package manifest must be sorted and unique: %s\n' "$manifest" >&2
        exit 1
    fi
    if grep -Eq '^[[:space:]]*$|[[:space:]]' "$manifest"; then
        printf 'invalid package entry in %s\n' "$manifest" >&2
        exit 1
    fi
done

for package in feh tailscale; do
    for manifest in "$minimal" "$official" "$all"; do
        if ! grep -Fxq "$package" "$manifest"; then
            printf 'required package %s is missing from %s\n' "$package" "$manifest" >&2
            exit 1
        fi
    done
done
if grep -Fxq 'ntp' "$official" || grep -Fxq 'ntp' "$all" ||
        grep -Fxq 'broadcom-wl-dkms' "$official" || grep -Fxq 'broadcom-wl-dkms' "$all"; then
    printf 'obsolete packages remain in generated manifests\n' >&2
    exit 1
fi

LC_ALL=C sort -u "$official" "$foreign" > "$temp/union"
if ! cmp -s "$temp/union" "$all"; then
    printf 'combined package manifest does not match the official/foreign union: %s\n' "$all" >&2
    diff -u "$temp/union" "$all" >&2 || true
    exit 1
fi

printf 'package manifest tests passed\n'
