#!/bin/sh

echo "Enter search query:"
read -r query && \
mu find --clearlinks --format=links \
    --linksdir="${XDG_CACHE_HOME}"/mu/search_results "${query}"
