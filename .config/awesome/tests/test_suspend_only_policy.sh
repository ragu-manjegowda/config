#!/usr/bin/env bash

set -euo pipefail

root="${HOME}"
logind="$root/.config/misc/etc/systemd/logind.conf.d/90-local.conf"
sleep_config="$root/.config/misc/etc/systemd/sleep.conf.d/90-disable-hibernation.conf"
polkit="$root/.config/misc/etc/polkit-1/rules.d/00-early-checks.rules"
exit_screen="$root/.config/awesome/module/exit-screen.lua"
battery="$root/.config/awesome/widget/battery/init.lua"
bootstrap_system="$root/.config/scripts/bootstrap/03-system.sh"
bootstrap_hardware="$root/.config/scripts/bootstrap/04-hardware.sh"
refind="$root/.config/rEFInd/refind.conf"

assert_contains() {
    grep -Fq -- "$2" "$1" || {
        printf 'Missing %s in %s\n' "$2" "$1" >&2
        exit 1
    }
}

assert_absent() {
    if grep -Fq -- "$2" "$1"; then
        printf 'Unexpected %s in %s\n' "$2" "$1" >&2
        exit 1
    fi
}

assert_contains "$logind" 'SleepOperation=suspend'
assert_contains "$logind" 'HandlePowerKey=ignore'
assert_absent "$logind" 'HandlePowerKeyLongPress='
assert_contains "$logind" 'HandleLidSwitch=suspend'
assert_absent "$logind" 'suspend-then-hibernate'
assert_absent "$logind" 'SleepOperation=suspend hibernate'

assert_contains "$sleep_config" 'AllowHibernation=no'
assert_contains "$sleep_config" 'AllowSuspendThenHibernate=no'
assert_contains "$sleep_config" 'AllowHybridSleep=no'
test ! -e "$root/.config/misc/etc/systemd/sleep.conf.d/hibernatemode.conf"
test ! -e "$root/.config/misc/etc/mkinitcpio.conf.d/90-resume.conf"

assert_absent "$exit_screen" 'hibernate'
assert_absent "$battery" 'hibernate'
assert_absent "$polkit" 'hibernate'
assert_absent "$polkit" 'hybrid-sleep'
assert_contains "$bootstrap_system" "sudo rm -f \"\$_mkinitcpio_dropin\""
assert_contains "$bootstrap_hardware" '90-disable-hibernation.conf'
assert_contains "$bootstrap_hardware" 'rm -f /etc/systemd/sleep.conf.d/hibernatemode.conf'
assert_contains "$bootstrap_hardware" 'systemd-hibernate.service'
assert_contains "$bootstrap_hardware" 'systemd-suspend-then-hibernate.service'
assert_contains "$bootstrap_hardware" 'systemd-hybrid-sleep.service'
assert_absent "$bootstrap_hardware" 'filefrag'
assert_absent "$bootstrap_hardware" 'fallocate'
assert_absent "$refind" 'resume='
assert_absent "$refind" 'resume_offset='
test "$(grep -c 'options.* nohibernate ' "$refind")" -eq 4

printf 'suspend-only policy tests passed\n'
