#!/bin/bash
# Neovim Configuration Test Runner
# Runs all tests for Neovim configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_CONFIG_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "═══════════════════════════════════════════════════════════"
echo "  Neovim Configuration Tests"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if nvim is installed
if ! command -v nvim &> /dev/null; then
    echo -e "${RED}✗ Error: Neovim not found${NC}"
    echo "Please install Neovim to run tests"
    exit 1
fi

echo "Neovim version: $(nvim --version | head -n1)"
echo "Config directory: $NVIM_CONFIG_DIR"
echo ""

# Check if plenary.nvim is available
echo "Checking dependencies..."
PLENARY_PATH="$HOME/.local/share/nvim/site/pack/vendor/start/plenary.nvim"
if [ ! -d "$PLENARY_PATH" ]; then
    echo -e "${YELLOW}⚠ plenary.nvim not found, installing...${NC}"
    mkdir -p "$(dirname "$PLENARY_PATH")"
    git clone --depth=1 https://github.com/nvim-lua/plenary.nvim "$PLENARY_PATH"
    echo -e "${GREEN}✓ plenary.nvim installed${NC}"
else
    echo -e "${GREEN}✓ plenary.nvim found${NC}"
fi

echo ""
echo "───────────────────────────────────────────────────────────"
echo "  Running Tests"
echo "───────────────────────────────────────────────────────────"
echo ""

# Find all test files automatically
TEST_FILES=($(find "$SCRIPT_DIR" -name "test_*.lua" -not -name "test_utils.lua" | sort))

FAILED_TESTS=0
PASSED_TESTS=0

for test_file in "${TEST_FILES[@]}"; do
    if [ -f "$test_file" ]; then
        test_name=$(basename "$test_file" .lua)
        echo "Running: $test_name"
        
        # Run test with minimal init
        nvim --headless \
            -u "$SCRIPT_DIR/minimal_init.lua" \
            -c "lua require('plenary.busted').run('$test_file')" \
            -c "qa!" \
            2>&1 | tee "/tmp/nvim_test_$test_name.log"
        
        # Check exit code from test output
        # Strip ANSI color codes and extract numbers
        failed_count=$(grep "Failed" "/tmp/nvim_test_$test_name.log" | sed 's/\x1b\[[0-9;]*m//g' | grep -oE '[0-9]+' | tail -1)
        error_count=$(grep "Errors" "/tmp/nvim_test_$test_name.log" | sed 's/\x1b\[[0-9;]*m//g' | grep -oE '[0-9]+' | tail -1)
        
        # Default to 0 if empty
        failed_count=${failed_count:-0}
        error_count=${error_count:-0}
        
        if [ "$failed_count" != "0" ] 2>/dev/null || [ "$error_count" != "0" ] 2>/dev/null; then
            echo -e "${RED}✗ $test_name failed (Failed: $failed_count, Errors: $error_count)${NC}"
            ((FAILED_TESTS++))
        else
            echo -e "${GREEN}✓ $test_name passed${NC}"
            ((PASSED_TESTS++))
        fi
        echo ""
    else
        echo -e "${YELLOW}⚠ Test file not found: $test_file${NC}"
    fi
done

echo "───────────────────────────────────────────────────────────"
echo "  Test Summary"
echo "───────────────────────────────────────────────────────────"
echo ""
echo "Total tests: $((PASSED_TESTS + FAILED_TESTS))"
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

