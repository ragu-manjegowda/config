#!/usr/bin/env bash

# Smoke tests for AwesomeWM external API integrations
# Tests weather, stocks, and calendar utilities against real endpoints.
# All tests skip gracefully when network or dependencies are unavailable.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWESOME_DIR="$(dirname "$SCRIPT_DIR")"

passed=0
failed=0
skipped=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================="
echo "  API Integration Smoke Tests"
echo "========================================="
echo ""

has_network() {
    curl -sf --connect-timeout 3 --max-time 5 "https://api.open-meteo.com/v1/forecast?latitude=0&longitude=0&current=temperature_2m" >/dev/null 2>&1
}

echo -n "Checking network connectivity... "
if has_network; then
    echo -e "${GREEN}available${NC}"
    NETWORK=true
else
    echo -e "${YELLOW}unavailable (network tests will be skipped)${NC}"
    NETWORK=false
fi
echo ""

# --- Weather: Open-Meteo (no API key required) ---
echo -n "Testing Open-Meteo API... "
if [ "$NETWORK" = false ]; then
    echo -e "${YELLOW}⚠ SKIPPED${NC} (no network)"
    ((skipped++))
else
    RESPONSE=$(curl -sf --connect-timeout 5 --max-time 10 \
        "https://api.open-meteo.com/v1/forecast?latitude=37.3382&longitude=-121.8863&current=temperature_2m,weather_code,is_day&daily=sunrise,sunset&timezone=America/Los_Angeles&forecast_days=1" 2>/dev/null || true)

    if echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'current' in d and 'temperature_2m' in d['current']" 2>/dev/null; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((passed++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  Open-Meteo returned invalid or empty response"
        ((failed++))
    fi
fi

# --- Weather: wttr.in (no API key required) ---
echo -n "Testing wttr.in API... "
if [ "$NETWORK" = false ]; then
    echo -e "${YELLOW}⚠ SKIPPED${NC} (no network)"
    ((skipped++))
else
    RESPONSE=$(curl -sf --connect-timeout 5 --max-time 10 \
        "https://wttr.in/San+Jose?format=j1" 2>/dev/null || true)

    if echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'current_condition' in d" 2>/dev/null; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((passed++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  wttr.in returned invalid or empty response"
        ((failed++))
    fi
fi

# --- Stocks: yfinance via stocks_fetcher.py ---
STOCKS_VENV="$AWESOME_DIR/library/stocks/.venv"
STOCKS_SCRIPT="$AWESOME_DIR/library/stocks/stocks_fetcher.py"

echo -n "Testing stocks fetcher (yfinance)... "
if [ ! -x "$STOCKS_VENV/bin/python3" ]; then
    echo -e "${YELLOW}⚠ SKIPPED${NC} (venv not set up at $STOCKS_VENV)"
    ((skipped++))
elif [ "$NETWORK" = false ]; then
    echo -e "${YELLOW}⚠ SKIPPED${NC} (no network)"
    ((skipped++))
else
    RESPONSE=$("$STOCKS_VENV/bin/python3" "$STOCKS_SCRIPT" "NVDA" 2>/dev/null || true)

    if echo "$RESPONSE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert 'symbol' in d, 'missing symbol'
assert d['symbol'] == 'NVDA', 'wrong symbol'
assert 'error' not in d or d.get('price') is not None, 'got error with no price'
" 2>/dev/null; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((passed++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  stocks_fetcher.py returned invalid response: $RESPONSE"
        ((failed++))
    fi
fi

# --- Outlook Calendar: outlook-calendar utility ---
CALENDAR_SCRIPT="$AWESOME_DIR/utilities/outlook-calendar"
NEOMUTT_DIR="$HOME/.config/neomutt"
OAUTH_SCRIPT="$NEOMUTT_DIR/accounts/work/oauth2.py"
TOKEN_FILE="$NEOMUTT_DIR/credentials/token_outlook_graph"

is_git_crypt_locked() {
    local file="$1"
    [ -f "$file" ] && head -c9 "$file" 2>/dev/null | LC_ALL=C tr -d '\0' | grep -q "GITCRYPT"
}

echo -n "Testing outlook-calendar utility... "
if [ ! -x "$CALENDAR_SCRIPT" ]; then
    echo -e "${RED}✗ FAILED${NC}"
    echo "  $CALENDAR_SCRIPT not found or not executable"
    ((failed++))
elif is_git_crypt_locked "$OAUTH_SCRIPT" || is_git_crypt_locked "$TOKEN_FILE"; then
    echo -e "${YELLOW}⚠ SKIPPED${NC} (oauth2.py or token file is git-crypt locked)"
    ((skipped++))
elif [ ! -f "$TOKEN_FILE" ]; then
    echo -e "${YELLOW}⚠ SKIPPED${NC} (token file not found - run oauth2.py --authorize first)"
    ((skipped++))
elif [ "$NETWORK" = false ]; then
    echo -e "${YELLOW}⚠ SKIPPED${NC} (no network)"
    ((skipped++))
else
    RESPONSE=$("$CALENDAR_SCRIPT" --days 1 2>/dev/null || true)

    if echo "$RESPONSE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert 'ok' in d, 'missing ok field'
if d['ok']:
    assert 'events' in d, 'missing events field'
    assert 'count' in d, 'missing count field'
    assert isinstance(d['events'], list), 'events is not a list'
" 2>/dev/null; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((passed++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  outlook-calendar returned invalid JSON structure"
        ((failed++))
    fi
fi

echo ""
echo "========================================="
echo "  Results: $passed passed, $failed failed, $skipped skipped"
echo "========================================="

if [ $failed -gt 0 ]; then
    exit 1
fi
exit 0
