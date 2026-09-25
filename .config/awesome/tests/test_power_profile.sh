#!/usr/bin/env bash

set -euo pipefail

repo_home="${HOME}"
helper="$repo_home/.config/awesome/utilities/power-profile"
consumers="$repo_home/.config/awesome/utilities/battery-power-consumers"
policy="$repo_home/.config/misc/usr/local/libexec/awesome-power-profile-policy"
widget="$repo_home/.config/awesome/widget/power-profile/init.lua"
panel="$repo_home/.config/awesome/layout/control-center/init.lua"
service="$repo_home/.config/systemd/user/power-profile-monitor.service"
bootstrap="$repo_home/.config/scripts/bootstrap/05-services.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

state="$tmp_dir/profile"
log="$tmp_dir/commands"
epp_dir="$tmp_dir/cpufreq"
platform_profile="$tmp_dir/platform_profile"
no_turbo="$tmp_dir/no_turbo"
bluetooth_state="$tmp_dir/bluetooth-state"
printf 'balanced\n' > "$state"
mkdir -p "$epp_dir/policy0" "$epp_dir/policy1"
printf 'balance_performance\n' > "$epp_dir/policy0/energy_performance_preference"
printf 'balance_performance\n' > "$epp_dir/policy1/energy_performance_preference"
printf 'balanced\n' > "$platform_profile"
printf '0\n' > "$no_turbo"
printf 'no\n' > "$bluetooth_state"

cat > "$tmp_dir/powerprofilesctl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    get) cat "$POWER_PROFILE_STATE_FILE" ;;
    set)
        [[ "${POWER_PROFILE_POLKIT_ALLOWED:-}" == 1 ]] || {
            printf 'Not Authorized: switch-profile\n' >&2
            exit 1
        }
        [[ "${POWER_PROFILE_TEST_FAIL_DAEMON:-}" != 1 ]] || exit 1
        printf '%s\n' "$2" > "$POWER_PROFILE_STATE_FILE"
        case "$2" in
            performance) epp=performance; platform=performance ;;
            balanced) epp=balance_performance; platform=balanced ;;
            power-saver) epp=power; platform=balanced ;;
        esac
        for policy in "$POWER_PROFILE_EPP_DIR"/policy*/energy_performance_preference; do
            printf '%s\n' "$epp" > "$policy"
        done
        printf '%s\n' "$platform" > "$POWER_PROFILE_PLATFORM_PROFILE"
        ;;
    *) exit 2 ;;
esac
EOF
cat > "$tmp_dir/light" <<'EOF'
#!/usr/bin/env bash
printf 'light %s\n' "$*" >> "$POWER_PROFILE_COMMAND_LOG"
if [[ "$1" == -G ]]; then printf '42.0\n'; fi
EOF
cat > "$tmp_dir/rfkill" <<'EOF'
#!/usr/bin/env bash
printf 'rfkill %s\n' "$*" >> "$POWER_PROFILE_COMMAND_LOG"
EOF
cat > "$tmp_dir/bluetoothctl" <<'EOF'
#!/usr/bin/env bash
printf 'bluetoothctl %s\n' "$*" >> "$POWER_PROFILE_COMMAND_LOG"
case "$1" in
    show) printf 'Controller 00:00:00:00:00:00\n\tPowered: %s\n' "$(<"$POWER_PROFILE_BLUETOOTH_STATE_FILE")" ;;
    power)
        case "$2" in
            on) printf 'yes\n' > "$POWER_PROFILE_BLUETOOTH_STATE_FILE" ;;
            off) printf 'no\n' > "$POWER_PROFILE_BLUETOOTH_STATE_FILE" ;;
        esac
        ;;
esac
EOF
cat > "$tmp_dir/nvidia-smi" <<'EOF'
#!/usr/bin/env bash
printf '7.5, P4\n'
EOF
cat > "$tmp_dir/ps" <<'EOF'
#!/usr/bin/env bash
printf '101 1 browser 4.8\n102 1 browser 2.2\n103 1 mail-client 1.2\n104 1 ps 200.0\n'
EOF
cat > "$tmp_dir/systemctl" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == start && "$2" =~ ^awesome-power-profile-policy@(performance|balanced|power-saver)\.service$ ]] || exit 2
[[ "${POWER_PROFILE_TEST_FAIL_TURBO:-}" != "${BASH_REMATCH[1]}" ]] || exit 1
exec /bin/bash "$POWER_PROFILE_POLICY_BIN" "${BASH_REMATCH[1]}"
EOF
chmod +x "$tmp_dir/powerprofilesctl" "$tmp_dir/light" "$tmp_dir/rfkill" \
    "$tmp_dir/bluetoothctl" "$tmp_dir/nvidia-smi" "$tmp_dir/ps" "$tmp_dir/systemctl"

