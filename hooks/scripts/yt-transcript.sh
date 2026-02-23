#!/usr/bin/env bash
# Detect YouTube URLs in user prompt and auto-fetch transcript + metadata.
# Returns systemMessage with JSON data so Claude has the transcript in context.

source "$(dirname "$0")/_lib.sh"

# Read user prompt from stdin
PROMPT=$(cat)

# Check for YouTube URL patterns
YT_URL=$(echo "$PROMPT" | grep -oE 'https?://(www\.)?(youtube\.com/watch\?v=|youtu\.be/|youtube\.com/shorts/)[a-zA-Z0-9_-]+' | head -1)

if [ -z "$YT_URL" ]; then
  exit 0
fi

# Extract video ID
VIDEO_ID=$(echo "$YT_URL" | grep -oE '[a-zA-Z0-9_-]{11}' | tail -1)

if [ -z "$VIDEO_ID" ]; then
  exit 0
fi

# Fetch transcript via inline Python (no external dependencies)
RESULT=$(python3 -c '
import sys, re, json, html, time, urllib.request, urllib.error

vid = sys.argv[1]

# Metadata
meta = {"title": "Video", "channel": "Unknown", "views": 0, "duration": None, "upload_date": None}
try:
    req = urllib.request.Request(f"https://www.youtube.com/watch?v={vid}", headers={
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept-Language": "en-US,en;q=0.9",
    })
    with urllib.request.urlopen(req, timeout=15) as resp:
        h = resp.read().decode("utf-8", errors="replace")
    t = re.search(r"<title>([^<]+)</title>", h)
    if t: meta["title"] = html.unescape(t.group(1).replace(" - YouTube", ""))
    c = re.search(r"\"author\":\"([^\"]+)\"", h)
    if c: meta["channel"] = html.unescape(c.group(1))
    v = re.search(r"\"viewCount\":\"(\d+)\"", h)
    if v: meta["views"] = int(v.group(1))
    l = re.search(r"\"lengthSeconds\":\"(\d+)\"", h)
    if l:
        s = int(l.group(1))
        hr, mi, se = s // 3600, (s % 3600) // 60, s % 60
        meta["duration"] = f"{hr}:{mi:02d}:{se:02d}" if hr else f"{mi}:{se:02d}"
    u = re.search(r"\"uploadDate\":\"([^\"]+)\"", h) or re.search(r"\"publishDate\":\"([^\"]+)\"", h)
    if u: meta["upload_date"] = u.group(1)[:10]
except: pass

# Transcript
transcript, error = None, None
elapsed = 0
while elapsed < 30:
    try:
        data = json.dumps({"video_id": vid}).encode("utf-8")
        req = urllib.request.Request("https://yt-to-text.com/api/v1/Subtitles", data=data, headers={
            "Content-Type": "application/json",
            "Origin": "https://www.tubetranscript.com",
            "Referer": "https://www.tubetranscript.com/",
            "User-Agent": "Mozilla/5.0",
        }, method="POST")
        with urllib.request.urlopen(req, timeout=15) as resp:
            result = json.loads(resp.read().decode("utf-8"))
        status = result.get("status", "")
        if status == "READY":
            transcripts = result.get("data", {}).get("transcripts", [])
            if transcripts:
                parts = [seg.get("t", "").strip() for seg in transcripts if seg.get("t")]
                transcript = re.sub(r"\s+", " ", " ".join(parts)).strip()
            else:
                error = "Empty transcript"
            break
        elif status in ("PROCESSING", "PENDING", ""):
            time.sleep(3); elapsed += 3
        elif status in ("ERROR", "NO_TRANSCRIPT"):
            error = "No transcript available"; break
        else:
            time.sleep(3); elapsed += 3
    except Exception as e:
        error = str(e); break

if elapsed >= 30 and not transcript:
    error = "Timeout after 30s"

print(json.dumps({
    "video_id": vid,
    "url": f"https://youtube.com/watch?v={vid}",
    "title": meta["title"],
    "channel": meta["channel"],
    "views": meta["views"],
    "duration": meta["duration"],
    "upload_date": meta["upload_date"],
    "transcript": transcript,
    "transcript_error": error,
}, ensure_ascii=False))
' "$VIDEO_ID" 2>/dev/null)

if [ -z "$RESULT" ]; then
  json_msg "[yt-transcript] Fehler beim Laden des Transkripts fuer Video $VIDEO_ID"
  exit 0
fi

# Extract title and duration for the summary line
TITLE=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('title','?'))" 2>/dev/null)
DURATION=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('duration','?'))" 2>/dev/null)
CHANNEL=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('channel','?'))" 2>/dev/null)
HAS_TRANSCRIPT=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if d.get('transcript') else 'no')" 2>/dev/null)

if [ "$HAS_TRANSCRIPT" = "yes" ]; then
  # Save transcript to temp file for Claude to read if needed
  TEMP_FILE="/tmp/yt-transcript-${VIDEO_ID}.json"
  echo "$RESULT" > "$TEMP_FILE"
  json_msg "[yt-transcript] Auto-fetched: \"${TITLE}\" (${CHANNEL}, ${DURATION}). Transcript saved to ${TEMP_FILE}. Read it with the Read tool to get the full transcript content."
else
  ERROR=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('transcript_error','unknown'))" 2>/dev/null)
  json_msg "[yt-transcript] Video: \"${TITLE}\" (${CHANNEL}, ${DURATION}). Transcript error: ${ERROR}"
fi

exit 0
