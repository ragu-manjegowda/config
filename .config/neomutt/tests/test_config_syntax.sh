#!/bin/bash
# Test neomutt configuration syntax validation

test_name="Config Syntax Tests"
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

# Test 1: Main config file syntax
echo -n "Testing neomuttrc syntax... "
if neomutt -F ~/.config/neomutt/neomuttrc -Q quit 2>&1 | grep -q "Error"; then
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Main config has syntax errors"
    ((failed++))
else
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
fi

# Test 2: Bindings file exists and is readable
echo -n "Testing bindings.mutt exists and readable... "
if [ -r ~/.config/neomutt/bindings.mutt ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  bindings.mutt not found or not readable"
    ((failed++))
fi

# Test 3: Styles file exists and is readable
echo -n "Testing styles.muttrc exists and readable... "
if [ -r ~/.config/neomutt/styles.muttrc ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  styles.muttrc not found or not readable"
    ((failed++))
fi

# Test 4: Colors file exists and is readable
echo -n "Testing colors-custom.muttrc exists and readable... "
if [ -r ~/.config/neomutt/colors-custom.muttrc ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  colors-custom.muttrc not found or not readable"
    ((failed++))
fi

# Test 5: GPG config exists and is readable
echo -n "Testing gpg.rc exists and readable... "
if [ -r ~/.config/neomutt/gpg.rc ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  gpg.rc not found or not readable"
    ((failed++))
fi

# Test 6: Mailcap file exists and is readable
echo -n "Testing mailcap exists and readable... "
if [ -r ~/.config/neomutt/mailcap ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  mailcap not found or not readable"
    ((failed++))
fi

# Test 7: Headers file exists and is readable
echo -n "Testing headers file exists and readable... "
if [ -r ~/.config/neomutt/headers ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  headers file not found or not readable"
    ((failed++))
fi

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed"
echo "========================================="

if [ $failed -gt 0 ]; then
    exit 1
fi
exit 0

