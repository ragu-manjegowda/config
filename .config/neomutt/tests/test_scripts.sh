#!/bin/bash
# Test neomutt helper scripts

test_name="Helper Scripts Tests"
passed=0
failed=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "  $test_name"
echo "========================================="
echo ""

is_git_crypt_locked() {
    local file="$1"
    [ -f "$file" ] && head -c9 "$file" 2>/dev/null | LC_ALL=C tr -d '\0' | grep -q "GITCRYPT"
}

# --- Executable shell scripts ---
for script in create-alias.py query-aliases.py get-mailboxes.sh mu-search.sh \
              fzf-notmuch-search.sh setup-paths.sh sync-notmuch-flags.sh; do
    echo -n "Testing scripts/$script exists and executable... "
    if [ -x ~/.config/neomutt/scripts/$script ]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((passed++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  scripts/$script not found or not executable"
        ((failed++))
    fi
done

echo -n "Testing sender aliases are extracted once without blank entries... "
alias_test_dir="$(mktemp -d)"
mkdir -p "$alias_test_dir/.config/neomutt/accounts"
alias_test_file="$alias_test_dir/.config/neomutt/accounts/aliases"
touch "$alias_test_file"
alias_script=~/.config/neomutt/scripts/create-alias.py
if printf 'From: Ada Lovelace <ADA@example.org>\nSubject: Example\n\nBody\n' |
       HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$alias_script" >/dev/null &&
   printf 'From: Ada Lovelace <ADA@example.org>\n\nBody\n' |
       HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$alias_script" >/dev/null &&
   printf 'From: noreply@example.org\n\nBody\n' |
       HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$alias_script" >/dev/null &&
   printf 'Subject: No sender\n\nBody\n' |
       HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$alias_script" >/dev/null &&
   [[ $(wc -l < "$alias_test_file") -eq 1 ]] &&
   grep -Fxq 'alias ada Ada Lovelace <ada@example.org>' "$alias_test_file"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Sender aliases were missing, duplicated, or blank"
    ((failed++))
fi

echo -n "Testing NeoMutt loads aliases and ignores locked git-crypt content... "
alias_source_config="$alias_test_dir/source.muttrc"
printf 'set alias_file = "%s"\n' "$alias_test_file" > "$alias_source_config"
grep -F 'source "sed -n ' ~/.config/neomutt/neomuttrc >> "$alias_source_config"
alias_lookup=$(neomutt -n -F "$alias_source_config" -A ada 2>/dev/null)
printf '\0GITCRYPT\0encrypted-placeholder\n' > "$alias_test_file"
locked_query=$(neomutt -n -F "$alias_source_config" -Q alias_file 2>&1)
locked_alias_before=$(sha256sum "$alias_test_file")
printf 'From: Another Person <another@example.org>\n\nBody\n' |
    HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$alias_script" >/dev/null
if [[ "$alias_lookup" == *ada@example.org* ]] &&
   [[ "$locked_query" == *"$alias_test_file"* ]] &&
   [[ "$locked_query" != *Error* ]] &&
   [[ $(sha256sum "$alias_test_file") == "$locked_alias_before" ]]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Alias lookup failed or encrypted content was parsed as aliases"
    ((failed++))
fi

echo -n "Testing saved addresses, same-name senders, and automated sender filters... "
printf 'alias saved Saved Person <saved@example.org>\nalias alex Existing Person <old@example.org>\n' > "$alias_test_file"
add_test_sender() {
    printf 'From: %s\n\nBody\n' "$1" |
        HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$alias_script" >/dev/null
}
if add_test_sender 'Ada Lovelace <alex@example.org>' &&
   add_test_sender 'Ada Lovelace <ada@other.example.org>' &&
   add_test_sender 'Ada Lovelace <ada@third.example.org>' &&
   add_test_sender 'Saved Person <SAVED@EXAMPLE.ORG>' &&
   add_test_sender 'Notifier <DO_NOT_REPLY+alerts@example.org>' &&
   add_test_sender 'Do Not Reply <newsletter@example.org>' &&
   add_test_sender 'Service <sender@paypal.com>' &&
   add_test_sender 'Joy Reply <joy@example.org>' &&
   [[ $(wc -l < "$alias_test_file") -eq 6 ]] &&
   grep -Fxq 'alias alex-example.org Ada Lovelace <alex@example.org>' "$alias_test_file" &&
   grep -Fxq 'alias ada Ada Lovelace <ada@other.example.org>' "$alias_test_file" &&
   grep -Fxq 'alias ada-third.example.org Ada Lovelace <ada@third.example.org>' "$alias_test_file" &&
   grep -Fxq 'alias joy Joy Reply <joy@example.org>' "$alias_test_file"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Existing aliases changed, senders collided, or automated mail was saved"
    ((failed++))
fi

echo -n "Testing display filter preserves message bytes exactly... "
printf 'fRoM: Joy Reply <joy@example.org>\r\nSubject: Example\r\n\r\nBody without newline' > "$alias_test_dir/message"
HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$alias_script" \
    < "$alias_test_dir/message" > "$alias_test_dir/rendered"
if cmp -s "$alias_test_dir/message" "$alias_test_dir/rendered" &&
   [[ $(wc -l < "$alias_test_file") -eq 6 ]]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Display filter changed the rendered message"
    ((failed++))
fi

echo -n "Testing concurrent reads append a sender only once... "
for attempt in {1..8}; do
    add_test_sender 'Parallel Person <parallel@example.org>' &
done
wait
if [[ $(wc -l < "$alias_test_file") -eq 7 ]] &&
   [[ $(grep -Fxc 'alias parallel Parallel Person <parallel@example.org>' "$alias_test_file") -eq 1 ]]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Concurrent alias generation created duplicate or missing entries"
    ((failed++))
fi

echo -n "Testing folded To recipients, self-addresses, and existing aliases... "
printf 'alias alex Existing Person <old@example.org>\nalias saved Saved Sender <saved@example.org>\n' > "$alias_test_file"
printf 'work|me@example.org\n' > "$alias_test_dir/.config/neomutt/accounts/notmuch-identities"
printf 'From: Saved Sender <saved@example.org>\nTo: Alex One <alex@first.example.org>,\n Alex Two <alex@second.example.org>, recipient@example.org,\n Me <me@example.org>, do.not.reply@example.org,\n Alex One <ALEX@FIRST.EXAMPLE.ORG>\nSubject: Example\n\nTo: forwarded@example.org\n' \
    > "$alias_test_dir/to-message"
if HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$alias_script" \
       < "$alias_test_dir/to-message" > "$alias_test_dir/to-rendered" &&
   HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$alias_script" \
       < "$alias_test_dir/to-message" >/dev/null &&
   cmp -s "$alias_test_dir/to-message" "$alias_test_dir/to-rendered" &&
   [[ $(wc -l < "$alias_test_file") -eq 5 ]] &&
   grep -Fxq 'alias alex-first.example.org Alex One <alex@first.example.org>' "$alias_test_file" &&
   grep -Fxq 'alias alex-second.example.org Alex Two <alex@second.example.org>' "$alias_test_file" &&
   grep -Fxq 'alias recipient <recipient@example.org>' "$alias_test_file"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  To recipients were missing, duplicated, or incorrectly filtered"
    ((failed++))
fi

echo -n "Testing file ordering by display name with email fallback... "
printf '# Curated contacts\nalias zed Zed Person <zed@example.org>\nalias jane Jane Doe <jane@example.org>\nalias anonymous <aaron@example.org>\n' > "$alias_test_file"
if HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$alias_script" --sort &&
   add_test_sender 'Alex Sort <alex@example.org>' &&
   HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$alias_script" --sort; then
    mapfile -t alias_rows < "$alias_test_file"
fi
if [[ ${#alias_rows[@]} -eq 5 ]] &&
   [[ "${alias_rows[0]}" == '# Curated contacts' ]] &&
   [[ "${alias_rows[1]}" == 'alias anonymous <aaron@example.org>' ]] &&
   [[ "${alias_rows[2]}" == 'alias alex Alex Sort <alex@example.org>' ]] &&
   [[ "${alias_rows[3]}" == 'alias jane Jane Doe <jane@example.org>' ]] &&
   [[ "${alias_rows[4]}" == 'alias zed Zed Person <zed@example.org>' ]]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Aliases were not sorted by name/email or a curated entry changed"
    ((failed++))
fi

echo -n "Testing fuzzy alias queries, duplicate addresses, and locked checkout... "
query_script=~/.config/neomutt/scripts/query-aliases.py
printf 'alias alice1 Alice Adams <alice1@example.org>\nalias alice2 Alice Rose <alice2@example.org>\nalias duplicate Another Name <alice1@example.org>\nalias bob Bob Brown <bob@example.org>\n' > "$alias_test_file"
query_result=$(HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$query_script" ALICE)
empty_query=$(HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$query_script" '' 2>/dev/null)
empty_status=$?
printf '\0GITCRYPT\0encrypted-placeholder\n' > "$alias_test_file"
locked_query=$(HOME="$alias_test_dir" XDG_CONFIG_HOME="$alias_test_dir/.config" "$query_script" alice 2>/dev/null)
locked_status=$?
if [[ $(printf '%s\n' "$query_result" | wc -l) -eq 3 ]] &&
   grep -Fq $'alice1@example.org\tAlice Adams\talice1' <<< "$query_result" &&
   grep -Fq $'alice2@example.org\tAlice Rose\talice2' <<< "$query_result" &&
   [[ "$empty_status" -ne 0 && "$empty_query" == *'before pressing Tab'* ]] &&
   [[ "$locked_status" -ne 0 && "$locked_query" == *'Unlock git-crypt'* ]]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Fuzzy query produced incorrect matches or accessed encrypted data"
    ((failed++))
fi
rm -rf "$alias_test_dir"

setup_paths=~/.config/neomutt/scripts/setup-paths.sh
echo -n "Testing bootstrap path setup initializes both Notmuch databases... "
if grep -Fq 'NOTMUCH_IDENTITIES="$NEOMUTT_DIR/accounts/notmuch-identities"' "$setup_paths" &&
     grep -Fq "while IFS='|' read -r account email" "$setup_paths" &&
     grep -Fq 'setup_notmuch "$account" "$email"' "$setup_paths" &&
     grep -Fq 'NOTMUCH_CONFIG="$config" notmuch new' "$setup_paths"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((failed++))
fi

fzf_search=~/.config/neomutt/scripts/fzf-notmuch-search.sh
work_offline=~/.config/neomutt/accounts/work/config-offline
personal_offline=~/.config/neomutt/accounts/personal/config-offline
echo -n "Testing fuzzy search uses a valid persistent command file... "
if ! grep -Fq '.gitignored/cache/fzf-cmd.muttrc' "$fzf_search" ||
   grep -Fq 'echo "noop"' "$fzf_search"; then
    echo -e "${RED}✗ FAILED${NC}"
    ((failed++))
elif is_git_crypt_locked "$work_offline" || is_git_crypt_locked "$personal_offline"; then
    echo -e "${YELLOW}⚠ SKIPPED${NC} (git-crypt locked)"
elif grep -Fq '.gitignored/cache/fzf-cmd.muttrc' "$work_offline" &&
     grep -Fq '.gitignored/cache/fzf-cmd.muttrc' "$personal_offline"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((failed++))
fi

# --- Readable Python scripts ---
for script in render-calendar-attachment.py mutt-ical.py; do
    echo -n "Testing scripts/$script exists... "
    if [ -r ~/.config/neomutt/scripts/$script ]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((passed++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  scripts/$script not found"
        ((failed++))
    fi
done

# --- OAuth2 scripts (git-crypt encrypted, skip if locked) ---
for account in work personal; do
    file=~/.config/neomutt/accounts/$account/oauth2.py
    echo -n "Testing accounts/$account/oauth2.py exists and executable... "
    if is_git_crypt_locked "$file"; then
        echo -e "${YELLOW}⚠ SKIPPED${NC} (git-crypt locked)"
    elif [ -x "$file" ]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((passed++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  accounts/$account/oauth2.py not found or not executable"
        ((failed++))
    fi
done

# --- Python script syntax validation ---
for script in scripts/create-alias.py scripts/query-aliases.py scripts/render-calendar-attachment.py scripts/mutt-ical.py; do
    if [ -r ~/.config/neomutt/$script ]; then
        echo -n "Testing $script syntax... "
        if python -m py_compile ~/.config/neomutt/$script 2>/dev/null; then
            echo -e "${GREEN}✓ PASSED${NC}"
            ((passed++))
        else
            echo -e "${RED}✗ FAILED${NC}"
            echo "  $script has syntax errors"
            ((failed++))
        fi
    fi
done

for script in accounts/work/oauth2.py accounts/personal/oauth2.py; do
    file=~/.config/neomutt/$script
    if is_git_crypt_locked "$file"; then
        echo -e "Testing $script syntax... ${YELLOW}⚠ SKIPPED${NC} (git-crypt locked)"
    elif [ -r "$file" ]; then
        echo -n "Testing $script syntax... "
        if python -m py_compile "$file" 2>/dev/null; then
            echo -e "${GREEN}✓ PASSED${NC}"
            ((passed++))
        else
            echo -e "${RED}✗ FAILED${NC}"
            echo "  $script has syntax errors"
            ((failed++))
        fi
    fi
done

# --- Shell script syntax validation ---
for script in get-mailboxes.sh mu-search.sh \
               fzf-notmuch-search.sh setup-paths.sh sync-notmuch-flags.sh; do
    file=~/.config/neomutt/scripts/$script
    if is_git_crypt_locked "$file"; then
        echo -e "Testing $script syntax... ${YELLOW}⚠ SKIPPED${NC} (git-crypt locked)"
    elif [ -r "$file" ]; then
        echo -n "Testing $script syntax... "
        if bash -n "$file" 2>/dev/null; then
            echo -e "${GREEN}✓ PASSED${NC}"
            ((passed++))
        else
            echo -e "${RED}✗ FAILED${NC}"
            echo "  $script has syntax errors"
            ((failed++))
        fi
    fi
done

for account in work personal; do
    file=~/.config/neomutt/accounts/$account/mbsyncrc
    echo -n "Testing $account background sync pulls all server-side changes... "
    if is_git_crypt_locked "$file"; then
        echo -e "${YELLOW}⚠ SKIPPED${NC} (git-crypt locked)"
    elif grep -Fqx "Sync Pull" "$file"; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((passed++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  Pull channel does not propagate the complete remote change set"
        ((failed++))
    fi
done

echo -n "Testing Notmuch synchronization never clears unread globally... "
if grep -Fq 'notmuch new' ~/.config/neomutt/scripts/sync-notmuch-flags.sh &&
   ! grep -Fq "notmuch tag -unread -- 'tag:unread'" ~/.config/neomutt/scripts/sync-notmuch-flags.sh; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Notmuch synchronization can erase authoritative Maildir unread flags"
    ((failed++))
fi

echo -n "Testing Notmuch synchronization preserves unread Maildir flags... "
flag_test_dir="$(mktemp -d)"
flag_test_maildir="$flag_test_dir/mail"
flag_test_config="$flag_test_dir/notmuch-config"
mkdir -p "$flag_test_maildir/Inbox/cur" "$flag_test_maildir/Inbox/new" \
    "$flag_test_maildir/Inbox/tmp"
cat > "$flag_test_config" <<EOF
[database]
path=$flag_test_maildir

[user]
name=Test User
primary_email=test@example.com

[new]
tags=unread;inbox

[maildir]
synchronize_flags=true
EOF
cat > "$flag_test_maildir/Inbox/cur/unread:2," <<'EOF'
From: sender@example.com
To: test@example.com
Subject: Unread message
Date: Mon, 14 Sep 2026 09:00:00 +0000
Message-ID: <unread@example.com>

Unread body.
EOF
cat > "$flag_test_maildir/Inbox/cur/read:2,S" <<'EOF'
From: sender@example.com
To: test@example.com
Subject: Read message
Date: Mon, 14 Sep 2026 09:01:00 +0000
Message-ID: <read@example.com>

Read body.
EOF
if ~/.config/neomutt/scripts/sync-notmuch-flags.sh "$flag_test_config" >/dev/null &&
   [[ -f "$flag_test_maildir/Inbox/cur/unread:2," ]] &&
   [[ -f "$flag_test_maildir/Inbox/cur/read:2,S" ]] &&
   [[ $(NOTMUCH_CONFIG="$flag_test_config" notmuch count 'tag:unread') == 1 ]]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Notmuch synchronization changed read/unread Maildir flags"
    ((failed++))
fi
rm -rf "$flag_test_dir"

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed"
echo "========================================="

if [ $failed -gt 0 ]; then
    exit 1
fi
exit 0
