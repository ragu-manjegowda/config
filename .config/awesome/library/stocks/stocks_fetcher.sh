#!/bin/bash
# Fetch stocks data using yfinance via local venv
# Setup venv if needed, then fetch stock data

CONFIG_DIR="${HOME}/.config/awesome"
STOCKS_DIR="${CONFIG_DIR}/library/stocks"
VENV_DIR="${STOCKS_DIR}/.venv"
PYTHON_SCRIPT="${STOCKS_DIR}/stocks_fetcher.py"

STOCK_SYMBOL="${1}"

if [ -z "$STOCK_SYMBOL" ]; then
    echo '{"error": "Usage: stocks_fetcher.sh SYMBOL"}'
    exit 1
fi

# Create venv if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    mkdir -p "$STOCKS_DIR"
    python3 -m venv "$VENV_DIR" 2>/dev/null
    "$VENV_DIR/bin/pip" install -q --upgrade pip 2>/dev/null
    "$VENV_DIR/bin/pip" install -q yfinance 2>/dev/null
fi

# Run the Python script and get results
"$VENV_DIR/bin/python3" "$PYTHON_SCRIPT" "$STOCK_SYMBOL"