run_helper() {
    POWER_PROFILE_CTL="$tmp_dir/powerprofilesctl" \
        POWER_PROFILE_LIGHT_BIN="$tmp_dir/light" \
        POWER_PROFILE_RFKILL_BIN="$tmp_dir/rfkill" \
        POWER_PROFILE_BLUETOOTHCTL_BIN="$tmp_dir/bluetoothctl" \
        POWER_PROFILE_STATE_FILE="$state" \
        POWER_PROFILE_COMMAND_LOG="$log" \
        POWER_PROFILE_BLUETOOTH_STATE_FILE="$bluetooth_state" \
        POWER_PROFILE_POLICY_BIN="$policy" \
        POWER_PROFILE_SYSTEMCTL_BIN="$tmp_dir/systemctl" \
        POWER_PROFILE_POLKIT_ALLOWED="${POWER_PROFILE_POLKIT_ALLOWED_OVERRIDE:-1}" \
        POWER_PROFILE_EPP_DIR="$epp_dir" \
        POWER_PROFILE_PLATFORM_PROFILE="$platform_profile" \
        POWER_PROFILE_NO_TURBO="$no_turbo" \
        XDG_STATE_HOME="$tmp_dir/state" \
        POWER_PROFILE_ON_BATTERY="$1" \
        bash "$helper" "${@:2}"
}

[[ "$(run_helper false default)" == performance ]]
grep -Fxq 'light -S 100' "$log"
! grep -Fq 'bluetoothctl power ' "$log"
[[ "$(<"$bluetooth_state")" == no ]]

: > "$log"
[[ "$(run_helper true default)" == balanced ]]
grep -Fxq 'light -S 60' "$log"
! grep -Fq 'bluetoothctl power ' "$log"
[[ "$(<"$bluetooth_state")" == no ]]

: > "$log"
[[ "$(run_helper true set power-saver)" == power-saver ]]
[[ "$(cat "$state")" == balanced ]]
[[ "$(run_helper true get)" == power-saver ]]
[[ "$(<"$tmp_dir/state/awesome/power-profile-bluetooth")" == no ]]
grep -Fxq 'light -S 35' "$log"
grep -Fxq 'bluetoothctl power off' "$log"
[[ "$(cat "$epp_dir/policy0/energy_performance_preference")" == power ]]
[[ "$(cat "$platform_profile")" == balanced ]]
[[ "$(cat "$no_turbo")" == 1 ]]

[[ "$(run_helper true default)" == balanced ]]
[[ "$(cat "$state")" == balanced ]]
[[ "$(<"$bluetooth_state")" == no ]]
[[ ! -e "$tmp_dir/state/awesome/power-profile-bluetooth" ]]
[[ "$(cat "$epp_dir/policy0/energy_performance_preference")" == balance_performance ]]
[[ "$(cat "$no_turbo")" == 0 ]]
[[ "$(run_helper true set power-saver)" == power-saver ]]

[[ "$(run_helper true cycle)" == performance ]]
[[ "$(cat "$state")" == performance ]]
[[ "$(<"$bluetooth_state")" == no ]]
[[ "$(cat "$epp_dir/policy1/energy_performance_preference")" == performance ]]
[[ "$(cat "$no_turbo")" == 0 ]]

# A previously enabled controller is turned off only in Power Saver, then
# restored on exit. Reapplying Power Saver must not overwrite its saved state.
printf 'yes\n' > "$bluetooth_state"
[[ "$(run_helper true set power-saver)" == power-saver ]]
[[ "$(<"$tmp_dir/state/awesome/power-profile-bluetooth")" == yes ]]
[[ "$(<"$bluetooth_state")" == no ]]
[[ "$(run_helper true set power-saver)" == power-saver ]]
[[ "$(<"$tmp_dir/state/awesome/power-profile-bluetooth")" == yes ]]
[[ "$(run_helper false default)" == performance ]]
[[ "$(<"$bluetooth_state")" == yes ]]
[[ ! -e "$tmp_dir/state/awesome/power-profile-bluetooth" ]]

