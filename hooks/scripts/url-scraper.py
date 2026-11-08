#!/usr/bin/env python3
"""CWE URL Scraper — UserPromptSubmit hook.

Detects non-YouTube URLs in user prompts, scrapes content via
Firecrawl → trafilatura → curl fallback, saves JSON to the system temp dir.
"""

import hashlib
import ipaddress
import json
import re
import socket
import sys
import tempfile
import urllib.request
import urllib.error
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse


# YouTube patterns to exclude (handled by transcript.sh)
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


def autoscrape_enabled():
    """Auto-scraping is OPT-IN. Enable with `url_autoscrape: true` in
    .claude/cwe-settings.yml (project or ~/.claude). Default: disabled, so the
    hook never silently ships prompt URLs to a scraper without consent."""
    for path in (Path(".claude/cwe-settings.yml"),
                 Path.home() / ".claude" / "cwe-settings.yml"):
        try:
            if path.exists():
                if re.search(r"url_autoscrape:\s*(true|yes|on|1)\b",
                             path.read_text(), re.IGNORECASE):
                    return True
        except Exception:
            pass
    return False


def is_public_url(url):
    """SSRF guard: allow only http(s) hosts that resolve to public addresses.
    Rejects loopback, private, link-local (incl. 169.254.169.254 cloud
    metadata), reserved, multicast and unspecified targets."""
    try:
        parsed = urlparse(url)
        if parsed.scheme not in ("http", "https") or not parsed.hostname:
            return False
        port = parsed.port or (443 if parsed.scheme == "https" else 80)
        for info in socket.getaddrinfo(parsed.hostname, port,
                                       proto=socket.IPPROTO_TCP):
            ip = ipaddress.ip_address(info[4][0])
            if (ip.is_private or ip.is_loopback or ip.is_link_local
                    or ip.is_reserved or ip.is_multicast or ip.is_unspecified):
                return False
        return True
    except Exception:
        return False


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
        with urllib.request.urlopen(req, timeout=10) as resp:
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
        with urllib.request.urlopen(req, timeout=5) as resp:
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

    # Opt-in only (see autoscrape_enabled): no setting → do nothing.
    if not autoscrape_enabled():
        print(json.dumps({}))
        return

    url = find_url(prompt)
    if not url:
        print(json.dumps({}))
        return

    # SSRF guard: never fetch internal / metadata addresses.
    if not is_public_url(url):
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

    # Save to the system temp dir (/tmp on Linux/WSL, %TEMP% on Windows)
    temp_file = str(Path(tempfile.gettempdir()) / f"url-scrape-{url_hash(url)}.json")
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

    # additionalContext so Claude actually learns the content was fetched.
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": msg,
        }
    }))


if __name__ == "__main__":
    main()
