---
name: upscale
description: >
  Bild hochskalieren via MagicHour. Default 2x, optional 4x (nicht im Free-Tier).
allowed-tools: ["Bash", "Read"]
argument-hint: "<bild.png> [--scale 2|4] [--output pfad]"
disable-model-invocation: true
---

Run the generator with the plugin path quoted and each argument passed as a
**separate, quoted** shell argument — never interpolate the raw argument string
unquoted into the shell.

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/magichour_upscale.py" "<bild.png>" [--scale 2|4] [--output "<pfad>"]
```

Lies das Ergebnis-JSON. Bei `success: true` → zeig das Ergebnis mit Read-Tool.
