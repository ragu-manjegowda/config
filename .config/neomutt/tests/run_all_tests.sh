#!/bin/bash
# Neomutt Configuration Test Runner
# Runs all tests for Neomutt configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEOMUTT_CONFIG_DIR="$(dirname "$SCRIPT_DIR")"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "═══════════════════════════════════════════════════════════"
echo "  Neomutt Configuration Tests"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if neomutt is installed
if ! command -v neomutt &> /dev/null; then
    echo -e "${RED}✗ Error: Neomutt not found${NC}"
    echo "Please install Neomutt to run tests"
    exit 1
fi

echo "Neomutt version: $(neomutt -v 2>&1 | head -n1)"
echo "Config directory: $NEOMUTT_CONFIG_DIR"
echo ""

echo "───────────────────────────────────────────────────────────"
echo "  Running Tests"
echo "───────────────────────────────────────────────────────────"
echo ""

# Find all test files
TEST_FILES=(
    "$SCRIPT_DIR/test_config_syntax.sh"
    "$SCRIPT_DIR/test_scripts.sh"
    "$SCRIPT_DIR/test_settings.sh"
    "$SCRIPT_DIR/test_mailcap.sh"
)

FAILED_TESTS=0
PASSED_TESTS=0
TOTAL_TESTS=0

for test_file in "${TEST_FILES[@]}"; do
    if [ -f "$test_file" ]; then
        test_name=$(basename "$test_file" .sh | sed 's/test_//' | sed 's/_/ /g')

        echo -e "${BLUE}Running: $test_name${NC}"
        echo ""

        # Run the test
        if bash "$test_file"; then
            echo -e "${GREEN}✓ $test_name passed${NC}"
            ((PASSED_TESTS++))
        else
            echo -e "${RED}✗ $test_name failed${NC}"
            ((FAILED_TESTS++))
        fi

        ((TOTAL_TESTS++))
        echo ""
    else
        echo -e "${YELLOW}⚠ Test file not found: $test_file${NC}"
    fi
done

echo "───────────────────────────────────────────────────────────"
echo "  Test Summary"
echo "───────────────────────────────────────────────────────────"
echo ""
echo "Total test suites: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"

if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${RED}  TESTS FAILED${NC}"
    echo "═══════════════════════════════════════════════════════════"
    exit 1
else
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${GREEN}  ALL TESTS PASSED${NC}"
    echo "═══════════════════════════════════════════════════════════"
    exit 0
fi

