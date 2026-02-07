#!/bin/bash
# Test neomutt mailcap configuration

test_name="Mailcap Configuration Tests"
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

MAILCAP_FILE="$HOME/.config/neomutt/config/mailcap"

# Test 1: HTML rendering configured
echo -n "Testing HTML rendering configured... "
if grep -q "text/html" "$MAILCAP_FILE"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  HTML rendering not configured in mailcap"
    ((failed++))
fi

# Test 2: PDF viewer configured
echo -n "Testing PDF viewer configured... "
if grep -q "application/pdf" "$MAILCAP_FILE"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  PDF viewer not configured in mailcap"
    ((failed++))
fi

# Test 3: Calendar invites handling configured
echo -n "Testing calendar invites configured... "
if grep -q "text/calendar\|application/ics" "$MAILCAP_FILE"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Calendar handling not configured in mailcap"
    ((failed++))
fi

# Test 4: Image viewer configured
echo -n "Testing image viewer configured... "
if grep -q "image/\*" "$MAILCAP_FILE"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Image viewer not configured in mailcap"
    ((failed++))
fi

# Test 5: Audio/Video player configured
echo -n "Testing audio/video player configured... "
if grep -q "audio/\*\|video/\*" "$MAILCAP_FILE"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Audio/video player not configured in mailcap"
    ((failed++))
fi

# Test 6: MS Word documents handling configured
echo -n "Testing MS Word handling configured... "
if grep -q "application/.*word" "$MAILCAP_FILE"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  MS Word handling not configured in mailcap"
    ((failed++))
fi

# Test 7: Text editor configured
echo -n "Testing text editor configured... "
if grep -q "text/plain" "$MAILCAP_FILE"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Text editor not configured in mailcap"
    ((failed++))
fi

# Test 8: Check for required applications
echo -n "Testing w3m (HTML) installed... "
if command -v w3m &> /dev/null; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${YELLOW}⚠ SKIPPED${NC}"
    echo "  w3m not installed (may be CI environment)"
fi

echo -n "Testing nvim installed... "
if command -v nvim &> /dev/null; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${YELLOW}⚠ SKIPPED${NC}"
    echo "  nvim not installed (may be CI environment)"
fi

echo -n "Testing mpv (audio/video) installed... "
if command -v mpv &> /dev/null; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((passed++))
else
    echo -e "${YELLOW}⚠ SKIPPED${NC}"
    echo "  mpv not installed (may be CI environment)"
fi

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed"
echo "========================================="

if [ $failed -gt 0 ]; then
    exit 1
fi
exit 0
