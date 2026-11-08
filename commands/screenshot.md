---
description: MUSS VERWENDET WERDEN wenn User einen Screenshot analysieren will oder Bild aus Zwischenablage braucht. Multi-OS (WSL2/macOS/Linux).
allowed-tools: ["Bash", "Read"]
argument-hint: "[--output pfad.png]"
---

# CWE Screenshot

Liest einen Screenshot aus der Zwischenablage und analysiert ihn. Multi-OS Support (WSL2 / macOS / Linux Wayland / Linux X11).

**Usage:** `/cwe:screenshot [--output pfad.png]`

## Ausfuehrung

Run the capture script with the plugin path quoted. If the user passed
`--output <path>`, pass it as a **separate, quoted** argument — never interpolate
the raw argument string unquoted into the shell:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/screenshot.py"                      # clipboard → temp file
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/screenshot.py" --output "out.png"   # explicit output path
```

Parse das JSON-Ergebnis:

- **`success: true`** → Lies `path` mit dem Read-Tool und analysiere das Bild im Kontext der Konversation. Danach die Datei loeschen: `rm -f <path>`.
- **`success: false`** → Zeige `error` + `hint` dem User an. Haeufige Faelle:
  - "Kein Bild in der Zwischenablage" → User soll zuerst einen Screenshot machen
  - "pngpaste nicht installiert" → `brew install pngpaste` (macOS)
  - "wl-clipboard nicht installiert" → `sudo apt install wl-clipboard` (Wayland)
  - "xclip nicht installiert" → `sudo apt install xclip` (X11)

## Unterstuetzte Plattformen

| OS | Tool | Install | Status |
|----|------|---------|--------|
| WSL2 | PowerShell (Windows Clipboard) | Automatisch verfuegbar | Getestet (v0.8.2) |
| macOS | `pngpaste` | `brew install pngpaste` | **Nicht getestet** — bitte bei Problemen Issue öffnen |
| Linux Wayland | `wl-paste` | `sudo apt install wl-clipboard` | Nicht getestet |
| Linux X11 | `xclip` | `sudo apt install xclip` | Nicht getestet |
