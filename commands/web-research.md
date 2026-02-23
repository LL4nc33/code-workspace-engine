---
description: MUSS VERWENDET WERDEN wenn User etwas im Web suchen, eine Webseite lesen oder Recherche betreiben will. Lokale SearXNG-Suche + Firecrawl/trafilatura Scraping.
allowed-tools: ["Bash", "WebFetch", "WebSearch", "AskUserQuestion"]
---

# Web Research

Suche im Web und scrape Seiten via lokaler SearXNG + Firecrawl/trafilatura.

**Usage:** `/cwe:web-research [query or URL]`

## Prerequisites

URLs werden per-Projekt in `.claude/cwe-settings.yml` konfiguriert:

```yaml
searxng_url: http://localhost:8080
firecrawl_url: http://localhost:3002
```

| Service | Config Key | Required |
|---------|-----------|----------|
| SearXNG | `searxng_url` | Yes — lokale Metasearch |
| Firecrawl | `firecrawl_url` | Optional — JS-fähiges Scraping |
| trafilatura | Python library | Fallback — immer verfügbar |

## Interactive Mode (keine Argumente)

Wenn User `/cwe:web-research` ohne Argumente aufruft, frage mit AskUserQuestion:

```
Question: "Was möchtest du recherchieren?"
Header: "Research"
Options:
  1. "Web-Suche" - Informationen zu einem Thema finden (Recommended)
  2. "Webseite lesen" - Eine bestimmte URL scrapen und zusammenfassen
  3. "Suche + Deep Read" - Suchen, dann Top-Ergebnisse scrapen
```

## Direct Mode (mit Argumenten)

- **URL erkannt** (http/https): Direkt scrapen
- **Sonst**: SearXNG-Suche mit dem Query

## SearXNG Search (JSON)

```bash
curl -s "${SEARXNG_URL}/search?q=QUERY&format=json&language=de" | python3 -c "
import sys, json
data = json.load(sys.stdin)
results = [{'title': r.get('title',''), 'url': r.get('url',''), 'snippet': r.get('content','')[:200]}
           for r in data.get('results', [])[:10]]
print(json.dumps({'query': 'QUERY', 'count': len(results), 'results': results}, ensure_ascii=False, indent=2))
"
```

### Search Parameters

| Param | Default | Description |
|-------|---------|-------------|
| `q` | required | Search query (URL-encoded) |
| `format` | `json` | Immer `json` verwenden |
| `language` | `de` | `de`, `en`, `all` |
| `safesearch` | `1` | 0=off, 1=moderate, 2=strict |
| `engines` | all | `google,bing,duckduckgo` |
| `categories` | all | `general`, `news`, `images`, `videos`, `science` |
| `time_range` | none | `day`, `week`, `month`, `year` |

### Tips
- Current events: `&time_range=week` oder `&categories=news`
- English results: `&language=en`
- URL-encode Spaces als `+`

## Scraping Pages

### Option 1: Firecrawl (JSON-nativ, JS-fähig)

Best für JS-heavy Sites. Verfügbarkeit prüfen:

```bash
curl -s -X POST "${FIRECRAWL_URL}/v1/scrape" \
  -H "Content-Type: application/json" \
  -d '{"url":"URL_HERE","formats":["markdown"],"onlyMainContent":true}' | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data.get('success'):
    result = {'url': 'URL_HERE', 'success': True, 'content': data['data'].get('markdown', '')[:5000], 'error': None}
else:
    result = {'url': 'URL_HERE', 'success': False, 'content': '', 'error': data.get('error', 'Unknown')}
print(json.dumps(result, ensure_ascii=False, indent=2))
"
```

#### Firecrawl API Reference

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/scrape` | POST | Single URL scrape |
| `/v1/crawl` | POST | Multi-page crawl |
| `/v1/map` | POST | Sitemap/URL discovery |

Body: `{"url": "...", "formats": ["markdown"], "onlyMainContent": true, "waitFor": 2000}`

### Option 2: trafilatura (JSON, Fallback)

Statische Seiten, Artikel, News:

```bash
python3 -c "
import json, trafilatura
url = 'URL_HERE'
d = trafilatura.fetch_url(url)
text = trafilatura.extract(d, include_tables=True) if d else None
print(json.dumps({'url': url, 'success': bool(text), 'content': (text or '')[:5000], 'error': None if text else 'No content extracted'}, ensure_ascii=False, indent=2))
"
```

### Option 3: curl + trafilatura (JSON, robust)

```bash
curl -sL -H "User-Agent: Mozilla/5.0" "URL_HERE" | python3 -c "
import sys, json, trafilatura
html = sys.stdin.read()
text = trafilatura.extract(html, include_tables=True)
print(json.dumps({'url': 'URL_HERE', 'success': bool(text), 'content': (text or '')[:5000], 'error': None if text else 'No content'}, ensure_ascii=False, indent=2))
"
```

### Option 4: WebFetch Tool (last resort)

Falls SearXNG und Firecrawl nicht erreichbar, `WebFetch` oder `WebSearch` Tool direkt verwenden.

## Workflow: Search + Scrape + Analyze

```bash
# 1. Suche → JSON
curl -s "${SEARXNG_URL}/search?q=claude+code+plugins&format=json&language=en" | python3 -c "
import sys, json
results = json.load(sys.stdin).get('results', [])[:5]
for r in results:
    print(r['url'])
" > /tmp/urls.txt

# 2. Scrape top results → JSON pro URL
while read url; do
  python3 -c "
import json, trafilatura
d = trafilatura.fetch_url('$url')
text = trafilatura.extract(d, include_tables=True) if d else None
print(json.dumps({'url': '$url', 'success': bool(text), 'content': (text or '')[:3000]}, ensure_ascii=False))
"
done < /tmp/urls.txt
```

## Output

Immer liefern:
- Strukturierte Zusammenfassung der Ergebnisse
- Quellen-URLs zur Verifikation
- Key Facts hervorgehoben
- Angebot zum Vertiefen
