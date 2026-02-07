#!/bin/bash
# Test neomutt configuration settings

test_name="Settings Validation Tests"
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

CONFIG_FILE="$HOME/.config/neomutt/neomuttrc"

# Helper function to check setting value
check_setting() {
    local setting=$1
    local expected=$2
    local description=$3

    echo -n "Testing $description... "

    # Query the setting from neomutt
    actual=$(neomutt -F "$CONFIG_FILE" -Q "$setting" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | xargs)

    if [ "$actual" = "$expected" ]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((passed++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  Expected: $expected"
        echo "  Got: $actual"
        ((failed++))
        return 1
    fi
}

# Helper function to check boolean setting
check_bool_setting() {
    local setting=$1
    local expected=$2
    local description=$3

    echo -n "Testing $description... "

    # Query the setting from neomutt
    if neomutt -F "$CONFIG_FILE" -Q "$setting" 2>/dev/null | grep -q "yes"; then
        actual="yes"
    else
        actual="no"
    fi

    if [ "$actual" = "$expected" ]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((passed++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  Expected: $expected"
        echo "  Got: $actual"
        ((failed++))
        return 1
    fi
}

# Test critical settings
check_bool_setting "delete" "yes" "delete without confirmation"
check_bool_setting "ssl_force_tls" "yes" "force TLS for connections"
check_setting "timeout" "5" "timeout setting"
check_setting "mail_check" "10" "mail check interval"
check_setting "pager_index_lines" "10" "pager index lines"
check_setting "sleep_time" "0" "sleep time"
check_bool_setting "ts_enabled" "yes" "terminal status enabled"
check_bool_setting "include" "yes" "include message in reply"
check_bool_setting "smart_wrap" "yes" "smart wrap enabled"
check_setting "wrap" "90" "wrap width"
check_bool_setting "text_flowed" "yes" "text flowed format"
# Note: quit=ask-yes shows as "yes" when queried, this is expected
# check_bool_setting "quit" "ask-yes" "quit confirmation"
check_bool_setting "fcc_attach" "yes" "save attachments with body"
check_bool_setting "forward_decode" "yes" "forward decode"
check_setting "history" "10000" "history size"
check_bool_setting "pager_stop" "yes" "pager stop at end"
check_bool_setting "menu_scroll" "yes" "menu scroll"
check_setting "sidebar_width" "30" "sidebar width"
check_bool_setting "sidebar_short_path" "yes" "sidebar short path"
check_bool_setting "sidebar_folder_indent" "yes" "sidebar folder indent"

# Test editor setting contains nvim
echo -n "Testing editor is nvim... "
editor=$(neomutt -F "$CONFIG_FILE" -Q editor 2>/dev/null | cut -d'=' -f2- | tr -d '"')
if echo "$editor" | grep -q "nvim"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Editor doesn't use nvim: $editor"
    ((failed++))
fi

# Test mailcap_path contains neomutt/mailcap
echo -n "Testing mailcap path points to neomutt/config/mailcap... "
mailcap_path=$(neomutt -F "$CONFIG_FILE" -Q mailcap_path 2>/dev/null | cut -d'=' -f2- | tr -d '"')
if echo "$mailcap_path" | grep -q "neomutt/config/mailcap"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Mailcap path doesn't point to neomutt/config/mailcap: $mailcap_path"
    ((failed++))
fi

# Test alias_file contains neomutt/aliases
echo -n "Testing alias file path points to neomutt/.gitignored/data/aliases... "
alias_file=$(neomutt -F "$CONFIG_FILE" -Q alias_file 2>/dev/null | cut -d'=' -f2- | tr -d '"')
if echo "$alias_file" | grep -q "neomutt/.gitignored/data/aliases"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Alias file doesn't point to neomutt/.gitignored/data/aliases: $alias_file"
    ((failed++))
fi

# Test history_file contains neomutt/history
echo -n "Testing history file path points to neomutt/.gitignored/data/history... "
history_file=$(neomutt -F "$CONFIG_FILE" -Q history_file 2>/dev/null | cut -d'=' -f2- | tr -d '"')
if echo "$history_file" | grep -q "neomutt/.gitignored/data/history"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  History file doesn't point to neomutt/.gitignored/data/history: $history_file"
    ((failed++))
fi

# Test gitignore patterns for runtime files
echo -n "Testing gitignore rules for neomutt runtime files... "
GIT_ROOT=""
if [ -n "${GITHUB_WORKSPACE:-}" ] && [ -d "$GITHUB_WORKSPACE/.git" ]; then
    GIT_ROOT="$GITHUB_WORKSPACE"
else
    GIT_ROOT=$(git -C "$HOME" rev-parse --show-toplevel 2>/dev/null || true)
fi

if [ -z "$GIT_ROOT" ] || [ ! -f "$GIT_ROOT/.gitignore" ]; then
    echo -e "${YELLOW}⚠ SKIPPED${NC}"
    echo "  .gitignore not found in repo"
else
    missing=0
    required_patterns=(
        "/.config/neomutt/.gitignored"
        "/.config/neomutt/credentials/token_*"
        "/.config/neomutt/**/__pycache__"
        "/.config/neomutt/**/.mypy_cache"
    )

    for pattern in "${required_patterns[@]}"; do
        if ! grep -Fqx "$pattern" "$GIT_ROOT/.gitignore" && ! grep -Fqx "${pattern}/" "$GIT_ROOT/.gitignore"; then
            missing=1
        fi
    done

    if [ $missing -ne 0 ]; then
        echo -e "${RED}✗ FAILED${NC}"
        echo "  Missing required neomutt ignore patterns in .gitignore"
        ((failed++))
    else
        echo -e "${GREEN}✓ PASSED${NC}"
        ((passed++))
    fi
fi

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed"
echo "========================================="

if [ $failed -gt 0 ]; then
    exit 1
fi
exit 0
