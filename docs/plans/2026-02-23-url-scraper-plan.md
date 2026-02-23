# URL Auto-Scraper Hook Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Automatically scrape non-YouTube URLs found in user prompts and provide the content as JSON for Claude to read.

**Architecture:** Python UserPromptSubmit hook that detects URLs, scrapes via Firecrawl → trafilatura → curl fallback chain, saves JSON to /tmp, returns systemMessage with summary.

**Tech Stack:** Python 3 stdlib + trafilatura (installed) + Firecrawl API (optional, via cwe-settings.yml)

---

### Task 1: Create url-scraper.py hook

**Files:**
- Create: `hooks/scripts/url-scraper.py`

**Step 1: Create the hook script**

```python
#!/usr/bin/env python3
"""CWE URL Scraper — UserPromptSubmit hook.

Detects non-YouTube URLs in user prompts, scrapes content via
Firecrawl → trafilatura → curl fallback, saves JSON to /tmp.
"""

import hashlib
import json
import re
import sys
import urllib.request
import urllib.error
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path


# YouTube patterns to exclude (handled by yt-transcript.sh)
YT_PATTERN = re.compile(
    r"https?://(www\.)?(youtube\.com|youtu\.be|m\.youtube\.com)/"
)

# URL pattern — match http/https URLs in prompt
URL_PATTERN = re.compile(r"https?://[^\s\)\]\}>\"']+")


def extract_prompt(stdin_data):
    """Extract user prompt from hook stdin JSON."""
    try:
        data = json.loads(stdin_data)
        return data.get("message", data.get("prompt", ""))
    except (json.JSONDecodeError, AttributeError):
        return stdin_data.strip()


def find_url(prompt):
    """Find first non-YouTube URL in prompt."""
    urls = URL_PATTERN.findall(prompt)
    for url in urls:
        # Clean trailing punctuation
        url = url.rstrip(".,;:!?")
        if not YT_PATTERN.match(url):
            return url
    return None


def get_firecrawl_url():
    """Read Firecrawl URL from cwe-settings.yml."""
    settings_paths = [
        Path(".claude/cwe-settings.yml"),
        Path.home() / ".claude" / "cwe-settings.yml",
    ]
    for path in settings_paths:
        if path.exists():
            try:
                text = path.read_text()
                match = re.search(r"firecrawl_url:\s*(\S+)", text)
                if match:
                    return match.group(1)
            except Exception:
                pass
    return "http://localhost:3002"


def scrape_firecrawl(url, firecrawl_url):
    """Scrape via Firecrawl API. Returns (content, title) or (None, None)."""
    try:
        payload = json.dumps({
            "url": url,
            "formats": ["markdown"],
            "onlyMainContent": True,
            "waitFor": 2000,
        }).encode("utf-8")
        req = urllib.request.Request(
            f"{firecrawl_url}/v1/scrape",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            result = json.loads(resp.read().decode("utf-8"))
        if result.get("success"):
            data = result.get("data", {})
            content = data.get("markdown", "")
            title = data.get("metadata", {}).get("title", "")
            return content, title
    except Exception:
        pass
    return None, None


def scrape_trafilatura(url):
    """Scrape via trafilatura. Returns (content, title) or (None, None)."""
    try:
        import trafilatura
        downloaded = trafilatura.fetch_url(url)
        if downloaded:
            content = trafilatura.extract(
                downloaded, include_tables=True, include_links=False
            )
            # Try to get title from HTML
            title = ""
            match = re.search(r"<title[^>]*>([^<]+)</title>", downloaded, re.IGNORECASE)
            if match:
                import html
                title = html.unescape(match.group(1)).strip()
            if content:
                return content, title
    except Exception:
        pass
    return None, None


class TitleParser(HTMLParser):
    """Minimal HTML parser to extract <title>."""
    def __init__(self):
        super().__init__()
        self._in_title = False
        self.title = ""

    def handle_starttag(self, tag, attrs):
        if tag.lower() == "title":
            self._in_title = True

    def handle_data(self, data):
        if self._in_title:
            self.title += data

    def handle_endtag(self, tag):
        if tag.lower() == "title":
            self._in_title = False


def scrape_curl(url):
    """Scrape via urllib + basic HTML stripping. Returns (content, title) or (None, None)."""
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        })
        with urllib.request.urlopen(req, timeout=10) as resp:
            html_bytes = resp.read()
            html_text = html_bytes.decode("utf-8", errors="replace")

        # Extract title
        parser = TitleParser()
        parser.feed(html_text)
        title = parser.title.strip()

        # Strip HTML tags for basic text extraction
        text = re.sub(r"<script[^>]*>.*?</script>", "", html_text, flags=re.DOTALL | re.IGNORECASE)
        text = re.sub(r"<style[^>]*>.*?</style>", "", text, flags=re.DOTALL | re.IGNORECASE)
        text = re.sub(r"<[^>]+>", " ", text)
        text = re.sub(r"\s+", " ", text).strip()
        import html as html_mod
        text = html_mod.unescape(text)

        if len(text) > 100:
            return text, title
    except Exception:
        pass
    return None, None


def scrape(url):
    """Try all scraping methods in order. Returns result dict."""
    firecrawl_url = get_firecrawl_url()

    # Method 1: Firecrawl
    content, title = scrape_firecrawl(url, firecrawl_url)
    if content:
        return {"content": content[:10000], "title": title, "method": "firecrawl"}

    # Method 2: trafilatura
    content, title = scrape_trafilatura(url)
    if content:
        return {"content": content[:10000], "title": title, "method": "trafilatura"}

    # Method 3: curl + HTML strip
    content, title = scrape_curl(url)
    if content:
        return {"content": content[:10000], "title": title, "method": "curl"}

    return None


def url_hash(url):
    """Short hash for temp file naming."""
    return hashlib.md5(url.encode()).hexdigest()[:10]


def domain(url):
    """Extract domain from URL."""
    match = re.search(r"https?://([^/]+)", url)
    return match.group(1) if match else "unknown"


def main():
    stdin_data = sys.stdin.read()
    prompt = extract_prompt(stdin_data)

    if not prompt:
        print(json.dumps({}))
        return

    url = find_url(prompt)
    if not url:
        print(json.dumps({}))
        return

    result = scrape(url)
    if not result:
        print(json.dumps({}))
        return

    # Build output JSON
    output = {
        "url": url,
        "domain": domain(url),
        "title": result.get("title", ""),
        "content": result["content"],
        "content_length": len(result["content"]),
        "method": result["method"],
        "scraped_at": datetime.now(timezone.utc).isoformat(),
    }

    # Save to /tmp
    temp_file = f"/tmp/url-scrape-{url_hash(url)}.json"
    with open(temp_file, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    # Build systemMessage
    title = result.get("title", domain(url)) or domain(url)
    length = len(result["content"])
    method = result["method"]
    msg = (
        f"[url-scraper] Scraped: \"{title}\" ({domain(url)}, {length} chars via {method}). "
        f"Content saved to {temp_file}. Read it with the Read tool to see the full content."
    )

    print(json.dumps({"systemMessage": msg}))


if __name__ == "__main__":
    main()
```

