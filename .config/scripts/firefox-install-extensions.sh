#!/usr/bin/env bash

set -euo pipefail

manifest_path="${1:-$HOME/.config/firefox/extensions.txt}"
profiles_ini="$HOME/.mozilla/firefox/profiles.ini"
potatofox_path="${POTATOFOX_PATH:-$HOME/.config/firefox/potatofox}"
user_agent_switcher_prefs="${USER_AGENT_SWITCHER_PREFS:-$HOME/.config/firefox/useragent-switcher-preferences.json}"

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

need() {
    command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

default_profile_path() {
    awk -F= '
        /^\[Install/ { in_install = 1; next }
        /^\[/ { in_install = 0 }
        in_install && $1 == "Default" { print $2; found = 1; exit }
        END { exit found ? 0 : 1 }
    ' "$profiles_ini" 2>/dev/null || awk -F= '
        /^\[Profile/ { in_profile = 1; path = ""; is_default = 0; next }
        /^\[/ {
            if (in_profile && is_default && path != "") { print path; found = 1; exit }
            in_profile = 0
        }
        in_profile && $1 == "Path" { path = $2 }
        in_profile && $1 == "Default" && $2 == "1" { is_default = 1 }
        END {
            if (!found && in_profile && is_default && path != "") { print path; found = 1 }
            exit found ? 0 : 1
        }
    ' "$profiles_ini" 2>/dev/null
}

profile_records() {
    awk -F= '
        function flush_profile() {
            if (in_profile && path != "") {
                printf "%s\t%s\t%s\t%s\t%s\n", section, name, path, is_default, is_relative
            }
        }

        /^\[Profile[0-9]+\]/ {
            flush_profile()
            in_profile = 1
            section = $0
            gsub(/^\[/, "", section)
            gsub(/\]$/, "", section)
            name = ""
            path = ""
            is_default = "0"
            is_relative = "1"
            next
        }

        /^\[/ {
            flush_profile()
            in_profile = 0
            next
        }

        in_profile && $1 == "Name" { name = $2 }
        in_profile && $1 == "Path" { path = $2 }
        in_profile && $1 == "Default" { is_default = $2 }
        in_profile && $1 == "IsRelative" { is_relative = $2 }

        END { flush_profile() }
    ' "$profiles_ini"
}

resolve_profile_path() {
    local path="$1" is_relative="$2"

    if [[ "$path" == /* || "$is_relative" == "0" ]]; then
        printf '%s' "$path"
    else
        printf '%s/.mozilla/firefox/%s' "$HOME" "$path"
    fi
}

prune_profiles_ini() {
    local default_path="$1" tmp

    tmp="$(mktemp)"
    awk -v home="$HOME" -v keep="$default_path" '
        function absolute_profile_path(path, is_relative) {
            if (path ~ /^\// || is_relative == "0") {
                return path
            }
            return home "/.mozilla/firefox/" path
        }

        function flush_profile(i) {
            if (!in_profile) {
                return
            }
            if (absolute_profile_path(path, is_relative) == keep) {
                for (i = 1; i <= buffered_count; i++) {
                    print buffered[i]
                }
            }
            delete buffered
            buffered_count = 0
            in_profile = 0
        }

        /^\[Profile[0-9]+\]/ {
            flush_profile()
            in_profile = 1
            path = ""
            is_relative = "1"
            buffered_count = 1
            buffered[buffered_count] = $0
            next
        }

        /^\[/ {
            flush_profile()
            print
            next
        }

        in_profile {
            buffered[++buffered_count] = $0
            if ($0 ~ /^Path=/) {
                path = substr($0, 6)
            } else if ($0 ~ /^IsRelative=/) {
                is_relative = substr($0, 12)
            }
            next
        }

        { print }

        END { flush_profile() }
    ' "$profiles_ini" >"$tmp"
    install -m 0600 "$tmp" "$profiles_ini"
    rm -f "$tmp"
}

offer_delete_non_default_profiles() {
    local default_profile="$1" reply line section name path is_default is_relative profile_path
    local -a profiles=() non_default_profiles=()

    mapfile -t profiles < <(profile_records)
    (( ${#profiles[@]} > 1 )) || return 0

    printf 'Found %s Firefox profiles:\n' "${#profiles[@]}"
    for line in "${profiles[@]}"; do
        IFS=$'\t' read -r section name path is_default is_relative <<<"$line"
        profile_path="$(resolve_profile_path "$path" "$is_relative")"
        if [[ "$profile_path" == "$default_profile" ]]; then
            printf '  * %s (%s) [default]\n' "${name:-$section}" "$profile_path"
        else
            printf '  - %s (%s)\n' "${name:-$section}" "$profile_path"
            non_default_profiles+=("$line")
        fi
    done

    (( ${#non_default_profiles[@]} > 0 )) || return 0
    if [[ ! -t 0 ]]; then
        printf 'More than one Firefox profile exists; run interactively to delete non-default profiles.\n'
        return 0
    fi

    read -r -p 'Delete non-default Firefox profiles? [y/N] ' reply
    case "$reply" in
        [Yy]|[Yy][Ee][Ss]) ;;
        *) return 0 ;;
    esac

    for line in "${non_default_profiles[@]}"; do
        IFS=$'\t' read -r section name path is_default is_relative <<<"$line"
        profile_path="$(resolve_profile_path "$path" "$is_relative")"
        case "$profile_path" in
            "$HOME"/.mozilla/firefox/*)
                rm -rf -- "$profile_path"
                printf 'Deleted non-default profile %s (%s)\n' "${name:-$section}" "$profile_path"
                ;;
            *)
                printf 'Skipping profile outside Firefox directory: %s\n' "$profile_path" >&2
                ;;
        esac
    done

    prune_profiles_ini "$default_profile"
}

ensure_symlink() {
    local target="$1" link_path="$2" current_target

    if [[ ! -e "$target" ]]; then
        printf 'Skipping missing potatofox target: %s\n' "$target" >&2
        return 0
    fi

    if [[ -L "$link_path" ]]; then
        current_target="$(readlink "$link_path")"
        if [[ "$current_target" == "$target" ]]; then
            printf 'Symlink already exists: %s -> %s\n' "$link_path" "$target"
        else
            printf 'Skipping existing symlink with different target: %s -> %s\n' "$link_path" "$current_target" >&2
        fi
        return 0
    fi

    if [[ -e "$link_path" ]]; then
        printf 'Skipping existing non-symlink path: %s\n' "$link_path" >&2
        return 0
    fi

    ln -s "$target" "$link_path"
    printf 'Created symlink: %s -> %s\n' "$link_path" "$target"
}

setup_potatofox_links() {
    local profile_path="$1"

    ensure_symlink "$potatofox_path/user.js" "$profile_path/user.js"
    ensure_symlink "$potatofox_path/chrome" "$profile_path/chrome"
}

user_agent_switcher_id_from_manifest() {
    awk '
        /^[[:space:]]*#/ { next }
        tolower($0) ~ /user-agent switcher|user_agent_string_switcher|useragent/ {
            line = $0
            sub(/[[:space:]]+#.*/, "", line)
            count = split(line, fields, /[[:space:]]+/)
            if (count >= 2) {
                print fields[2]
                exit
            }
        }
    ' "$manifest_path"
}

install_user_agent_switcher_prefs() {
    local extension_id managed_dir managed_path tmp

    if [[ ! -f "$user_agent_switcher_prefs" ]]; then
        printf 'User-Agent Switcher preferences not found; skipping managed settings: %s\n' "$user_agent_switcher_prefs"
        return 0
    fi

    extension_id="${USER_AGENT_SWITCHER_ID:-$(user_agent_switcher_id_from_manifest)}"
    [[ -n "$extension_id" ]] \
        || die 'could not determine User-Agent Switcher extension ID from manifest; set USER_AGENT_SWITCHER_ID'

    jq -e '
        type == "object"
        and has("json-guid")
        and (.blacklist? | type == "array")
    ' "$user_agent_switcher_prefs" >/dev/null \
        || die "invalid User-Agent Switcher preferences JSON: $user_agent_switcher_prefs"

    managed_dir="$HOME/.mozilla/managed-storage"
    managed_path="$managed_dir/$extension_id.json"
    tmp="$(mktemp)"
    mkdir -p "$managed_dir"

    jq -n \
        --arg name "$extension_id" \
        --rawfile prefs "$user_agent_switcher_prefs" \
        '{
            name: $name,
            description: "User-Agent Switcher and Manager preferences",
            type: "storage",
            data: {
                json: $prefs
            }
        }' >"$tmp"

    install -m 0600 "$tmp" "$managed_path"
    rm -f "$tmp"
    printf 'Installed User-Agent Switcher managed settings: %s\n' "$managed_path"
}

download_url_for() {
    local item="$1"
    local slug

    if [[ "$item" =~ ^https?:// ]]; then
        if [[ "$item" =~ /addon/([^/?#]+)/? ]]; then
            slug="${BASH_REMATCH[1]}"
            printf 'https://addons.mozilla.org/firefox/downloads/latest/%s/latest.xpi' "$slug"
        else
            printf '%s' "$item"
        fi
    else
        printf 'https://addons.mozilla.org/firefox/downloads/latest/%s/latest.xpi' "$item"
    fi
}

extension_id_from_xpi() {
    local xpi_path="$1"
    local extension_id

    extension_id="$(unzip -p "$xpi_path" manifest.json \
        | jq -r '.browser_specific_settings.gecko.id // .applications.gecko.id // empty')"
    if [[ -n "$extension_id" ]]; then
        printf '%s\n' "$extension_id"
        return 0
    fi

    unzip -p "$xpi_path" META-INF/mozilla.rsa 2>/dev/null \
        | strings \
        | grep -Eo -m1 '\{[0-9A-Fa-f-]{36}\}'
}

need curl
need grep
need install
need jq
need mktemp
need strings
need unzip

[[ -f "$manifest_path" ]] || die "manifest not found: $manifest_path"
[[ -f "$profiles_ini" ]] || die "Firefox profiles.ini not found: $profiles_ini"

profile_path="${FIREFOX_PROFILE_PATH:-$(default_profile_path)}"
[[ -n "$profile_path" ]] || die 'could not determine Firefox profile path'

if [[ "$profile_path" != /* ]]; then
    profile_path="$HOME/.mozilla/firefox/$profile_path"
fi

offer_delete_non_default_profiles "$profile_path"
setup_potatofox_links "$profile_path"
install_user_agent_switcher_prefs

extensions_dir="$profile_path/extensions"
mkdir -p "$extensions_dir"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

installed=0
skipped=0
processed=0
failed=0
failed_extensions=()

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    line="$(trim "${raw_line%%#*}")"
    [[ -n "$line" ]] || continue
    read -r item manifest_extension_id _ <<<"$line"

    if [[ -n "${manifest_extension_id:-}" && -e "$extensions_dir/$manifest_extension_id.xpi" ]]; then
        printf 'Extension already installed; skipping %s\n' "$manifest_extension_id"
        skipped=$((skipped + 1))
        continue
    fi

    url="$(download_url_for "$item")"
    xpi_path="$tmpdir/addon-$processed.xpi"
    processed=$((processed + 1))

    printf 'Downloading %s\n' "$url"
    if ! curl -fsSL -o "$xpi_path" "$url"; then
        printf 'Failed to download; skipping %s\n' "$item" >&2
        failed_extensions+=("$item (download failed: $url)")
        failed=$((failed + 1))
        continue
    fi

    if ! extension_id="$(extension_id_from_xpi "$xpi_path")" || [[ -z "$extension_id" ]]; then
        if [[ -n "${manifest_extension_id:-}" ]]; then
            extension_id="$manifest_extension_id"
        else
            printf 'Could not determine extension ID; skipping %s\n' "$item" >&2
            failed_extensions+=("$item (could not determine extension ID)")
            failed=$((failed + 1))
            continue
        fi
    fi

    if [[ -n "${manifest_extension_id:-}" && "$manifest_extension_id" != "$extension_id" ]]; then
        printf 'Manifest ID differs from downloaded ID for %s: %s != %s\n' "$item" "$manifest_extension_id" "$extension_id" >&2
    fi

    if [[ -e "$extensions_dir/$extension_id.xpi" ]]; then
        printf 'Extension already installed; skipping %s\n' "$extension_id"
        skipped=$((skipped + 1))
        continue
    fi

    if ! install -m 0644 "$xpi_path" "$extensions_dir/$extension_id.xpi"; then
        printf 'Failed to install %s; skipping %s\n' "$extension_id" "$item" >&2
        failed_extensions+=("$item (install failed for $extension_id)")
        failed=$((failed + 1))
        continue
    fi
    printf 'Installed %s\n' "$extension_id"
    installed=$((installed + 1))
done < "$manifest_path"

printf 'Installed %s extension(s), skipped %s existing extension(s), failed %s extension(s) in %s\n' "$installed" "$skipped" "$failed" "$extensions_dir"
if (( failed > 0 )); then
    printf 'Failed extension(s):\n' >&2
    printf '  - %s\n' "${failed_extensions[@]}" >&2
fi
printf 'Restart Firefox to load newly installed or updated extensions.\n'
