#!/bin/bash
# Fetch stock data using yfinance from the shared managed venv.

CONFIG_DIR="${HOME}/.config/awesome"
STOCKS_DIR="${CONFIG_DIR}/library/stocks"
VENV_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/venv"
PYTHON_SCRIPT="${STOCKS_DIR}/stocks_fetcher.py"

STOCK_SYMBOL="${1}"

if [ -z "$STOCK_SYMBOL" ]; then
    echo '{"error": "Usage: stocks_fetcher.sh SYMBOL"}'
    exit 1
fi

if [ ! -x "$VENV_DIR/bin/python" ]; then
    echo '{"error": "shared Python venv is unavailable", "hint": "Run the bootstrap script"}'
    exit 1
fi

# Run the Python script and get results
"$VENV_DIR/bin/python" "$PYTHON_SCRIPT" "$STOCK_SYMBOL"
