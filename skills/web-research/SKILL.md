---
name: web-research
description: >
  Use PROACTIVELY when you need to search the web or read/scrape any webpage.
  Provides local SearXNG search and Firecrawl/trafilatura web scraping.
  Use this instead of WebSearch/WebFetch when those tools fail or for better results.
allowed-tools: ["Bash", "Read", "WebSearch", "WebFetch"]
---

# Web Research — SearXNG + Scraping

Local self-hosted web search and scraping for research tasks.

## Configuration

URLs are configured per-project in `.claude/cwe-settings.yml`:

```yaml
searxng_url: http://localhost:8080    # Your SearXNG instance
firecrawl_url: http://localhost:3002  # Your Firecrawl instance (optional)
```

If not configured, defaults: `SEARXNG_URL=http://localhost:8080`, `FIRECRAWL_URL=http://localhost:3002`

## Services

| Service | Config Key | Purpose | Status |
|---------|-----------|---------|--------|
| SearXNG | `searxng_url` | Web search (metasearch) | Primary |
| Firecrawl | `firecrawl_url` | JS-capable scraping | Optional (may be offline) |
| trafilatura | Python library | Static page scraping | Fallback (always available) |

## When to Use

- Web search for facts, current events, verification
- Reading full articles, documentation, reports
- When `WebSearch` or `WebFetch` fail or return incomplete results
- Research tasks that need multiple sources

## SearXNG Search

```bash
curl -s "${SEARXNG_URL}/search?q=QUERY&format=json&language=de" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for i, r in enumerate(data.get('results', [])[:10], 1):
    print(f\"{i}. {r.get('title', '?')}\")
    print(f\"   {r.get('url', '')}\")
    s = r.get('content', '')[:120]
    if s: print(f\"   {s}\")
    print()
"
```

### Search Parameters

| Param | Default | Description |
|-------|---------|-------------|
| `q` | required | Search query (URL-encoded) |
| `format` | `json` | Always use `json` |
| `language` | `de` | `de`, `en`, `all` |
| `safesearch` | `1` | 0=off, 1=moderate, 2=strict |
| `engines` | all | `google,bing,duckduckgo` |
| `categories` | all | `general`, `news`, `images`, `videos`, `science` |
| `time_range` | none | `day`, `week`, `month`, `year` |

### Tips
- Current events: `&time_range=week` or `&categories=news`
- English results: `&language=en`
- URL-encode spaces as `+`

## Scraping Pages

### Option 1: Firecrawl (if available)

Best for JS-heavy sites. Test availability first:

```bash
curl -s -X POST "${FIRECRAWL_URL}/v1/scrape" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com","formats":["markdown"],"onlyMainContent":true}' | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data.get('success'):
    print(data['data'].get('markdown', '')[:5000])
else:
    print('ERROR:', data.get('error', 'Unknown'))
"
```

### Option 2: trafilatura (always available, fallback)

Works for static pages, articles, news sites:

```bash
python3 -c "
import trafilatura
url = 'https://example.com/article'
downloaded = trafilatura.fetch_url(url)
if downloaded:
    text = trafilatura.extract(downloaded, include_tables=True, include_links=False)
    if text:
        print(text[:5000])
    else:
        print('ERROR: No content extracted')
else:
    print('ERROR: Could not fetch URL')
"
```

### Option 3: curl + trafilatura (most reliable)

```bash
curl -sL -H "User-Agent: Mozilla/5.0" "URL_HERE" | python3 -c "
import sys, trafilatura
html = sys.stdin.read()
text = trafilatura.extract(html, include_tables=True)
print(text[:5000] if text else 'ERROR: No content')
"
```

## Workflow: Search + Scrape + Analyze

```bash
# 1. Search (URLs into a temp file, no fixed /tmp path)
URLS=$(mktemp "${TMPDIR:-/tmp}/cwe-urls-XXXXXX")
curl -s "${SEARXNG_URL}/search?q=claude+code+plugins&format=json&language=en" | python3 -c "
import sys, json
results = json.load(sys.stdin).get('results', [])[:5]
for r in results:
    print(r['url'])
" > "$URLS"

# 2. Scrape top results (URL via argv — never interpolate it into the source)
while read -r url; do
  echo "=== $url ==="
  python3 -c "
import sys, trafilatura
d = trafilatura.fetch_url(sys.argv[1])
if d:
    t = trafilatura.extract(d, include_tables=True)
    if t: print(t[:3000])
" "$url"
done < "$URLS"
rm -f "$URLS"
```

## Firecrawl API Reference (when available)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/scrape` | POST | Single URL scrape |
| `/v1/crawl` | POST | Multi-page crawl |
| `/v1/map` | POST | Sitemap/URL discovery |

Scrape body: `{"url": "...", "formats": ["markdown"], "onlyMainContent": true, "waitFor": 2000}`

## Notes

- SearXNG: local network, no auth, no rate limits
- Firecrawl: may be offline — always try trafilatura as fallback
- For YouTube/video/audio URLs: use `/cwe:transcript` instead
- trafilatura: `pip install trafilatura` if not installed
