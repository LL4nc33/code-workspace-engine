---
name: video
description: >
  Video generieren via MagicHour. Text-to-Video oder Image-to-Video mit --input.
allowed-tools: ["Bash", "Read"]
argument-hint: "<prompt> [--input bild.jpg] [--duration 5] [--output video.mp4]"
disable-model-invocation: true
---

Run the generator with the plugin path quoted and each argument passed as a
**separate, quoted** shell argument — never interpolate the raw argument string
unquoted into the shell.

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/magichour_video.py" "<prompt>" [--input "<file>"] [--duration 5] [--output "<file>"]
```

Lies das Ergebnis-JSON. Bei `success: true` → informiere den User wo das Video liegt.
