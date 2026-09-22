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
platform_choices="$tmp_dir/platform_choices"
no_turbo="$tmp_dir/no_turbo"
printf 'balanced\n' > "$state"
mkdir -p "$epp_dir/policy0" "$epp_dir/policy1"
printf 'balance_performance\n' > "$epp_dir/policy0/energy_performance_preference"
printf 'balance_performance\n' > "$epp_dir/policy1/energy_performance_preference"
printf 'balanced performance\n' > "$platform_choices"
printf 'balanced\n' > "$platform_profile"
printf '0\n' > "$no_turbo"

cat > "$tmp_dir/powerprofilesctl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    get) cat "$POWER_PROFILE_STATE_FILE" ;;
    set) printf '%s\n' "$2" > "$POWER_PROFILE_STATE_FILE" ;;
    *) exit 2 ;;
esac
EOF
cat > "$tmp_dir/light" <<'EOF'
#!/usr/bin/env bash
printf 'light %s\n' "$*" >> "$POWER_PROFILE_COMMAND_LOG"
[[ "$1" == -G ]] && printf '42.0\n'
EOF
cat > "$tmp_dir/rfkill" <<'EOF'
#!/usr/bin/env bash
printf 'rfkill %s\n' "$*" >> "$POWER_PROFILE_COMMAND_LOG"
EOF
cat > "$tmp_dir/bluetoothctl" <<'EOF'
#!/usr/bin/env bash
printf 'bluetoothctl %s\n' "$*" >> "$POWER_PROFILE_COMMAND_LOG"
EOF
cat > "$tmp_dir/nvidia-smi" <<'EOF'
#!/usr/bin/env bash
printf '7.5, P4\n'
EOF
cat > "$tmp_dir/ps" <<'EOF'
#!/usr/bin/env bash
printf '101 1 browser 4.8\n102 1 browser 2.2\n103 1 mail-client 1.2\n104 1 ps 200.0\n'
EOF
cat > "$tmp_dir/sudo" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == -n ]] && shift
exec /bin/bash "$@"
EOF
chmod +x "$tmp_dir/powerprofilesctl" "$tmp_dir/light" "$tmp_dir/rfkill" \
    "$tmp_dir/bluetoothctl" "$tmp_dir/nvidia-smi" "$tmp_dir/ps" "$tmp_dir/sudo"

run_helper() {
    POWER_PROFILE_CTL="$tmp_dir/powerprofilesctl" \
        POWER_PROFILE_LIGHT_BIN="$tmp_dir/light" \
        POWER_PROFILE_RFKILL_BIN="$tmp_dir/rfkill" \
        POWER_PROFILE_BLUETOOTHCTL_BIN="$tmp_dir/bluetoothctl" \
        POWER_PROFILE_STATE_FILE="$state" \
        POWER_PROFILE_COMMAND_LOG="$log" \
        POWER_PROFILE_POLICY_BIN="$policy" \
        POWER_PROFILE_SUDO_BIN="$tmp_dir/sudo" \
        POWER_PROFILE_EPP_DIR="$epp_dir" \
        POWER_PROFILE_PLATFORM_PROFILE="$platform_profile" \
        POWER_PROFILE_PLATFORM_CHOICES="$platform_choices" \
        POWER_PROFILE_NO_TURBO="$no_turbo" \
        XDG_STATE_HOME="$tmp_dir/state" \
        POWER_PROFILE_ON_BATTERY="$1" \
        bash "$helper" "${@:2}"
}

[[ "$(run_helper false default)" == performance ]]
grep -Fxq 'light -S 100' "$log"
grep -Fxq 'bluetoothctl power on' "$log"

: > "$log"
[[ "$(run_helper true default)" == balanced ]]
grep -Fxq 'light -S 60' "$log"
grep -Fxq 'bluetoothctl power on' "$log"

: > "$log"
[[ "$(run_helper true set power-saver)" == power-saver ]]
grep -Fxq 'light -S 35' "$log"
grep -Fxq 'bluetoothctl power off' "$log"
[[ "$(cat "$epp_dir/policy0/energy_performance_preference")" == power ]]
[[ "$(cat "$no_turbo")" == 1 ]]

[[ "$(run_helper true cycle)" == performance ]]
[[ "$(cat "$state")" == performance ]]
[[ "$(cat "$epp_dir/policy1/energy_performance_preference")" == performance ]]
[[ "$(cat "$no_turbo")" == 0 ]]

runtime_status="$tmp_dir/runtime_status"
printf 'suspended\n' > "$runtime_status"
snapshot="$(BATTERY_PROFILE_HELPER="$helper" \
    BATTERY_LIGHT_BIN="$tmp_dir/light" \
    BATTERY_NVIDIA_SMI="$tmp_dir/nvidia-smi" \
    BATTERY_PS_BIN="$tmp_dir/ps" \
    BATTERY_NVIDIA_RUNTIME_STATUS="$runtime_status" \
    POWER_PROFILE_CTL="$tmp_dir/powerprofilesctl" \
    POWER_PROFILE_STATE_FILE="$state" \
    POWER_PROFILE_POLICY_BIN="$policy" \
    POWER_PROFILE_SUDO_BIN="$tmp_dir/sudo" \
    POWER_PROFILE_EPP_DIR="$epp_dir" \
    POWER_PROFILE_PLATFORM_PROFILE="$platform_profile" \
    POWER_PROFILE_PLATFORM_CHOICES="$platform_choices" \
    POWER_PROFILE_NO_TURBO="$no_turbo" \
    XDG_STATE_HOME="$tmp_dir/state" \
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
    POWER_PROFILE_POLICY_BIN="$policy" \
    POWER_PROFILE_SUDO_BIN="$tmp_dir/sudo" \
    POWER_PROFILE_EPP_DIR="$epp_dir" \
    POWER_PROFILE_PLATFORM_PROFILE="$platform_profile" \
    POWER_PROFILE_PLATFORM_CHOICES="$platform_choices" \
    POWER_PROFILE_NO_TURBO="$no_turbo" \
    XDG_STATE_HOME="$tmp_dir/state" \
    bash "$consumers")"
grep -Fq '      NVIDIA: 7.5 W · P4' <<< "$snapshot"

grep -Fq "local function select_profile(profile)" "$widget"
grep -Fq "key = 'performance'," "$widget"
grep -Fq "color = beautiful.system_green_light," "$widget"
grep -Fq "key = 'balanced'," "$widget"
grep -Fq "color = beautiful.system_yellow_light," "$widget"
grep -Fq "key = 'power-saver'," "$widget"
grep -Fq "color = beautiful.system_red_light," "$widget"
grep -Fq "tooltip = '100% brightness · Bluetooth on · CPU performance · turbo on'" "$widget"
grep -Fq "tooltip = '60% brightness · Bluetooth on · balanced CPU policy'" "$widget"
grep -Fq "tooltip = '35% brightness · Bluetooth off · CPU power policy · turbo off'" "$widget"
grep -Fq 'tooltips[profile.key] = awful.tooltip' "$widget"
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
grep -Fq 'enable_user_service power-profile-monitor' "$bootstrap"
grep -Fq 'NOPASSWD: /usr/local/libexec/awesome-power-profile-policy performance' \
    "$repo_home/.config/misc/etc/sudoers.d/awesome-power-profile"

printf 'power profile tests passed\n'
