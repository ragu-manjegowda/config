#!/usr/bin/env python3

"""Stock data fetcher using yfinance.

Outputs JSON to stdout for Awesome WM widget consumption
"""

import json
import sys


def fetch_stock_data(stock_symbol):
    """Fetch stock data from Yahoo Finance using yfinance."""
    try:
        # Available in venv
        import yfinance as yf  # noqa: None
    except ImportError:
        return {
            "error": "yfinance not installed",
            "hint": "Run ~/.config/awesome/library/stocks/stocks_fetcher.sh",
        }

    try:
        # Fetch ticker data
        ticker = yf.Ticker(stock_symbol)
        info = ticker.info

        if not info:
            return {"error": "No data available for symbol"}

        current_price = info.get("currentPrice") or info.get("regularMarketPrice")
        change = info.get("regularMarketChange", 0)
        change_percent = info.get("regularMarketChangePercent", 0)

        # Determine market status
        market_state = info.get("marketState", "CLOSED")
        is_market_open = market_state == "REGULAR"
        market_status = "Market Open" if is_market_open else "Market Closed"

        # Get pre/post market info if available
        premarket_price = info.get("preMarketPrice")
        postmarket_price = info.get("postMarketPrice")

        result = {
            "symbol": stock_symbol,
            "price": float(current_price) if current_price else None,
            "change": round(float(change), 2) if change else 0,
            "change_percent": (
                round(float(change_percent), 2) if change_percent else 0
            ),
            "status": market_status,
            "premarket": float(premarket_price) if premarket_price else None,
            "postmarket": float(postmarket_price) if postmarket_price else None,
        }

        return result

    except Exception as e:
        return {"error": str(e), "symbol": stock_symbol}


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: stocks_fetcher.py SYMBOL"}))
        sys.exit(1)

    stock_symbol = sys.argv[1]
    result = fetch_stock_data(stock_symbol)
    print(json.dumps(result))
