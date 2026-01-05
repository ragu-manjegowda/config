#!/bin/bash
# Neovim Configuration Test Runner
# Author       : Ragu Manjegowda
# Github       : @ragu-manjegowda
#
# Usage:
#   ./run_all_tests.sh              # Run all tests (respects .testignore)
#   ./run_all_tests.sh <testfile>   # Run specific test file
#   ./run_all_tests.sh --all        # Run all tests (ignore blacklist)
#
# Blacklist:
#   Create .testignore in tests/ directory with one filename per line
#   to exclude tests from running (e.g., remote_nvim_spec.lua)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
BLACKLIST_FILE="$SCRIPT_DIR/.testignore"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Neovim Plugin Configuration Tests${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
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

# Check if plenary.nvim is available in lazy or vendor path
check_plenary() {
    local lazy_plenary="$HOME/.local/share/nvim/lazy/plenary.nvim"
    local vendor_plenary="$HOME/.local/share/nvim/site/pack/vendor/start/plenary.nvim"

    if [ -d "$lazy_plenary" ] || [ -d "$vendor_plenary" ]; then
        return 0
    fi
    return 1
}

echo "Checking dependencies..."
if ! check_plenary; then
    echo -e "${YELLOW}⚠ plenary.nvim not found, installing...${NC}"
    PLENARY_PATH="$HOME/.local/share/nvim/site/pack/vendor/start/plenary.nvim"
    mkdir -p "$(dirname "$PLENARY_PATH")"
    git clone --depth=1 https://github.com/nvim-lua/plenary.nvim "$PLENARY_PATH"
    echo -e "${GREEN}✓ plenary.nvim installed${NC}"
else
    echo -e "${GREEN}✓ plenary.nvim found${NC}"
fi

echo ""
echo -e "${BLUE}───────────────────────────────────────────────────────────${NC}"
echo -e "${BLUE}  Running Tests${NC}"
echo -e "${BLUE}───────────────────────────────────────────────────────────${NC}"
echo ""

# If specific test file provided
if [ -n "$1" ] && [ "$1" != "--all" ]; then
    TEST_FILE="$1"
    if [[ ! "$TEST_FILE" == tests/* ]]; then
        TEST_FILE="tests/$TEST_FILE"
    fi
    echo "Running specific test: $TEST_FILE"
    cd "$NVIM_CONFIG_DIR"
    nvim --headless -u tests/minimal_init.lua \
        -c "PlenaryBustedFile $TEST_FILE"
    exit_code=$?
else
    # Check for blacklist and --all flag
    IGNORE_BLACKLIST=false
    if [ "$1" == "--all" ]; then
        IGNORE_BLACKLIST=true
        echo -e "${YELLOW}Ignoring blacklist (--all flag)${NC}"
    fi

    # Handle blacklist
    if [ -f "$BLACKLIST_FILE" ] && [ "$IGNORE_BLACKLIST" == "false" ]; then
        echo -e "${YELLOW}Found blacklist file: $BLACKLIST_FILE${NC}"
        echo "Blacklisted tests:"
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            echo -e "  ${RED}✗ $line${NC}"
        done < "$BLACKLIST_FILE"
        echo ""

        # Create temp directory with filtered tests
        TEMP_TEST_DIR=$(mktemp -d)
        trap "rm -rf $TEMP_TEST_DIR" EXIT

        # Copy init and helpers
        cp "$SCRIPT_DIR/minimal_init.lua" "$TEMP_TEST_DIR/"
        cp "$SCRIPT_DIR/helpers.lua" "$TEMP_TEST_DIR/" 2>/dev/null || true

        # Copy non-blacklisted test files
        echo "Tests to run:"
        for test_file in "$SCRIPT_DIR"/*_spec.lua; do
            filename=$(basename "$test_file")
            if ! grep -qxF "$filename" "$BLACKLIST_FILE"; then
                cp "$test_file" "$TEMP_TEST_DIR/"
                echo -e "  ${GREEN}✓ $filename${NC}"
            fi
        done
        echo ""

        cd "$TEMP_TEST_DIR"
        nvim --headless -u minimal_init.lua \
            -c "PlenaryBustedDirectory . {minimal_init = 'minimal_init.lua', sequential = true}"
        exit_code=$?
    else
        # Run all tests
        echo "Running all tests..."
        cd "$NVIM_CONFIG_DIR"
        nvim --headless -u tests/minimal_init.lua \
            -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua', sequential = true}"
        exit_code=$?
    fi
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}  TESTS COMPLETED${NC}"
else
    echo -e "${RED}  TESTS FAILED${NC}"
fi
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

exit $exit_code
