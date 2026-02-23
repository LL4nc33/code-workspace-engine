---
description: MUSS VERWENDET WERDEN wenn User einen Screenshot analysieren will oder Bild aus Zwischenablage braucht. Multi-OS (WSL2/macOS/Linux).
allowed-tools: ["Bash", "Read"]
---

# CWE Screenshot

Liest einen Screenshot aus der Zwischenablage und analysiert ihn. Multi-OS Support.

**Usage:** `/cwe:screenshot`

## Schritte

1. Erkenne das Betriebssystem und speichere die Zwischenablage als PNG:

```bash
OS_TYPE="$(uname -s)"
SAVE_PATH="$(pwd)/clipboard-screenshot.png"

if grep -qi microsoft /proc/version 2>/dev/null; then
  # WSL2 — use PowerShell with Windows path (WSL paths cause GDI+ error)
  WIN_DIR=$(wslpath -w "$(pwd)")
  powershell.exe -Command "Add-Type -AssemblyName System.Windows.Forms; if ([System.Windows.Forms.Clipboard]::ContainsImage()) { [System.Windows.Forms.Clipboard]::GetImage().Save('${WIN_DIR}\\clipboard-screenshot.png', [System.Drawing.Imaging.ImageFormat]::Png); Write-Output 'SAVED' } else { Write-Output 'NO_IMAGE' }"
elif [ "$OS_TYPE" = "Darwin" ]; then
  # macOS — use pngpaste (brew install pngpaste)
  if command -v pngpaste &>/dev/null; then
    pngpaste "$SAVE_PATH" 2>/dev/null && echo "SAVED" || echo "NO_IMAGE"
  else
    echo "MISSING_TOOL:pngpaste (brew install pngpaste)"
  fi
elif [ -n "$WAYLAND_DISPLAY" ]; then
  # Linux Wayland
  if command -v wl-paste &>/dev/null; then
    wl-paste --type image/png > "$SAVE_PATH" 2>/dev/null && [ -s "$SAVE_PATH" ] && echo "SAVED" || echo "NO_IMAGE"
  else
    echo "MISSING_TOOL:wl-clipboard (sudo apt install wl-clipboard)"
  fi
else
  # Linux X11
  if command -v xclip &>/dev/null; then
    xclip -selection clipboard -t image/png -o > "$SAVE_PATH" 2>/dev/null && [ -s "$SAVE_PATH" ] && echo "SAVED" || echo "NO_IMAGE"
  else
    echo "MISSING_TOOL:xclip (sudo apt install xclip)"
  fi
fi
```

2. **Wenn `SAVED`**: Lies `clipboard-screenshot.png` im aktuellen Verzeichnis mit dem Read-Tool und beschreibe/analysiere was du siehst. Beziehe dich dabei auf den aktuellen Kontext der Konversation.

3. **Wenn `NO_IMAGE`**: Sage dem User dass kein Bild in der Zwischenablage ist — er soll zuerst einen Screenshot machen.

4. **Wenn `MISSING_TOOL:...`**: Sage dem User welches Tool fehlt und wie er es installiert.

5. **Cleanup**: Nach der Analyse die temporäre Datei löschen:

```bash
rm -f "$(pwd)/clipboard-screenshot.png"
```
