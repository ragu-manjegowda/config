#!/usr/bin/env bash

set -euo pipefail

root="${HOME}/.config/neomutt"
script="$root/scripts/fzf-notmuch-search.sh"
temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT

maildir="$temp/mail"
config_home="$temp/config"
mkdir -p "$maildir/division/program/reports/cur" "$temp/bin"

cat > "$temp/bin/notmuch" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == config && $2 == get && $3 == database.path ]]; then
    printf '%s\n' "$MOCK_MAILDIR"
elif [[ $1 == search ]]; then
    printf '%s\n' 'thread:0001 today [1/1] Example Sender; Quarterly report (inbox)'
else
    exit 1
fi
EOF

cat > "$temp/bin/fzf" <<'EOF'
#!/usr/bin/env bash
for argument in "$@"; do
    case "$argument" in
        --filter=*) pattern="${argument#--filter=}" ;;
    esac
done
grep -i -- "${pattern:?}"
EOF
chmod +x "$temp/bin/notmuch" "$temp/bin/fzf"

run_search() {
    printf '%s\n' "$1" | PATH="$temp/bin:$PATH" \
        XDG_CONFIG_HOME="$config_home" MOCK_MAILDIR="$maildir" TERM=xterm \
        "$script" "$temp/notmuch-config" >/dev/null
}

command_file="$config_home/neomutt/.gitignored/cache/fzf-cmd.muttrc"

run_search '"quarterly" folder:reports'
grep -Fq 'folder:"division/program/reports"' "$command_file"
grep -Fq 'thread:0001' "$command_file"

run_search 'folder:reports'
grep -Fq "<vfolder-from-query>(folder:\"division/program/reports\")<enter>" \
    "$command_file"

printf 'fuzzy Notmuch folder tests passed\n'
