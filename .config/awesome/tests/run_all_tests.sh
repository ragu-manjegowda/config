#!/usr/bin/env bash

# Test runner for AwesomeWM configuration
# Runs all unit tests and reports results

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWESOME_DIR="$(dirname "$SCRIPT_DIR")"
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     AwesomeWM Configuration Test Suite                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to run a test
run_test() {
    local test_file="$1"
    local test_name="$(basename "$test_file" .lua | sed 's/_/ /g' | sed 's/test //')"
    
    echo -e "\n${YELLOW}▶ Running: $test_name${NC}"
    echo "$(printf '─%.0s' {1..60})"
    
    if lua "$test_file"; then
        echo -e "${GREEN}✓ $test_name passed${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ $test_name failed${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Run Lua unit tests
echo -e "${BLUE}Running Lua Unit Tests...${NC}"
for test in "$SCRIPT_DIR"/test_*.lua; do
    if [ -f "$test" ]; then
        run_test "$test" || true
    fi
done

# Run bash script tests
echo -e "\n${BLUE}Running Bash Script Tests...${NC}"
echo "$(printf '─%.0s' {1..60})"

# Test 1: Check all scripts are executable
echo -e "\n${YELLOW}▶ Checking script executability${NC}"
SCRIPTS=(
    "utilities/setup-monitors"
    "utilities/connect-external"
    "utilities/disconnect-external"
    "utilities/read-display-config"
)

SCRIPT_CHECK_PASSED=true
for script in "${SCRIPTS[@]}"; do
    if [ -f "$AWESOME_DIR/$script" ]; then
        if [ -x "$AWESOME_DIR/$script" ]; then
            echo -e "  ${GREEN}✓${NC} $script"
        else
            echo -e "  ${RED}✗${NC} $script (not executable)"
            SCRIPT_CHECK_PASSED=false
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} $script (not found)"
    fi
done

if [ "$SCRIPT_CHECK_PASSED" = true ]; then
    echo -e "${GREEN}✓ Script executability check passed${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Script executability check failed${NC}"
    ((TESTS_FAILED++))
fi

# Test 2: Check Lua syntax
echo -e "\n${YELLOW}▶ Checking Lua syntax${NC}"
SYNTAX_ERRORS=0
while IFS= read -r file; do
    if ! luac -p "$file" &>/dev/null; then
        echo -e "  ${RED}✗${NC} Syntax error in: $file"
        ((SYNTAX_ERRORS++))
    fi
done < <(find "$AWESOME_DIR" -name "*.lua" \
    -not -path "$AWESOME_DIR/library/*" \
    -not -path "$AWESOME_DIR/theme/solarized-*/*")

if [ $SYNTAX_ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Lua syntax check passed${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Lua syntax check failed ($SYNTAX_ERRORS errors)${NC}"
    ((TESTS_FAILED++))
fi

# Test 3: Check for common issues
echo -e "\n${YELLOW}▶ Checking for common issues${NC}"

# Check for world-writable files
WRITABLE_FILES=$(find "$AWESOME_DIR" -type f -perm /o+w 2>/dev/null | wc -l)
if [ "$WRITABLE_FILES" -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} No world-writable files"
else
    echo -e "  ${YELLOW}⚠${NC} Found $WRITABLE_FILES world-writable files"
fi

# Check for files without proper shebang
BAD_SCRIPTS=0
while IFS= read -r script; do
    if [ ! -r "$script" ]; then
        continue
    fi
    
    FIRST_LINE=$(head -n1 "$script")
    if [[ ! "$FIRST_LINE" =~ ^#! ]]; then
        echo -e "  ${YELLOW}⚠${NC} Missing shebang: $script"
        ((BAD_SCRIPTS++))
    fi
done < <(find "$AWESOME_DIR/utilities" -type f -executable 2>/dev/null)

if [ $BAD_SCRIPTS -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} All executable scripts have shebangs"
fi

echo -e "${GREEN}✓ Common issues check completed${NC}"
((TESTS_PASSED++))

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Test Summary                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "  Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    exit 1
fi

