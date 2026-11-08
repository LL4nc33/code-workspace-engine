---
name: bookstack
description: >
  Used by the /cwe:docs command when uploading, creating, or updating documentation on BookStack.
  Provides API reference, auth, curl snippets and error handling for BookStack REST API.
  Not invoked from free-text user requests — workflow lives in /cwe:docs.
allowed-tools: ["Bash", "Read"]
---

# BookStack API — Implementierungsdetails

Technische Referenz fuer die BookStack REST API. Wird vom `/cwe:docs`-Command genutzt.

## Auth

Config aus `~/.claude/cwe.local.md` lesen:

```yaml
bookstack:
  url: https://<your-bookstack-host>
  token: <token-id>:<token-secret>
```

**Wichtig:** BookStack Token besteht aus zwei Teilen — Token ID und Token Secret.
Format: `<Token-ID>:<Token-Secret>` (zu finden unter Profil → API Tokens).
Beispiel: `abc123xyz:secretvalue456`

```bash
BS_URL=$(grep -A2 'bookstack:' ~/.claude/cwe.local.md | grep 'url:' | awk '{print $2}')
BS_TOKEN=$(grep -A3 'bookstack:' ~/.claude/cwe.local.md | grep 'token:' | awk '{print $2}')
```

Jeder Request benoetigt:
```bash
-H "Authorization: Token $BS_TOKEN"
-H "Content-Type: application/json"
```

## Endpunkte

| Ressource | Endpunkt | Methoden |
|-----------|---------|---------|
| Books | `/api/books` | GET (list), POST (create) |
| Books | `/api/books/{id}` | GET, PUT, DELETE |
| Chapters | `/api/chapters` | GET (list), POST (create) |
| Chapters | `/api/chapters/{id}` | GET, PUT, DELETE |
| Pages | `/api/pages` | GET (list), POST (create) |
| Pages | `/api/pages/{id}` | GET, PUT, DELETE |
| Search | `/api/search` | GET |

## Bewährte Vorgehensweise

### Stil deiner Docs anpassen (WICHTIG)

Bevor du Pages erstellst: **schaue dir bestehende Pages des Users an** und übernimm deren Stil.

```bash
# Bestehende Page als Stil-Referenz holen
curl -s "$BS_URL/api/pages/<id>" \
  -H "Authorization: Token $BS_TOKEN" | python3 -c "
import sys, json, re
d = json.load(sys.stdin)
html = d.get('html', '')
text = re.sub(r'<[^>]+>', ' ', html)
print(re.sub(r'\s+', ' ', text).strip()[:2000])
"
```

Typische Stile in Homelab-Wikis:
- **Kompakt** — kurze Übersichtstabelle (`Info | Wert`) oben
- **Praxisorientiert** — direkt Befehle, Ports, Konfiguration
- **Keine Kapitel** — Pages direkt im Buch ohne Zwischenschicht
- **Auf Deutsch** mit Sections wie `Übersicht`, `Installation`, `Zugriff`, `Wartung`

### Pages ohne Kapitel erstellen (empfohlen)

Pages immer direkt mit `book_id` erstellen, **ohne** `chapter_id` — außer der User fragt explizit nach Kapiteln:

```bash
# Build the JSON body with json.dumps (values via env) — never interpolate
# $TITLE/$CONTENT straight into the JSON string.
PAYLOAD=$(BOOK_ID="$BOOK_ID" TITLE="$TITLE" CONTENT="$CONTENT" python3 -c 'import os,json; print(json.dumps({"book_id": int(os.environ["BOOK_ID"]), "name": os.environ["TITLE"], "markdown": os.environ["CONTENT"]}))')
curl -s -X POST "$BS_URL/api/pages" \
  -H "Authorization: Token $BS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary "$PAYLOAD"
```

**WICHTIG:** `chapter_id: 0` zum Entfernen eines Kapitels funktioniert NICHT — die Page verliert dabei auch ihre `book_id` und wird unsichtbar. Pages immer neu erstellen statt verschieben.

## Snippets

### Pages erstellen

```bash
PAYLOAD=$(BOOK_ID="$BOOK_ID" CHAPTER_ID="$CHAPTER_ID" TITLE="$TITLE" CONTENT="$CONTENT" python3 -c 'import os,json; print(json.dumps({"book_id": int(os.environ["BOOK_ID"]), "chapter_id": int(os.environ["CHAPTER_ID"]), "name": os.environ["TITLE"], "markdown": os.environ["CONTENT"]}))')
curl -s -X POST "$BS_URL/api/pages" \
  -H "Authorization: Token $BS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary "$PAYLOAD"
```

`chapter_id` ist optional — weglassen für Pages direkt im Buch. Bevorzugtes Format: `markdown` (alternativ: `html`).

### Pages aktualisieren

```bash
PAYLOAD=$(TITLE="$TITLE" CONTENT="$CONTENT" python3 -c 'import os,json; print(json.dumps({"name": os.environ["TITLE"], "markdown": os.environ["CONTENT"]}))')
curl -s -X PUT "$BS_URL/api/pages/$PAGE_ID" \
  -H "Authorization: Token $BS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary "$PAYLOAD"
```

