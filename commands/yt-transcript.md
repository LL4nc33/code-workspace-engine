---
description: MUSS VERWENDET WERDEN wenn User eine YouTube-URL teilt oder ein Video-Transkript braucht. Extrahiert Transkript + Metadaten ohne API-Key.
allowed-tools: ["Bash", "Read"]
---

# YouTube Transcript

Extrahiert Transkript und Metadaten von jedem YouTube-Video. Keine API-Keys, keine Dependencies — reines Python 3 mit stdlib.

**Usage:** `/cwe:yt-transcript <url_or_video_id>`

## Anwendung

1. Rufe das Hook-Script direkt auf mit der URL/ID als Fake-Prompt:

```bash
echo '{"message":"USER_URL_HERE"}' | bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/yt-transcript.sh
```

Ersetze `USER_URL_HERE` mit der vom User gegebenen URL oder Video-ID.

2. Das Script gibt eine `systemMessage` zurück mit dem Pfad zur JSON-Datei (`/tmp/yt-transcript-<ID>.json`).

3. **Lies die JSON-Datei** mit dem Read-Tool und präsentiere dem User:
   - Titel, Channel, Dauer, Views, Upload-Datum
   - Transkript-Zusammenfassung (bei langen Videos die wichtigsten Punkte)
   - Bei Fehler: Fehlermeldung anzeigen

## Tipps

- Funktioniert mit allen YouTube-URL-Formaten: `watch?v=`, `youtu.be/`, `shorts/`, `/embed/`
- Braucht nur Python 3 stdlib — kein pip install nötig
- Transkript kommt von tubetranscript.com (kostenlos, kein API-Key)
- Bei Timeout: Nochmal versuchen — manche Videos brauchen 2 Anläufe

## Output-Format

Die JSON-Datei unter `/tmp/yt-transcript-<ID>.json` enthält:

```json
{
  "video_id": "abc123",
  "url": "https://youtube.com/watch?v=abc123",
  "title": "Video Title",
  "channel": "Channel Name",
  "views": 123456,
  "duration": "12:34",
  "upload_date": "2025-01-15",
  "transcript": "Full transcript text...",
  "transcript_error": null
}
```
