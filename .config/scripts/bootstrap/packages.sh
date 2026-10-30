#!/usr/bin/env bash
# Package restore helpers, shared with the regression tests.

load_package_manifests() {
    local repo="$1" destination="$2" profile="$3" name package
    case "$profile" in
        full|minimal) ;;
        *) log_fail "Unknown package profile: $profile"; return 1 ;;
    esac
    for name in pkglistPacmanInstalled.txt foreignpkglist.txt pkglistAll.txt; do
        if ! git --git-dir="$repo" show "HEAD:.config/archiso-backup/$name" > "$destination/$name"; then
            log_fail "Unable to read committed manifest: $name"
            return 1
        fi
        if [[ ! -s "$destination/$name" ]] ||
           grep -qEv '^[[:alnum:]@._+-]+$' "$destination/$name"; then
            log_fail "Invalid or empty committed manifest: $name"
            return 1
        fi
        LC_ALL=C sort -u -o "$destination/$name" "$destination/$name"
    done
    LC_ALL=C sort -u "$destination/pkglistPacmanInstalled.txt" "$destination/foreignpkglist.txt" > "$destination/union.txt"
    if ! cmp -s "$destination/union.txt" "$destination/pkglistAll.txt"; then
        log_fail "Committed full package manifests disagree with pkglistAll.txt"
        return 1
    fi
    if [[ "$profile" == minimal ]]; then
        name=pkglistMinimal.txt
        if ! git --git-dir="$repo" show "HEAD:.config/archiso-backup/$name" > "$destination/$name" ||
           [[ ! -s "$destination/$name" ]] ||
           grep -qEv '^[[:alnum:]@._+-]+$' "$destination/$name"; then
            log_fail "Invalid or missing committed minimal manifest"
            return 1
        fi
        LC_ALL=C sort -u -o "$destination/$name" "$destination/$name"
        # Keep the committed foreign classification. For minimal-only additions,
        # consult sync metadata rather than assuming every new name is official.
        LC_ALL=C comm -23 "$destination/$name" "$destination/foreignpkglist.txt" > "$destination/minimal-candidates.txt"
        LC_ALL=C comm -12 "$destination/$name" "$destination/foreignpkglist.txt" > "$destination/minimal-foreign.txt"
        : > "$destination/pkglistPacmanInstalled.txt"
        while IFS= read -r package; do
            if grep -Fxq "$package" "$destination/union.txt" || pacman -Si "$package" &>/dev/null; then
                printf '%s\n' "$package" >> "$destination/pkglistPacmanInstalled.txt"
            else
                printf '%s\n' "$package" >> "$destination/minimal-foreign.txt"
            fi
        done < "$destination/minimal-candidates.txt"
        LC_ALL=C sort -u -o "$destination/minimal-foreign.txt" "$destination/minimal-foreign.txt"
        mv "$destination/minimal-foreign.txt" "$destination/foreignpkglist.txt"
        cp "$destination/$name" "$destination/pkglistAll.txt"
    fi
}

arch_package_command() {
    # Homebrew shellenv must not decide which headers/libraries an Arch package
    # links against. Keep Brew-only tools available after the system tools.
    local argument
    local -a build_env=(
        "PATH=/usr/bin:/bin:${PATH}"
        'PKG_CONFIG=/usr/bin/pkg-config'
        'PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig'
        'PKG_CONFIG_LIBDIR=/usr/lib/pkgconfig:/usr/share/pkgconfig'
    )
    # Restore installs AUR packages one at a time. Scope this recipe-specific
    # switch to the Awesome invocation, not every makepkg/paru process.
    for argument in "$@"; do
        if [[ "$argument" == awesome-luajit-git ]]; then
            build_env+=("_BUILD_DOCS=${_BUILD_DOCS:-0}")
            break
        fi
    done
    env "${build_env[@]}" "$@"
}

verify_package_restore() {
    local desired="$1" directory="$2" package
    local -a dependencies
    mapfile -t dependencies < "$desired"
    if pacman -T "${dependencies[@]}" > "$directory/missing.txt"; then
        return 0
    fi
    if [[ -s "$directory/missing.txt" ]]; then
        log_fail "Selected package profile is incomplete; missing packages:"
        while IFS= read -r package; do log_fail "  $package"; done < "$directory/missing.txt"
        return 1
    fi
    log_fail "Unable to query installed package dependencies"
    return 1
}

resolve_package_selection() {
    local desired="$1" output="$2"
    local -a dependencies
    mapfile -t dependencies < "$desired"
    if ! pacman -Qq "${dependencies[@]}" > "$output"; then
        log_fail "Unable to resolve selected packages/providers; refusing to prune"
        return 1
    fi
    LC_ALL=C sort -u -o "$output" "$output"
}

dotfiles_are_unlocked() {
    local repo="$1"
    [[ -s "$repo/git-crypt/keys/default" ]] &&
        git --git-dir="$repo" config --local --get filter.git-crypt.smudge >/dev/null
}