### Page-Existenz pruefen (Idempotenz)

```bash
Q=$(TITLE="$TITLE" python3 -c 'import os,urllib.parse; print(urllib.parse.quote(os.environ["TITLE"]))')
curl -s "$BS_URL/api/search?query=$Q&type=page" \
  -H "Authorization: Token $BS_TOKEN" | TITLE="$TITLE" python3 -c "
import sys, os, json
data = json.load(sys.stdin)
hits = [r for r in data.get('data', []) if r['name'] == os.environ['TITLE']]
print(hits[0]['id'] if hits else 'NOT_FOUND')
"
```

### Books auflisten

```bash
curl -s "$BS_URL/api/books?count=50" \
  -H "Authorization: Token $BS_TOKEN" | python3 -c "
import sys, json
for b in json.load(sys.stdin).get('data', []):
    print(f\"{b['id']}: {b['name']}\")
"
```

### Books erstellen

```bash
PAYLOAD=$(NAME="$NAME" DESC="$DESC" python3 -c 'import os,json; print(json.dumps({"name": os.environ["NAME"], "description": os.environ["DESC"]}))')
curl -s -X POST "$BS_URL/api/books" \
  -H "Authorization: Token $BS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary "$PAYLOAD"
```

### Chapters erstellen

```bash
PAYLOAD=$(BOOK_ID="$BOOK_ID" NAME="$NAME" DESC="$DESC" python3 -c 'import os,json; print(json.dumps({"book_id": int(os.environ["BOOK_ID"]), "name": os.environ["NAME"], "description": os.environ["DESC"]}))')
curl -s -X POST "$BS_URL/api/chapters" \
  -H "Authorization: Token $BS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary "$PAYLOAD"
```

### Suchen

```bash
curl -s "$BS_URL/api/search?query=$QUERY&type=page&count=10" \
  -H "Authorization: Token $BS_TOKEN" | python3 -c "
import sys, json
for r in json.load(sys.stdin).get('data', []):
    print(f\"[{r['id']}] {r['name']}  {r.get('url', '')}\")
"
```

### Page loeschen

```bash
curl -s -X DELETE "$BS_URL/api/pages/$PAGE_ID" \
  -H "Authorization: Token $BS_TOKEN"
```

## Python-Upload-Pattern (empfohlen für mehrere Pages)

Für mehrere Pages in einem Durchgang — bewährtes Pattern:

```python
import json, subprocess

BS_URL = "https://<your-bookstack-host>"
BS_TOKEN = "<token-id>:<token-secret>"
BOOK_ID = 123

def upload(title, content, chapter_id=None):
    payload = {"book_id": BOOK_ID, "name": title, "markdown": content}
    if chapter_id:
        payload["chapter_id"] = chapter_id
    r = subprocess.run([
        "curl", "-s", "-X", "POST", f"{BS_URL}/api/pages",
        "-H", f"Authorization: Token {BS_TOKEN}",
        "-H", "Content-Type: application/json",
        "-d", json.dumps(payload)
    ], capture_output=True, text=True)
    d = json.loads(r.stdout)
    if "id" in d:
        print(f"OK [{d['id']}] {d['name']}")
    else:
        print(f"ERR {d}")

upload("Übersicht", "## Übersicht\n\n| Info | Wert |\n...")
upload("Commands", "## Commands\n\n| Command | Beschreibung |\n...")
```

Credentials aus `~/.claude/cwe.local.md` lesen:

```python
import subprocess, re

def get_config():
    content = open('/home/' + subprocess.getoutput('whoami') + '/.claude/cwe.local.md').read()
    url = re.search(r'bookstack:.*?url:\s*(\S+)', content, re.DOTALL)
    token = re.search(r'bookstack:.*?token:\s*(\S+)', content, re.DOTALL)
    return url.group(1), token.group(1)
```

## Markdown-Verarbeitung

Frontmatter vor dem Upload entfernen:

```python
import re
content = open('file.md').read()
content = re.sub(r'^---\n.*?\n---\n', '', content, flags=re.DOTALL)
```

Titel aus erstem H1 extrahieren:

```python
import re
match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
title = match.group(1).strip() if match else 'Untitled'
```

Hinweis: Relative interne Links (`[Link](other.md)`) werden nicht aufgeloest — User informieren.

## Fehlerbehandlung

| HTTP-Code | Bedeutung | Loesung |
|-----------|-----------|---------|
| 401 | Token ungueltig/abgelaufen | `bookstack.token` in cwe.local.md pruefen |
| 403 | Keine Berechtigung | Token braucht Create/Edit-Rechte in BookStack |
| 404 | Ressource nicht gefunden | Buch-ID oder Chapter-ID pruefen |
| 413 | Inhalt zu gross | Page in kleinere Abschnitte aufteilen |
| Timeout | Server nicht erreichbar | `bookstack.url` und Netzwerkverbindung pruefen |
