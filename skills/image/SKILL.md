---
name: image
description: >
  Bild generieren mit Gemini via OpenRouter.
  Text-to-Image oder Image-Editing mit --input.
allowed-tools: ["Bash", "Read"]
argument-hint: "<prompt> [--input bild.jpg] [--output pfad.png] [--model flash|3.1|pro]"
disable-model-invocation: true
---

Run the generator with the plugin path quoted and each argument passed as a
**separate, quoted** shell argument — never interpolate the raw argument string
unquoted into the shell.

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/gemini_image.py" "<prompt>" [--input "<file>"] [--output "<file>"] [--model flash|3.1|pro]
```

Lies das Ergebnis-JSON. Bei `success: true` → zeig das Bild mit Read-Tool.
Bei `success: false` → zeig den Fehler dem User.
