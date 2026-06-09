# Search Fallback Policy

When websearch/Exa fails, rate-limits, times out, or returns insufficient results, retry with SearXNG before reporting failure.

This applies to web search tool failures only. If an agent fails before searching because its model provider/API key is invalid, do not classify that as an Exa failure. Report the model-provider failure separately, then continue the research with direct tools and SearXNG if web search is still needed.

Prefer this order for general web search:

1. Use Exa/websearch first when available.
2. If Exa/websearch is rate-limited, unavailable, times out, or low quality, use SearXNG.
3. If both fail, report both failures clearly.
