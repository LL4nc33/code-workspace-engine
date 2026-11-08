---
description: MUSS VERWENDET WERDEN wenn User eine URL teilt (YouTube, Instagram, TikTok, Podcast, etc.) oder ein Video/Audio-Transkript braucht. Transkribiert via self-hosted Whisper server (faster-whisper) oder Fallback tubetranscript.
allowed-tools: ["Bash", "Read"]
---

# Transcribe

Transkribiert Audio/Video von jeder URL: YouTube, Instagram Reels, TikTok, Podcasts, direkte Media-Links. Nutzt eine self-hosted faster-whisper-API als Primary, tubetranscript als YouTube-Fallback.

**Usage:** `/cwe:transcript <url>`

## Konfiguration

Lies die Whisper-Server-URL aus `.claude/cwe-settings.yml` (Schlüssel: `tscribe_url`). Wenn nicht gesetzt, nur YouTube-Fallback verfügbar.

Use a Python parser instead of `grep | sed` — YAML values may be quoted, contain `:` or `#`, or have trailing whitespace/comments. The snippet below is safe against all of those and silently falls back to empty when the file/key is missing.

```bash
TSCRIBE_URL=$(python3 -c "
import sys, re, os
p = '.claude/cwe-settings.yml'
if not os.path.exists(p): sys.exit(0)
with open(p) as f:
    for line in f:
        m = re.match(r'^\s*tscribe_url\s*:\s*[\"\']?(\S+?)[\"\']?\s*(#.*)?$', line)
        if m:
            print(m.group(1))
            break
" 2>/dev/null)
```

Wenn kein Whisper-Server konfiguriert ist und die URL keine YouTube-URL ist, informiere den User und verweise auf Setup-Optionen:
- Self-hosted Whisper server via Docker
- Whisper lokal via `whisper-cli`
- Andere faster-whisper-API-Services

## Schritte

### 1. URL erkennen und Methode waehlen

- **YouTube** (`youtube.com`, `youtu.be`, `youtube.com/shorts/`): Whisper server primary (falls konfiguriert), tubetranscript Fallback
- **Instagram** (`instagram.com/reel/`, `instagram.com/p/`): Whisper server (erfordert Konfiguration)
- **TikTok** (`tiktok.com`): Whisper server (erfordert Konfiguration)
- **Alles andere** (Podcasts, direkte MP3/MP4 URLs): Whisper server (erfordert Konfiguration)

### 2. Whisper server API (Primary, wenn konfiguriert)

```bash
# Job erstellen
RESULT=$(curl -s -X POST "$TSCRIBE_URL/api/jobs/" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"URL_HERE\"}")

JOB_ID=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))")
echo "Job: $JOB_ID"
```

Dann pollen bis fertig:

```bash
# Pollen (max 60 Versuche, alle 5 Sekunden = 5 Minuten)
for i in $(seq 1 60); do
  sleep 5
  RESULT=$(curl -s "$TSCRIBE_URL/api/jobs/$JOB_ID")
  STATUS=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null)
  PROGRESS=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('progress',0))" 2>/dev/null)
  echo "Poll $i: status=$STATUS progress=$PROGRESS"
  if [ "$STATUS" = "done" ] || [ "$STATUS" = "failed" ]; then
    break
  fi
done
```

Ergebnis auslesen:

```bash
echo "$RESULT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f\"Titel: {d.get('title', '?')}\")
print(f\"Sprache: {d.get('detected_language', '?')}\")
print(f\"Dauer: {d.get('duration_seconds', 0):.0f}s\")
print(f\"---TRANSKRIPT---\")
print(d.get('result_text', 'FEHLER: ' + str(d.get('error', 'unbekannt'))))
"
```

### 3. Ergebnis praesentieren

- Titel, Sprache, Dauer
- Transkript-Zusammenfassung (bei langen Videos die wichtigsten Punkte)

### 4. Fallback: tubetranscript (nur YouTube, kein Whisper server nötig)

Falls Whisper server nicht konfiguriert/erreichbar ist UND es eine YouTube-URL ist, nutze das Hook-Script:

```bash
echo "{\"message\":\"URL_HERE\"}" | bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/transcript.sh
```

## Tipps

- Whisper server nutzt faster-whisper auf GPU — transkribiert auch Videos OHNE Untertitel
- Funktioniert mit allem was yt-dlp laden kann (YouTube, IG, TikTok, Vimeo, Twitter/X, etc.)
- Instagram/TikTok brauchen manchmal 10-20 Sekunden laenger (Download + Transkription)
- Bei langen Videos (>30 Min) kann es bis zu 2-3 Minuten dauern
- Whisper server erkennt die Sprache automatisch
