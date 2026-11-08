# CWE v0.8.3

Orchestration plugin. Delegation via hooks — follow the injected routing hints (hook `additionalContext`).

## Mistakes to avoid
- Don't handle tasks yourself when a CWE agent exists for it
- Don't skip memory updates after changes (memory/MEMORY.md, CHANGELOG.md)
- Run /cwe:help if unsure about available commands

## Media Tools

Scripts in `scripts/` for image, video, and motion generation. API keys in `scripts/media-keys.sh` (gitignored). These are invoked via skills (not slash commands).

| Skill | Script | API | Description |
|-------|--------|-----|-------------|
| `image` | `gemini_image.py` | OpenRouter (Gemini) | Text/Image-to-Image |
| `faceswap` | `magichour_faceswap.py` | MagicHour | Face Swap (photo + video) |
| `headswap` | `magichour_headswap.py` | MagicHour | Head Swap |
| `upscale` | `magichour_upscale.py` | MagicHour | Image Upscaler (2x/4x) |
| `video` | `magichour_video.py` | MagicHour | Text/Image-to-Video |
| `motion` | Remotion project | React + Remotion | Programmatic motion graphics |

## Content Tools

| Command | Purpose | Backend |
|---------|---------|---------|
| `/cwe:transcript` | Video/audio transcripts (YouTube, Instagram, TikTok, podcasts) | self-hosted Whisper server or tubetranscript fallback |
| `/cwe:pdf` | Read/analyze PDFs by rendering pages to images | Stirling PDF API |