if POWER_PROFILE_TEST_FAIL_TURBO=power-saver run_helper true set power-saver >/dev/null 2>&1; then
    printf 'Failed Power Saver entry was reported as successful\n' >&2
    exit 1
fi
[[ "$(<"$bluetooth_state")" == yes ]]
[[ ! -e "$tmp_dir/state/awesome/power-profile-bluetooth" ]]

# A manual Bluetooth-off choice remains off across normal profiles.
printf 'no\n' > "$bluetooth_state"
: > "$log"
[[ "$(run_helper true set balanced)" == balanced ]]
[[ "$(run_helper false set performance)" == performance ]]
[[ "$(<"$bluetooth_state")" == no ]]
! grep -Fq 'bluetoothctl power ' "$log"

: > "$log"
if POWER_PROFILE_TEST_FAIL_TURBO=balanced run_helper true set balanced >/dev/null 2>&1; then
    printf 'Turbo failure was reported as a successful transition\n' >&2
    exit 1
fi
[[ "$(cat "$state")" == performance ]]
[[ ! -s "$log" ]]

printf 'yes\n' > "$bluetooth_state"
[[ "$(run_helper true set power-saver)" == power-saver ]]
if POWER_PROFILE_TEST_FAIL_TURBO=balanced run_helper true set balanced >/dev/null 2>&1; then
    printf 'Failed transition out of Power Saver was reported as successful\n' >&2
    exit 1
fi
[[ "$(run_helper true get)" == power-saver ]]
[[ "$(<"$tmp_dir/state/awesome/power-profile-bluetooth")" == yes ]]
[[ "$(cat "$epp_dir/policy0/energy_performance_preference")" == power ]]
[[ "$(cat "$no_turbo")" == 1 ]]
[[ "$(run_helper true set performance)" == performance ]]
[[ "$(<"$bluetooth_state")" == yes ]]

if POWER_PROFILE_POLKIT_ALLOWED_OVERRIDE=0 run_helper true set balanced >/dev/null 2>&1; then
    printf 'Unauthorized daemon switch was reported as successful\n' >&2
    exit 1
fi
[[ "$(cat "$state")" == performance ]]

if POWER_PROFILE_TEST_FAIL_DAEMON=1 run_helper true set balanced >/dev/null 2>&1; then
    printf 'Daemon failure was reported as a successful transition\n' >&2
    exit 1
fi
[[ "$(cat "$state")" == performance ]]

runtime_status="$tmp_dir/runtime_status"
printf 'suspended\n' > "$runtime_status"
snapshot="$(BATTERY_PROFILE_HELPER="$helper" \
    BATTERY_LIGHT_BIN="$tmp_dir/light" \
    BATTERY_NVIDIA_SMI="$tmp_dir/nvidia-smi" \
    BATTERY_PS_BIN="$tmp_dir/ps" \
    BATTERY_NVIDIA_RUNTIME_STATUS="$runtime_status" \
    POWER_PROFILE_CTL="$tmp_dir/powerprofilesctl" \
    POWER_PROFILE_STATE_FILE="$state" \
    bash "$consumers")"
grep -Fq '     Profile: performance · Brightness: 42%' <<< "$snapshot"
grep -Fq '      NVIDIA: suspended' <<< "$snapshot"
grep -Fq 'CPU activity: browser 7%, mail-client 1%' <<< "$snapshot"
if grep -Fq 'ps 200%' <<< "$snapshot"; then
    printf 'CPU sampler included its own ps process\n' >&2
    exit 1
fi

printf 'active\n' > "$runtime_status"
snapshot="$(BATTERY_PROFILE_HELPER="$helper" \
    BATTERY_LIGHT_BIN="$tmp_dir/light" \
    BATTERY_NVIDIA_SMI="$tmp_dir/nvidia-smi" \
    BATTERY_PS_BIN="$tmp_dir/ps" \
    BATTERY_NVIDIA_RUNTIME_STATUS="$runtime_status" \
    POWER_PROFILE_CTL="$tmp_dir/powerprofilesctl" \
    POWER_PROFILE_STATE_FILE="$state" \
    bash "$consumers")"
