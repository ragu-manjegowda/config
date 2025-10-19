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

# Test 1: create-alias.sh exists and executable
echo -n "Testing create-alias.sh exists and executable... "
if [ -x ~/.config/neomutt/create-alias.sh ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  create-alias.sh not found or not executable"
    ((failed++))
fi

# Test 2: get-mailboxes.sh exists and executable
echo -n "Testing get-mailboxes.sh exists and executable... "
if [ -x ~/.config/neomutt/get-mailboxes.sh ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  get-mailboxes.sh not found or not executable"
    ((failed++))
fi

# Test 3: mu-search.sh exists and executable
echo -n "Testing mu-search.sh exists and executable... "
if [ -x ~/.config/neomutt/mu-search.sh ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  mu-search.sh not found or not executable"
    ((failed++))
fi

# Test 4: viewmailattachments.py exists and readable
echo -n "Testing viewmailattachments.py exists... "
if [ -r ~/.config/neomutt/viewmailattachments.py ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  viewmailattachments.py not found"
    ((failed++))
fi

# Test 5: render-calendar-attachment.py exists and readable
echo -n "Testing render-calendar-attachment.py exists... "
if [ -r ~/.config/neomutt/render-calendar-attachment.py ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  render-calendar-attachment.py not found"
    ((failed++))
fi

# Test 6: mutt-ical.py exists and readable
echo -n "Testing mutt-ical.py exists... "
if [ -r ~/.config/neomutt/mutt-ical.py ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  mutt-ical.py not found"
    ((failed++))
fi

# Test 7: Python scripts have valid syntax
for script in viewmailattachments.py render-calendar-attachment.py mutt-ical.py; do
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

# Test 8: Shell scripts have valid syntax
for script in create-alias.sh get-mailboxes.sh mu-search.sh; do
    if [ -r ~/.config/neomutt/$script ]; then
        echo -n "Testing $script syntax... "
        if bash -n ~/.config/neomutt/$script 2>/dev/null; then
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

