# Design: URL Auto-Scraper Hook

**Date:** 2026-02-23
**Status:** Approved

## Problem

YouTube URLs werden automatisch erkannt und Transkripte extrahiert (yt-transcript.sh), aber generische URLs (Docs, Artikel, APIs) werden ignoriert. Der User muss manuell `/cwe:web-research` aufrufen.

## Solution

Ein neuer UserPromptSubmit Hook `url-scraper.py` der:
- Nicht-YouTube URLs im Prompt erkennt
- Automatisch scrapt (Firecrawl → trafilatura → curl Fallback)
- JSON nach `/tmp/url-scrape-<hash>.json` speichert
- systemMessage mit Titel, Domain und Dateipfad zurückgibt

## Hook: `hooks/scripts/url-scraper.py`

### URL-Erkennung
- Regex: `https?://[^\s]+` (alle URLs im Prompt)
- YouTube-URLs explizit ausschließen (yt-transcript.sh ist zuständig)
- Erste gefundene URL wird gescrapt

### Scraping Fallback-Kette
1. **Firecrawl** — JS-fähig via Playwright, `formats: ["markdown"]`, `onlyMainContent: true`
2. **trafilatura** — Python-Library für statische Seiten, Artikel, News
3. **curl + Python html.parser** — Zero-Dependency Fallback

### Config
Liest `firecrawl_url` aus `.claude/cwe-settings.yml` (Default: `http://localhost:3002`).
Wenn Firecrawl nicht erreichbar → direkt zu trafilatura.

### JSON Output (`/tmp/url-scrape-<hash>.json`)
```json
{
  "url": "https://example.com/article",
  "domain": "example.com",
  "title": "Page Title",
  "content": "Markdown content...",
  "content_length": 4523,
  "method": "firecrawl|trafilatura|curl",
  "scraped_at": "2026-02-23T14:30:00Z"
}
```

### systemMessage
```
[url-scraper] Scraped: "<title>" (<domain>, <length> chars via <method>). Content saved to /tmp/url-scrape-<hash>.json. Read it with the Read tool to see the full content.
```

## Hook Chain Order

```
UserPromptSubmit:
  1. intent-router.py     (routing hints)
  2. url-scraper.py       (auto-scrape non-YouTube URLs) ← NEW
  3. idea-observer.sh     (idea capture)
  4. yt-transcript.sh     (YouTube transcript)
```

## Intent-Router Update

Generische URLs (`https?://` ohne YouTube) werden zu web-research geroutet, aber der Hook scrapt sie bereits automatisch. Kein Konflikt — die systemMessage vom Hook und der Routing-Hint ergänzen sich.

## Decisions

- **Kein neuer Command** — Hook scrapt automatisch, `/cwe:web-research` existiert für manuelle Nutzung
- **Nur erste URL** — Bei mehreren URLs im Prompt wird nur die erste gescrapt
- **YouTube ausgeschlossen** — yt-transcript.sh bleibt zuständig
- **Python (nicht Bash)** — Konsistent mit intent-router.py, bessere JSON-Handhabung
