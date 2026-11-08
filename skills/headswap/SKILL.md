---
name: headswap
description: >
  Head Swap via MagicHour. Ganzen Kopf in einem Foto austauschen.
allowed-tools: ["Bash", "Read"]
argument-hint: "--source <foto.jpg> --head <kopf.jpg> [--output pfad]"
disable-model-invocation: true
---

Run the generator with the plugin path quoted and each argument passed as a
**separate, quoted** shell argument — never interpolate the raw argument string
unquoted into the shell.

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/magichour_headswap.py" --source "<foto.jpg>" --head "<kopf.jpg>" [--output "<pfad>"]
```

Lies das Ergebnis-JSON. Bei `success: true` → zeig das Ergebnis mit Read-Tool.