**Step 2: Make executable**

```bash
chmod +x hooks/scripts/url-scraper.py
```

**Step 3: Smoke test — generic URL**

```bash
echo '{"message":"schau dir mal https://httpbin.org/html an"}' | python3 hooks/scripts/url-scraper.py
```

Expected: JSON with systemMessage containing `[url-scraper] Scraped:` and a `/tmp/url-scrape-*.json` path.

**Step 4: Smoke test — YouTube URL should be skipped**

```bash
echo '{"message":"https://www.youtube.com/watch?v=abc123"}' | python3 hooks/scripts/url-scraper.py
```

Expected: `{}` (empty — YouTube handled by yt-transcript.sh)

**Step 5: Smoke test — no URL**

```bash
echo '{"message":"fix the login bug"}' | python3 hooks/scripts/url-scraper.py
```

Expected: `{}` (no URL found)

**Step 6: Verify saved JSON**

```bash
cat /tmp/url-scrape-*.json | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'OK: {d[\"domain\"]} — {d[\"content_length\"]} chars via {d[\"method\"]}')"
```

**Step 7: Commit**

```bash
git add hooks/scripts/url-scraper.py
git commit -m "feat: add url-scraper hook for auto-scraping non-YouTube URLs"
```

---

### Task 2: Register hook in hooks.json

**Files:**
- Modify: `hooks/hooks.json`

**Step 1: Add url-scraper.py AFTER intent-router, BEFORE idea-observer**

In the `UserPromptSubmit` hooks array, insert after the intent-router entry:

```json
{
  "type": "command",
  "command": "python3 ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/url-scraper.py",
  "timeout": 20
}
```

