#!/usr/bin/env bash

set -euo pipefail

plugin="${HOME}/.config/zsh/zsh-custom/plugins/custom-alias/shared-dirstack.zsh"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
test_home="$test_root/home"
cache="$test_root/cache"
mkdir -p "$test_home" "$cache/zsh"

for index in $(seq 1 20); do
    mkdir -p "$test_root/dir-$index"
done

run_writer() {
    HOME="$test_home" XDG_CACHE_HOME="$cache" zsh -f -c '
        compdef() { :; }
        source "$1"
        builtin cd -q -- "$2"
        chpwd_dirpersist
    ' zsh "$plugin" "$1"
}

for index in $(seq 1 8); do
    run_writer "$test_root/dir-$index"
done
run_writer "$test_root/dir-9" &
run_writer "$test_root/dir-10" &
wait

stack="$cache/zsh/dirs"
test "$(wc -l < "$stack")" -eq 10
test "$(LC_ALL=C sort -u "$stack" | wc -l)" -eq 10
grep -Fxq "$test_root/dir-9" "$stack"
grep -Fxq "$test_root/dir-10" "$stack"

for index in $(seq 11 20); do
    run_writer "$test_root/dir-$index"
done
run_writer "$test_root/dir-20"
test "$(wc -l < "$stack")" -eq 10
test "$(LC_ALL=C sort -u "$stack" | wc -l)" -eq 10
while IFS= read -r dir; do test -d "$dir"; done < "$stack"
if compgen -G "$stack.tmp.*" > /dev/null; then
    printf 'temporary dirstack files were not cleaned up\n' >&2
    exit 1
fi

mkdir -p "$test_root/shared-update"
HOME="$test_home" XDG_CACHE_HOME="$cache" PLUGIN="$plugin" SHARED="$test_root/shared-update" \
    zsh -f -c '
        compdef() { :; }
        source "$PLUGIN"
        HOME="$HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" zsh -f -c '\''
            compdef() { :; }
            source "$1"
            builtin cd -q -- "$2"
            chpwd_dirpersist
        '\'' zsh "$PLUGIN" "$SHARED"
        d | grep -Fq -- "$SHARED"
    '

printf 'zsh shared dirstack tests passed\n'
