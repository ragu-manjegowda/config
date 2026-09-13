#!/usr/bin/env bash

set -euo pipefail

manifest_dir="${HOME}/.config/archiso-backup"
minimal="$manifest_dir/pkglistMinimal.txt"
official="$manifest_dir/pkglistPacmanInstalled.txt"
foreign="$manifest_dir/foreignpkglist.txt"
all="$manifest_dir/pkglistAll.txt"
temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT

for manifest in "$minimal" "$official" "$foreign" "$all"; do
    LC_ALL=C sort -cu "$manifest"
    test -s "$manifest"
    if grep -Eq '^[[:space:]]*$|[[:space:]]' "$manifest"; then
        printf 'invalid package entry in %s\n' "$manifest" >&2
        exit 1
    fi
done

test "$(wc -l < "$minimal")" -eq 142
grep -Fxq 'ipu-bridge-legacy-cvs-dkms' "$foreign"
grep -Fxq 'ipu-bridge-legacy-cvs-dkms' "$all"
if grep -Fxq 'ntp' "$official" || grep -Fxq 'ntp' "$all" ||
        grep -Fxq 'broadcom-wl-dkms' "$official" || grep -Fxq 'broadcom-wl-dkms' "$all"; then
    printf 'obsolete packages remain in generated manifests\n' >&2
    exit 1
fi

LC_ALL=C sort -u "$official" "$foreign" > "$temp/union"

printf 'package manifest tests passed\n'