Note: timeout is 20s (longer than intent-router's 3s) because scraping needs network time.

**Step 2: Verify hooks.json is valid JSON**

```bash
python3 -c "import json; json.load(open('hooks/hooks.json')); print('Valid JSON')"
```

**Step 3: Commit**

```bash
git add hooks/hooks.json
git commit -m "feat: register url-scraper in UserPromptSubmit hooks"
```

---

### Task 3: Update intent-router for generic URLs

**Files:**
- Modify: `hooks/scripts/intent-router.py`

**Step 1: Add URL detection to UTILITIES list**

In the `UTILITIES` list in intent-router.py, add a new entry BEFORE the existing `web-research` entry:

```python
{
    "command": "url-scraper",
    "patterns": [
        r"https?://(?!.*(youtube\.com|youtu\.be)/)\S+",  # any non-YouTube URL
    ],
    "hook_handled": True,  # url-scraper hook already handles this
},
```

Note: The `hook_handled` flag means the intent-router should NOT produce a routing systemMessage for this — the url-scraper hook already scraped the URL. We just need to suppress the router from routing it to `builder` or `researcher` by accident.

**Step 2: Update the `match_utility` function to handle `hook_handled`**

In the `route()` function, after `utility = match_utility(prompt)`, check for `hook_handled`:

The match_utility function should return the full entry dict (not just command name), and route() should check for hook_handled:

```python
def match_utility(prompt):
    """Check if prompt matches a utility command. Returns entry dict or None."""
    prompt_lower = prompt.lower()
    for entry in UTILITIES:
        for pattern in entry["patterns"]:
            if re.search(pattern, prompt_lower):
                return entry
    return None
```

And in route():
```python
utility = match_utility(prompt)
if utility:
    if utility.get("hook_handled"):
        return None  # Another hook handles this, don't route
    return {
        "agent": utility["command"],
        "utility": True,
        "matched": [utility["command"]],
        "reason": f"Utility command matched: {utility['command']}",
    }
```

**Step 3: Smoke test — generic URL should not route**

```bash
echo '{"message":"schau dir https://example.com an"}' | python3 hooks/scripts/intent-router.py
```

Expected: `{}` (url-scraper hook handles it, not the router)

**Step 4: Smoke test — youtube still routes to yt-transcript**

```bash
echo '{"message":"https://www.youtube.com/watch?v=abc123"}' | python3 hooks/scripts/intent-router.py
```

Expected: systemMessage with `yt-transcript`

**Step 5: Smoke test — web-search keywords still route**

```bash
echo '{"message":"suche im web nach React"}' | python3 hooks/scripts/intent-router.py
```

Expected: systemMessage with `web-research`

**Step 6: Commit**

```bash
git add hooks/scripts/intent-router.py
git commit -m "feat: intent-router skips URLs handled by url-scraper hook"
```

---

### Task 4: Update CHANGELOG + docs

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `docs/ARCHITECTURE.md`

**Step 1: Add to CHANGELOG under [0.6.1] section — or create [0.6.2] if already committed**

```markdown
### Added
- `hooks/scripts/url-scraper.py`: Auto-scrapes non-YouTube URLs in user prompts (Firecrawl → trafilatura → curl fallback)
- Intent-router: Generic URLs now suppressed from false agent routing

### Changed
- Hook chain order: intent-router → url-scraper → idea-observer → yt-transcript
```

**Step 2: Update ARCHITECTURE.md hook table**

Add `url-scraper.py` entry to the Hook Events table:

```markdown
| `UserPromptSubmit` | User sends a message | `url-scraper.py` — auto-scrapes non-YouTube URLs (Firecrawl → trafilatura → curl) |
```

**Step 3: Commit**

```bash
git add CHANGELOG.md docs/ARCHITECTURE.md
git commit -m "docs: add url-scraper to changelog and architecture"
```

---

### Task 5: End-to-end verification

**Step 1: Test full hook chain with generic URL**

```bash
echo '{"message":"schau dir https://httpbin.org/html an"}' | python3 hooks/scripts/url-scraper.py
```

Verify: systemMessage returned with scraped content path.

**Step 2: Verify JSON file was created and is valid**

```bash
ls -la /tmp/url-scrape-*.json
python3 -c "import json,glob; f=glob.glob('/tmp/url-scrape-*.json')[0]; d=json.load(open(f)); print(json.dumps({k:v for k,v in d.items() if k!='content'}, indent=2))"
```

**Step 3: Test that YouTube URLs are still handled by yt-transcript**

```bash
echo '{"message":"https://www.youtube.com/watch?v=abc123"}' | python3 hooks/scripts/url-scraper.py
```

Expected: `{}`

**Step 4: Test intent-router doesn't double-route URLs**

```bash
echo '{"message":"lies https://example.com"}' | python3 hooks/scripts/intent-router.py
```

Expected: `{}`

**Step 5: Clean up test files**

```bash
rm -f /tmp/url-scrape-*.json
```
