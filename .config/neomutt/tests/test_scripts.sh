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
for script in create-alias.sh get-mailboxes.sh mu-search.sh \
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
for script in scripts/render-calendar-attachment.py scripts/mutt-ical.py; do
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
for script in create-alias.sh get-mailboxes.sh mu-search.sh \
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

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed"
echo "========================================="

if [ $failed -gt 0 ]; then
    exit 1
fi
exit 0
