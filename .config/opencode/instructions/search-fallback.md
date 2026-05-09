# Search Fallback Policy

When websearch/Exa fails, rate-limits, times out, or returns insufficient results, retry with SearXNG before reporting failure.

Prefer this order for general web search:

1. Use Exa/websearch first when available.
2. If Exa/websearch is rate-limited, unavailable, times out, or low quality, use SearXNG.
3. If both fail, report both failures clearly.