grep -Fq '      NVIDIA: 7.5 W · P4' <<< "$snapshot"

printf 'power-saver\n' > "$tmp_dir/state/awesome/power-profile"
printf 'balanced\n' > "$state"
printf 'balance_performance\n' > "$epp_dir/policy0/energy_performance_preference"
[[ "$(run_helper true get)" == balanced ]] || {
    printf 'Stale Power Saver state hid the real CPU policy\n' >&2
    exit 1
}

grep -Fq "local function select_profile(profile)" "$widget"
grep -Fq "key = 'performance'," "$widget"
grep -Fq "color = beautiful.system_green_light," "$widget"
grep -Fq "key = 'balanced'," "$widget"
grep -Fq "color = beautiful.system_yellow_light," "$widget"
grep -Fq "key = 'power-saver'," "$widget"
grep -Fq "color = beautiful.system_red_light," "$widget"
grep -Fq "tooltip = '100% brightness · keep Bluetooth state · CPU performance · turbo on'" "$widget"
grep -Fq "tooltip = '60% brightness · keep Bluetooth state · balanced CPU policy'" "$widget"
grep -Fq "tooltip = '35% brightness · Bluetooth off · CPU power policy · turbo off'" "$widget"
grep -Fq 'awful.tooltip {' "$widget"
grep -Fq 'button.bg = selected and beautiful.accent or beautiful.background' "$widget"
grep -Fq 'button.label:set_markup' "$widget"
grep -Fq 'forced_width = dpi(118)' "$widget"
grep -Fq 'forced_height = dpi(40)' "$widget"
grep -Fq "require('widget.power-profile')" "$panel"
grep -Fq "main_control_row_sliders" "$panel"
grep -Fq 'ExecStart=/usr/bin/python3 %h/.config/awesome/utilities/power-profile-monitor' "$service"
grep -Fq 'configure-battery-aware", "--disable' "$repo_home/.config/awesome/utilities/power-profile-monitor"
grep -Fq "awesome.emit_signal('module::power_profile', '{profile}')" \
    "$repo_home/.config/awesome/utilities/power-profile-monitor"
grep -Fq 'enable_system_service power-profiles-daemon' "$bootstrap"
grep -Fq 'reenable power-profile-monitor.service' "$bootstrap"
grep -Fq 'start power-profile-monitor.service' "$bootstrap"
polkit_rule="$repo_home/.config/misc/etc/polkit-1/rules.d/50-awesome-power-profile.rules"
unit="$repo_home/.config/misc/etc/systemd/system/awesome-power-profile-policy@.service"
grep -Fq 'org.freedesktop.UPower.PowerProfiles.switch-profile' "$polkit_rule"
grep -Fq 'org.freedesktop.UPower.PowerProfiles.configure-battery-aware' "$polkit_rule"
grep -Fq 'org.freedesktop.systemd1.manage-units' "$polkit_rule"
grep -Fq 'subject.isInGroup("wheel")' "$polkit_rule"
grep -Fq 'action.lookup("verb") == "start"' "$polkit_rule"
for profile in performance balanced power-saver; do
    grep -Fq "awesome-power-profile-policy@${profile}.service" "$polkit_rule"
done
grep -Fxq 'ExecStart=/usr/local/libexec/awesome-power-profile-policy %i' "$unit"
grep -Fxq 'WantedBy=default.target' "$service"
if grep -Fq 'graphical-session.target' "$service"; then
    printf 'Power profile monitor depends on an inactive target\n' >&2
    exit 1
fi
if grep -Fq 'platform_profile' "$policy"; then
    printf 'CPU policy duplicates power-profiles-daemon platform settings\n' >&2
    exit 1
fi
if grep -Fq 'sudo' "$helper" || grep -Fq 'powerprofilesctl' "$policy"; then
    printf 'Power utility must not use sudo or switch daemon profiles as root\n' >&2
    exit 1
fi
grep -Fq '50-awesome-power-profile.rules' "$repo_home/.config/scripts/bootstrap/03-system.sh"
grep -Fq 'awesome-power-profile-policy@.service' "$repo_home/.config/scripts/bootstrap/03-system.sh"

printf 'power profile tests passed\n'
