---
name: faceswap
description: >
  Face Swap via MagicHour. Gesicht in Foto oder Video austauschen.
  Erkennt automatisch ob Source ein Bild oder Video ist.
allowed-tools: ["Bash", "Read"]
argument-hint: "--source <foto/video> --face <gesicht.jpg> [--output pfad]"
disable-model-invocation: true
---

Run the generator with the plugin path quoted and each argument passed as a
**separate, quoted** shell argument — never interpolate the raw argument string
unquoted into the shell.

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/magichour_faceswap.py" --source "<foto/video>" --face "<gesicht.jpg>" [--output "<pfad>"]
```

Lies das Ergebnis-JSON. Bei `success: true` -> zeig das Ergebnis mit Read-Tool (bei Bildern).
