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
    if [ -r ~/.config/neomutt/scripts/$script ]; then
        echo -n "Testing $script syntax... "
        if bash -n ~/.config/neomutt/scripts/$script 2>/dev/null; then
            echo -e "${GREEN}✓ PASSED${NC}"
            ((passed++))
        else
            echo -e "${RED}✗ FAILED${NC}"
            echo "  $script has syntax errors"
            ((failed++))
        fi
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
