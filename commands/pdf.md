---
description: MUSS VERWENDET WERDEN wenn User eine PDF-Datei lesen, analysieren oder Text daraus extrahieren will. Konvertiert PDF-Seiten zu Bildern via Stirling PDF API und liest sie visuell.
allowed-tools: ["Bash", "Read"]
---

# CWE PDF Reader

Liest PDF-Dateien durch Konvertierung zu Bildern via [Stirling PDF API](https://github.com/Stirling-Tools/Stirling-PDF). Funktioniert auch mit gescannten PDFs ohne OCR — Claude liest die Bilder direkt.

**Usage:** `/cwe:pdf <dateipfad> [seitenzahlen]`

Beispiele:
- `/cwe:pdf /path/to/dokument.pdf` — alle Seiten
- `/cwe:pdf /path/to/dokument.pdf 1-5` — nur Seite 1-5
- `/cwe:pdf /path/to/dokument.pdf 3` — nur Seite 3

## Konfiguration

Lies die Stirling-URL aus `.claude/cwe-settings.yml` (Schlüssel: `stirling_pdf_url`). Fällt sie auf `http://localhost:8080` zurück wenn nicht gesetzt.

Use a Python parser instead of `grep | sed` — YAML values may be quoted, contain `:` or `#`, or have trailing whitespace/comments. The fallback default is preserved if the key is absent.

```bash
STIRLING_URL=$(python3 -c "
import sys, re, os
p = '.claude/cwe-settings.yml'
if not os.path.exists(p): sys.exit(0)
with open(p) as f:
    for line in f:
        m = re.match(r'^\s*stirling_pdf_url\s*:\s*[\"\']?(\S+?)[\"\']?\s*(#.*)?$', line)
        if m:
            print(m.group(1))
            break
" 2>/dev/null)
STIRLING_URL=${STIRLING_URL:-http://localhost:8080}
```

Wenn kein Stirling-Server verfügbar ist, informiere den User und verweise auf [Stirling-PDF Setup](https://docs.stirlingpdf.com/) oder `docker run -p 8080:8080 stirlingtools/stirling-pdf`.

## Schritte

1. **Dateipfad und Seitenbereich parsen** aus den ARGUMENTS. Wenn kein Seitenbereich angegeben, alle Seiten lesen. Prüfe ob die Datei existiert.

2. **Seitenanzahl ermitteln** — Lade die PDF-Info über die Stirling API:

```bash
PAGE_COUNT=$(curl -s -X POST "$STIRLING_URL/api/v1/security/get-info-on-pdf" \
  -F "fileInput=@DATEIPFAD" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('basicInfo',{}).get('Number of pages','0'))" 2>/dev/null)
echo "Seiten: $PAGE_COUNT"
```

3. **PDF zu Bildern konvertieren** via Stirling API:

Erstelle **einmal** ein Arbeitsverzeichnis mit `mktemp -d` (kein fester, vorhersagbarer
Pfad) und verwende dessen echten Pfad in allen folgenden Schritten — jeder Bash-Aufruf
ist eine frische Shell, merke dir den ausgegebenen `$WORKDIR`-Pfad:

```bash
WORKDIR=$(mktemp -d "${TMPDIR:-/tmp}/cwe-pdf-XXXXXX"); echo "$WORKDIR"
curl -s -X POST "$STIRLING_URL/api/v1/convert/pdf/img" \
  -F 'fileInput=@DATEIPFAD' \
  -F 'imageFormat=jpeg' \
  -F 'singleOrMultiple=multiple' \
  -F 'dpi=200' \
  -o "$WORKDIR/pages.zip"
```

4. **ZIP entpacken**:

```bash
cd "$WORKDIR" && python3 -c "import zipfile; zipfile.ZipFile('pages.zip').extractall('pages/')"
ls "$WORKDIR/pages/" | sort
```

5. **Seiten lesen** — Lies jede Bild-Datei mit dem Read-Tool. Bei vielen Seiten (>20) nur den angegebenen Seitenbereich lesen. Fasse den Inhalt zusammen und beziehe dich auf den Kontext der Konversation.

   - Bei **Seitenbereich** (z.B. `1-5`): Nur die entsprechenden Dateien lesen
   - Bei **allen Seiten**: Maximal 20 Seiten auf einmal lesen, bei mehr den User fragen
   - **Parallel lesen**: Lies bis zu 5 Seiten gleichzeitig mit parallelen Read-Aufrufen

6. **Cleanup**: Nach der Analyse temporaere Dateien entfernen:

```bash
rm -rf "$WORKDIR"
```

## Tipps

- Funktioniert mit allen PDF-Typen: Text-PDFs, gescannte Dokumente, gemischt
- Gescannte PDFs werden als Bilder gelesen — kein OCR noetig da Claude multimodal ist
- Bei grossen PDFs (50+ Seiten) immer einen Seitenbereich angeben
