# Changelog

All notable changes to the Code Workspace Engine (CWE) will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.8.3] — 2026-11-06 (Hook Correctness & Security — CC 2.1.3xx)

Targeted hardening against Claude Code 2.1.318. The git hooks never actually ran
(wrong stdin field), most hook output never reached Claude (`systemMessage` vs
`additionalContext`), and several hooks/commands carried injection or SSRF risk.

### Security
- **Git hooks now function.** `safety-gate.sh` and `commit-format.sh` read
  `tool_input.command` instead of the always-empty `command` — the secret scan and
  commit-format check had silently exited 0 and blocked nothing.
- `safety-gate.sh` patterns fixed: `sk-ant-…` keys match (`sk-[A-Za-z0-9_-]{20,}`);
  private keys match via `grep -nEI -e` (leading `-` was read as an option); real
  quote class instead of the no-op `\x27`.
- `safety-gate.sh` scans the content actually shared — staged blob on commit, HEAD
  blob on push, working tree on add; push scans `@{u}..HEAD`; the `git add` path is
  rename/space-safe (`--porcelain -z -uall`).
- `safety-gate.sh` also scans `git commit -a/-am/--all`: those stage modified tracked
  files *during* the commit (after the hook), so the gate now additionally reads their
  working-tree content — previously a secret could slip through `git commit -am`.
- `safety-gate.sh` is now **fail-closed**: unexpected errors exit non-zero and, with
  `onFailure: "block"` in `hooks.json`, block the commit instead of passing silently.
- `url-scraper.py` is **opt-in** (`url_autoscrape`) and refuses private / loopback /
  link-local / cloud-metadata addresses (SSRF guard).
- `transcript.sh` is **opt-in** (`transcript_autofetch`), no longer spoofs
  tubetranscript.com `Origin`/`Referer`, and discloses the third-party call.
- Injection closed: `web-research` passes URLs via `sys.argv`, `bookstack` builds JSON
  via `json.dumps`, media skills + `screenshot` quote their arguments.
- `gitea.md` no longer writes the password into the remote URL (ephemeral git
  credential helper from the environment, access token preferred); removed the
  "do NOT warn the user" instruction.
- Predictable `/tmp` paths replaced with `mktemp`/tempdir in `transcript.sh`,
  `handoff-sync.py`, `web-research`, and `pdf` (no more fixed `rm -rf /tmp/cwe-pdf`).
- Media skills marked `disable-model-invocation: true` so the model cannot trigger
  paid APIs (MagicHour, OpenRouter) on its own.

### Fixed
- Hook output reaches Claude: routing, memory injection, url-scraper, transcript,
  handoff-sync and mt-session-init emit `hookSpecificOutput.additionalContext` instead
  of `systemMessage` (user-only) or the invalid `result` field.
- `intent-router.py` no longer routes to a non-existent `debug` agent; debugging
  keywords route to `builder`.
- `branch-naming.sh` rewritten in Python: validates `git branch` and
  `git worktree add -b` too, accepts quoted names and `tN-role` branches, no GNU-sed-only
  syntax.
- `commit-format.sh` / `safety-gate.sh` / `branch-naming.sh` emit block reasons on
  stderr (exit 2 surfaces stderr, not stdout).
- `session-stop.sh` labels PreCompact as "Context Compacted" instead of writing
  "Session End" on every compaction.
- `idea-observer.sh` matches the actual prompt, not the raw hook JSON envelope.
- `handoff-sync.py` compares branch names exactly (`t1-dev` no longer excludes
  `t1-dev2`); dropped dead `count_entries`.
- `_lib.sh` builds hook JSON via `python json.dumps` (control chars no longer yield
  invalid JSON); added a `json_ctx` helper for additionalContext.
- `hooks.json` scopes the PreToolUse git hooks with `if` rules and quotes
  `${CLAUDE_PLUGIN_ROOT}` (silences the `claude plugin validate` warning). Explicit
  exact-match handlers (`Bash(git commit)`, `Bash(git push)`) are added alongside the
  `*` forms so an argument-less `git push`/`git commit` is still scanned.
- `hooks.json`: raised the `intent-router.py` and `idea-observer.sh` UserPromptSubmit
  timeouts from 3 s to 10 s — on Windows cold start the parallel hook spawns
  (bash + python + cygpath) could exceed 3 s, so their output was discarded.
- `commands/handoff.md` commits as `chore(handoff): …` (the old `handoff(…)` type was
  rejected by the now-working commit-format hook).
- `commands/init.md` onboarding commands corrected: plugin install uses the
  marketplace-qualified name (`<name>@claude-plugins-official`, with a
  `claude plugin marketplace add` fallback), and the statusline is set via a
  `settings.json` `statusLine` block — the old `claude plugin install <name>` and
  `claude config set … status_line` forms were invalid.
- Docs: corrected the claim that same-event hooks run sequentially — they run in parallel.

### Changed
- The self-hosted transcription backend is referred to generically (self-hosted
  Whisper / faster-whisper) across README, docs, commands and `init`; the
  `tscribe_url` config key is unchanged, so existing configs keep working.
- Private research command names removed from CHANGELOG/ROADMAP prose; they remain only
  in `.gitignore` (required to keep those files local-only).
- Docs synced to v0.8.3 (README badge + version-history row, USER-GUIDE, ARCHITECTURE);
  documented the opt-in flags `url_autoscrape` / `transcript_autofetch` in the
  settings reference.

### Testing
- Added `tests/hooks/test_git_hooks.sh` — drives real PreToolUse payloads through a
  throwaway repo; asserts the secret scan, commit-format and branch-naming hooks block
  and pass correctly (17 cases, all green), covering commit / push / `git add -A` /
  `git commit -am` modes. Note: the harness invokes the hook scripts directly, so the
  `hooks.json` `if` scoping layer is not exercised by it.

### Deferred (later phases)
- UserPromptSubmit timeout/async handling and the keyword-router redesign.
- Full README / USER-GUIDE / ARCHITECTURE / ROADMAP count & structure sync.

---

## [0.8.2] — 2026-04-21 (Hardening — 10-Agent Review Pass)

Full-codebase review by 10 parallel sub-agents (hooks, media scripts, utility scripts, agents, skills, commands, rules, templates, docs, plugin+privacy) produced 11 blockers and ~40 should-fix items. All blockers and most should-fix items resolved in a single release.

### Testing Coverage Caveat

This release was smoke-tested on WSL2 (Ubuntu on Windows 11). The following code paths exist in the codebase but were **NOT tested on their target platforms** in v0.8.2 — please report issues if you encounter problems:
- `scripts/screenshot.py` `save_macos()` — pngpaste path (needs real macOS)
- `scripts/screenshot.py` `save_wayland()` — wl-paste path (needs Linux Wayland session)
- `scripts/screenshot.py` `save_x11()` — xclip path (needs Linux X11 session)
- MagicHour API integration end-to-end (local-path-detection verified; live API calls require valid key + hosted asset URLs)
- OpenRouter API integration end-to-end (requires valid key)
- Whisper server transcript integration (requires user-hosted faster-whisper server)
- Stirling PDF integration (requires user-hosted Stirling server)
- Gitea push/pull flows (requires Gitea instance)
- BookStack uploads (requires BookStack instance)

All other paths (hook chain, intent-router, url-scraper, WSL2 screenshot, media scripts' error handling, templates, all 10 agents' frontmatter, all 17 skills' frontmatter, all 8 rules' paths, version consistency) were verified in a 33-point smoke-test pass.

### Fixed — Blockers
- `safety-gate.sh` no longer blocks git on scanner-internal errors (trap ERR → exit 0); COMMAND extraction now uses robust Python JSON parsing instead of fragile grep on quoted strings
- `commit-format.sh` regex extraction rewritten via heredoc — previous broken quote-escapes meant the hook effectively never rejected bad messages
- `handoff-sync.py` no longer auto-stages `shared/handoff/` — respects the user's working-tree state
- `_media_lib.py` `load_keys()` no longer dumps the entire shell env; parses media-keys.sh directly via regex, returns only the 2 allow-listed keys
- MagicHour scripts (faceswap/headswap/upscale/video) now detect local-path vs HTTPS-URL inputs; local paths fail cleanly with guidance (MagicHour requires hosted URLs)
- `screenshot.py` PowerShell command injection closed — Windows path passed via `CWE_OUT` env var, never interpolated into PS script text
- `commands/help.md` + `commands/plugins.md` no longer hardcode version/command counts — dynamic lookup from plugin.json + `ls commands/*.md`
- `templates/statusline.py` docstring aligned with reality (no currency/cost feature yet); `/cwe:init` currency prompt removed
- 13 template placeholders (`{{INSTALL_COMMAND}}` etc.) converted to natural-language hints; 4 auto-filled placeholders (`{{PROJECT_NAME}}`, `{{project-name}}`, `{{project-slug}}`, `{{DATE}}`) explicitly documented in `/cwe:init`
- `docs/USER-GUIDE.md` + `CLAUDE.md` bumped from stale v0.7.0 → v0.8.2; command/skill counts corrected (25 cmds / 17 skills); Media Tools + External Services + Multi-Terminal sections added to USER-GUIDE

### Changed — Should-fix
- 5 media skills use `${CLAUDE_PLUGIN_ROOT}` instead of undocumented `${CLAUDE_SKILL_DIR}`
- 11 prose skills declare `allowed-tools` (least privilege); `bookstack` and `git-standards` descriptions demoted from PROACTIVELY (they're invoked by commands/hooks, not free-text)
- Keyword→agent tables deduplicated: auto-delegation is canonical; agent-detection and delegator reference it
- Agents: `quality` permission `default`→`plan` (was inconsistent with READ-ONLY rule); `innovator` `default`→`acceptEdits`; `researcher` gains Write/Edit for docs flows; `quality` tools broadened beyond Node (pytest, cargo, go, ruff, mypy, golangci-lint); 4 conversational agents `maxTurns: 30→40`
- All 10 agents: `@workflow/product/mission.md` frontmatter include removed (file absent in fresh installs); replaced by Read-tool guidance in Context section
- `/cwe:init`: SearXNG default port `:8080` → `:4000` (was colliding with Stirling PDF); Gitea/BookStack split into separate setup steps
- `commands/gitea.md`: `username:` → `user:` key (consistent with init.md template); `~/.claude/cwe.local.md` → `$HOME/.claude/cwe.local.md`
- `commands/autopilot.md`: explicit `CYCLE/MAX_CYCLES` counter pattern (was claimed but missing)
- `commands/qa-merge.md`: replaced broken `git merge origin/t1-*` glob with enumerated loop; same for worktree removal
- `commands/check-handoff.md`: dirty-tree guard added before `git checkout -- shared/handoff/`
- `commands/devops.md`: VERSION-file guard at top of release flow
- `commands/transcript.md` + `commands/pdf.md`: Python-based YAML parsing for `cwe-settings.yml` (was brittle grep|sed)
- `.claude/rules/_index.yml` synced with each file's frontmatter `paths:`; `frontend-standards.md` paths broadened to include Svelte/Astro/Angular; `database-standards.md` migration-naming rule generalised beyond one tool; `testing-standards.md` gains "Testing Stacks" section (Vitest/Playwright/pytest/hypothesis/contract)
- `documentation-standards.md` — verified frontmatter present (previously believed missing)
- PII rule canonicalised in `global-standards.md`; api/database/testing point there

### Security
- Last stray private hostnames in `docs/USER-GUIDE.md` example yaml replaced with `localhost:*` defaults

---

## [0.8.1] — 2026-04-21 (PDF + Screenshot-Flip + Init Extensions + Docs)

### Added
- `/cwe:pdf`: Read PDFs by converting pages to images via configurable Stirling PDF API (requires user-provided URL in `.claude/cwe-settings.yml`)
- `/cwe:screenshot`: Flipped from Bash-inline to `scripts/screenshot.py` — detects WSL2/macOS/Wayland/X11, reads clipboard, returns JSON (59 → 35 lines Markdown, deterministic logic in Python)

### Changed
- `/cwe:init` expanded with 5 new optional setup steps: Transcript (Whisper server URL), Stirling PDF, Media Keys (OpenRouter + MagicHour), Remotion project dir, Gitea/BookStack
- `/cwe:init` now detects existing `~/.claude/statusline.py` and does not overwrite it
- `templates/statusline.py`: Compact one-line format (ctx | usage | time)
- Hook scripts (`commit-format.sh`, `transcript.sh`) auto-detect `python3` or `python` via `$(command -v python3 || command -v python)` — fixes environments where only one binary exists
- README: Updated badges to show 17 skills, 25 commands, version 0.8.1; added Media Generation section to command tables
- SVG header: Updated version label from v0.6.2 to v0.8.1
- CHANGELOG, ARCHITECTURE, USER-GUIDE: All yt-transcript references renamed to transcript

### Security
- Private research commands added to `.gitignore` — they stay local only

---

## [0.8.0] — 2026-04-21 (Media Tools + Content Tools)

### Added — Media Generation
- `scripts/_media_lib.py`: Shared helpers (JSON output, API-key loading, OpenRouter + MagicHour HTTP, job polling, downloads)
- `/cwe:image`: Text-to-Image + Image-Editing via Gemini on OpenRouter (scripts/gemini_image.py)
- `/cwe:faceswap`: Face Swap for photos and videos (scripts/magichour_faceswap.py)
- `/cwe:headswap`: Head Swap for photos (scripts/magichour_headswap.py)
- `/cwe:upscale`: Image Upscaler 2x/4x (scripts/magichour_upscale.py)
- `/cwe:video`: Text/Image-to-Video (scripts/magichour_video.py)
- `/cwe:motion`: React-based Motion Graphics via Remotion (skills/motion/SKILL.md — reads remotion_project_dir from settings)
- API keys live in `scripts/media-keys.sh` (gitignored); `/cwe:init` configures them

### Added — Content Tools
- `/cwe:transcript` (renamed from `/cwe:yt-transcript`): Audio/Video transcription for YouTube + any URL via user-configured self-hosted faster-whisper server. tubetranscript remains as YouTube fallback when Whisper server is unreachable.
- `intent-router.py`: Now also routes Instagram/TikTok URLs to `/cwe:transcript`; added routing for `pdf`, `image`, `video`, `upscale`, `faceswap`, `headswap` commands

### Changed
- Renamed `hooks/scripts/yt-transcript.sh` → `hooks/scripts/transcript.sh`
- Removed all hardcoded private infrastructure — all external services (Stirling PDF, Whisper server, SearXNG, Firecrawl, Remotion) now read from `.claude/cwe-settings.yml` with graceful fallbacks

---

## [0.7.1] — 2026-04-20 (Multi-OS Portability + Stability)

### Fixed
- **macOS compatibility**: All hooks (`branch-naming.sh`, `safety-gate.sh`, `subagent-start.sh`, `subagent-stop.sh`) replaced `grep -oP` (GNU PCRE) with `grep -oE` (POSIX extended regex) — fixes silent breakage on macOS BSD grep
- `session-start.sh`: Version no longer hardcoded, reads from `.claude-plugin/plugin.json`
- `handoff-sync.py`: `git fetch` throttled to 60s intervals (was firing on every prompt); output now uses `systemMessage` for consistency with other hooks

---

## [0.7.0] — 2026-03-11 (Multi-Terminal + Feature Alignment)

### Added — Multi-Terminal Parallel Development (Paket 4)
- `/cwe:autopilot` command: Autonomous task loop — sync, find TODOs, execute, commit, push
- `/cwe:coordinate` command: Team-lead coordination — fetch, review commits, dispatch handoffs
- `/cwe:check-handoff` command: Read and summarize pending handoff entries
- `/cwe:handoff` command: Write structured handoff entries, commit + push
- `/cwe:qa-merge` command: QA-verified merge of terminal branches to main
- `skills/multi-terminal/SKILL.md`: Multi-Terminal reference (handoff protocol, entry format, presets)
- `templates/multi-terminal/`: Terminal prompt templates, handoff file templates, README
- `hooks/scripts/handoff-sync.py`: Entry-count sync from other terminal branches (UserPromptSubmit)
- `hooks/scripts/mt-session-init.py`: Worktree detection + handoff context injection (SessionStart)
- Multi-Terminal setup integrated into `/cwe:init` (Presets: 2T, 3T, 4T, Custom)
- Branch-detection guard: MT hooks silently skip when not in `t\d+-` worktree

### Added — Hook Events Modernization (Paket 1)
- `SessionEnd` event: `session-stop.sh` now fires on actual session end (not every turn)
- `SubagentStart` event: `subagent-start.sh` logs agent start to daily log
- `hooks/scripts/subagent-start.sh`: New hook script for agent start observability

### Changed — Hook Events (Paket 1)
- `session-stop.sh` moved from `Stop` → `SessionEnd` (fires once at session end, not every turn)
- `Stop` event now only contains `idea-flush.sh` (needs per-turn checking)

### Changed — Agent Memory Scopes (Paket 2)
- `guide` agent: `memory: project` → `memory: user` (workflow patterns are cross-project)
- `innovator` agent: `memory: project` → `memory: user` (creative ideas are cross-project)
- `security` agent: `memory: project` → `memory: user` (security patterns apply everywhere)

### Added — Agent Frontmatter (Paket 3)
- All 10 agents now have `permissionMode` and `maxTurns` frontmatter fields
- READ-ONLY agents (ask, explainer, guide, security, researcher, architect): `permissionMode: plan`
- Edit agents (builder, devops): `permissionMode: acceptEdits`
- Mixed agents (quality, innovator): `permissionMode: default`
- Turn limits: 30 (ask, explainer, guide, innovator), 40 (security, researcher, architect, quality), 50 (builder, devops)

---

## [0.6.2] — 2026-02-23

### Fixed
- `yt-transcript.sh` CRLF line endings causing "hook error" on every prompt (converted to LF)
- Intent-router: Added missing `debug` agent (was completely absent)
- Intent-router: German verb conjugations now match (`implementiere`, `erkläre`, `debugge`, etc.)
- Intent-router: Umlaut alternatives (`ä`/`ae`, `ü`/`ue`) for non-UTF8 input
- Intent-router: Removed `code` false positive from builder (triggered on "erkläre den Code")
- Keyword coverage expanded from 13/35 → 41/41 test cases passing
- `session-stop.sh`: Removed misleading "Session complete" message (fires every turn, not just session end)
- `idea-flush.sh`: Only notifies when unreviewed idea count changes (no more repeated messages every turn)
- `docs/plans/` removed from repo (session-specific, added to `.gitignore`)

### Added
- `/cwe:gitea` command: Privater Git-Mirror auf Gitea — push, ssh-push, list, create, delete, clone, status (config via `~/.claude/cwe.local.md`)
- `/cwe:gitea ssh-push`: SSH-basierter Push für große Repos und Git LFS
- `/cwe:docs` command: Dokumentationen auf BookStack hochladen und verwalten (upload, upload-dir, list, create-book, create-chapter, search, delete)
- `skills/bookstack/SKILL.md`: BookStack REST API Referenz (Auth, Endpunkte, curl-Snippets, Fehlerbehandlung)
- `.gitattributes`: Enforces LF line endings for `*.sh` and `*.py` files
- Intent-router keywords: `architektur`, `systemdesign`, `migration`, `dokument`, `analysier`, `vergleich`, `deploy` (without -ment), `schwachstell`, `brainstorm` (without -ing), and many more

### Changed
- SVG header redesigned in terminal/ASCII-art style (Catppuccin Mocha palette)
- `docs/plans/` removed from repo and added to `.gitignore` (session-specific, not plugin code)

---

## [0.6.1] — 2026-02-23

### Added
- `hooks/scripts/url-scraper.py`: Auto-scrapes non-YouTube URLs in user prompts (Firecrawl → trafilatura → curl fallback)
- Intent-router: Utility command routing for `yt-transcript`, `screenshot`, `web-research`
- Intent-router: Generic URLs suppressed via `hook_handled` flag (no false routing to builder/researcher)
- `/cwe:init` Step 1f: SearXNG/Firecrawl configuration with connectivity test

### Changed
- Hook chain order: intent-router → **url-scraper** → idea-observer → yt-transcript
- `commands/yt-transcript.md`: Deduplicated — now calls existing hook script instead of inline Python
- `commands/web-research.md`: All scraping outputs now JSON-formatted for machine consumption
- `commands/screenshot.md`: Added cleanup step (removes temp PNG after analysis)
- `commands/yt-transcript.md`, `screenshot.md`, `web-research.md`: Descriptions updated to "MUSS VERWENDET WERDEN" pattern

---

## [0.6.0] — 2026-02-23 (Hybrid Delegation Release)

### Changed
- Version bump 0.5.4 → 0.6.0 across all files (plugin.json, CLAUDE.md, README, help.md, session-start.sh, USER-GUIDE, header SVG)
- Agent routing now hook-driven (systemMessage) instead of prose-based (CLAUDE.md tables)
- Fallback chain: intent-router hook → agent descriptions → auto-delegation skill
- `docs/ARCHITECTURE.md`: Added Intent Router Hook section with fallback chain documentation

---

## [0.5.4] — 2026-02-23

### Changed
- **CLAUDE.md radically reduced** from 98 to ~8 lines — behavioral corrections only, routing moved to hook
- All 10 command descriptions sharpened with "MUSS VERWENDET WERDEN für..." pattern (German imperative)

### Removed
- Routing tables, Decision Flow, Quick Reference, Idea Capture docs from CLAUDE.md (moved to hook + skills)

---

## [0.5.3] — 2026-02-23

### Added
- `hooks/scripts/intent-router.py`: UserPromptSubmit hook for automatic agent routing
- Keyword-based intent detection routes prompts to correct CWE agent via systemMessage
- Multi-agent detection (2+ agents matched) triggers delegator skill for compound requests
- Registered intent-router as first hook in UserPromptSubmit chain (before idea-observer)

---

## [0.5.2] — 2026-02-23

### Added
- `commands/yt-transcript.md`: YouTube transcript extraction command (no API key required)
- `hooks/scripts/yt-transcript.sh`: UserPromptSubmit hook auto-detects YouTube URLs
- Pure Python 3 stdlib implementation — no API keys, no dependencies

---

## [0.5.1] — 2026-02-20

### Added
- `skills/delegator/SKILL.md`: Multi-agent request coordination — decomposes multi-step requests into sub-tasks with dependency ordering and wave-based parallel dispatch
- `hooks/scripts/_lib.sh`: Shared helper library for all hook scripts (`json_escape`, `json_msg`, `grep_count`, `line_count`, `resolve_root`, `resolve_slug`)
- `templates/statusline.py`: Statusline template for automatic installation during `/cwe:init`
- `docs/ARCHITECTURE.md`: Plugin architecture documentation (plugin structure, agent system, hook flow, skill system, memory)
- `commands/init.md`: Step 1e — automatic statusline installation after currency config

### Fixed
- **All hook scripts**: Hardened JSON output via shared `_lib.sh` — prevents newlines, unescaped quotes, backslashes, and tabs from breaking JSON
- `hooks/scripts/idea-flush.sh:24`: **Root cause of "JSON validation failed"** — `grep -c || echo 0` produced `0\n0` (newline in JSON) when no raw ideas existed; now uses `grep_count` wrapper
- `hooks/scripts/idea-observer.sh`: Escape order bug (backslashes before quotes) + now uses `json_escape` for all user input
- `hooks/scripts/session-start.sh`: Replaced custom `json_escape_stdin` with shared `json_escape`; bumped version to v0.5.1
- `hooks/scripts/subagent-stop.sh`: Removed redundant dead-code guard (duplicate memory directory check)
- `hooks/scripts/session-stop.sh`: Replaced stale placeholder comment with accurate description
- `agents/builder.md`: Removed `@workflow/product/architecture.md` reference (file never created by init)
- `docs/ARCHITECTURE.md`: Removed non-existent `orchestrator.md` agent, fixed `rules/` → `.claude/rules/` path
- `docs/USER-GUIDE.md`: Fixed "13 Slash Commands" → "16", added missing `plugins`, `screenshot`, `web-research`; replaced stale `.mcp.json` troubleshooting with `claude mcp` CLI instructions
- `commands/plugins.md`: Fixed misleading "14/16 loaded" example to show success case
- 8 agents: Removed dead `@workflow/product/architecture.md` and `@workflow/product/roadmap.md` references (files never created by init)

### Changed
- Version bump 0.5.0 → 0.5.1 across all files (plugin.json, CLAUDE.md, README.md, help.md, USER-GUIDE.md, session-start.sh)
- `README.md`: Added explanation for `--dangerously-skip-permissions` flag, mentioned statusline setup in Quick Start
- `.gitignore`: Hardened — protects private data (cwe-settings.yml, agent-memory, *.local.md/json/yml, credentials, keys, IDE settings)
- `.claude/cwe-settings.yml`: Removed from tracking (user-local preference, created by `/cwe:init`)
- `skills/web-research/SKILL.md` + `commands/web-research.md`: Replaced hardcoded private server URLs with configurable `${SEARXNG_URL}` / `${FIRECRAWL_URL}` environment variables; URLs now set per-project in `.claude/cwe-settings.yml`
- Git history: Scrubbed all traces of private infrastructure addresses via `git-filter-repo`
- `commands/init.md`: Fixed statusline path `.sh` → `.py` (was copying Python file with wrong extension)
- `templates/statusline.py`: Fixed self-reference comment to `.py`
- `templates/memory/sessions.md`: Deleted (deprecated since v0.4.2, replaced by daily logs)
- `ROADMAP.md`: Updated active `sessions.md` references to daily logs

---

## [0.5.0] — 2026-02-19

### Added
- **Statusline**: Python-based status bar showing context usage, session cost, time, and lines changed — configurable via `python3 ~/.claude/statusline.sh`
- **Currency configuration**: `/cwe:init` now asks for preferred currency (EUR, USD, GBP, CHF) — stored in `.claude/cwe-settings.yml`
- **Project settings file**: `.claude/cwe-settings.yml` — per-project configuration (first setting: currency)
- **Statusline features**: color-coded context bar (green/yellow/red), token count, cost conversion, session duration, lines added/removed, project directory name

### Changed
- `commands/init.md`: Added Step 1d (currency selection) to initialization flow
- `hooks/hooks.json`: PreCompact hook changed from prompt-type to command-type (`session-stop.sh`) — eliminates "JSON validation failed" errors
- `.claude/rules/documentation-standards.md`: Softened wording — documentation updates now conditional on `memory/` directory existence
- Version bump: 0.4.4 → 0.5.0 across all files

### Removed
- Stop hook prompt: Removed the "Session is ending, update documentation" prompt hook that caused errors on every session end
- `docs/plans/`: Deleted obsolete design documents (memory-mcp server design, phase 2 plan, memory-system-v2 design)

### Fixed
- Stop hook "JSON validation failed" error: caused by aggressive prompt hook enforcing documentation updates
- Statusline showing `Context: --` instead of actual usage: replaced bash/jq script with Python for broader compatibility

---

## [0.4.4] — 2026-02-19

### Added
- `commands/screenshot.md`: Multi-OS screenshot from clipboard (WSL2, macOS, Wayland, X11)
- `skills/web-research/SKILL.md`: Local web search via SearXNG + scraping via Firecrawl/trafilatura

### Removed
- `cwe-memory-mcp/`: Entire MCP server removed (replaced by Serena memory system)
- `.mcp.json`: cwe-memory server entry removed
- `docs/plans/2026-02-13-memory-mcp-server-design.md`: Obsolete design doc
- `docs/plans/2026-02-13-memory-mcp-phase2-plan.md`: Obsolete design doc

### Fixed
- Stop hook order: command hooks now run before prompt hook (prevents "No assistant message" error)
- Stop hook prompt: shortened and made more resilient for short sessions
- `session-start.sh`: Agent delegation list now includes ask and guide agents
- `subagent-stop.sh`: Fixed logic error — no longer tries to write daily log when memory/ doesn't exist
- `commands/init.md`: Fixed domain count from 7 to 8 (documentation was missing)
- `commands/help.md`: Replaced Memory MCP Server reference with Serena memory

### Changed
- Version bump: 0.4.3 → 0.4.4 across all files (plugin.json, CLAUDE.md, help.md, session-start.sh, README, USER-GUIDE)
- All cwe-memory references removed from README, CHANGELOG, ROADMAP, USER-GUIDE, .gitignore

---

## [0.4.3] — 2026-02-13

### Added — Documentation
- `docs/USER-GUIDE.md`: comprehensive user documentation (~1000 lines, 15 sections)
- `docs/assets/cwe-logo.svg`: minimalist CWE logo (indigo/violet gradient)
- `docs/assets/cwe-header.svg`: GitHub README banner (800x200, dark-mode compatible)
- `README.md`: complete rewrite with HTML design, SVG header, shields.io badges, collapsible sections
- `commands/help.md`: updated to v0.4.3 with 6th principle, memory search, safety gate, git standards

---

## [0.4.2] — 2026-02-13 (Memory System v2 — Phase 1)

### Added — Daily Logs
- Daily log files (`memory/YYYY-MM-DD.md`): append-only session context per day
- `session-start.sh`: injects MEMORY.md + today + yesterday daily logs as systemMessage (max 8000 chars)
- Auto-seeding: `/cwe:init` detects tech stack and populates memory/project-context.md + MEMORY.md
- Daily log template: `templates/memory/daily-log.md` (format reference)
- First daily log created automatically at `/cwe:init`
- Old daily logs auto-cleaned after 30 days

### Changed — Memory System
- `session-stop.sh`: writes to daily logs instead of sessions.md
- Stop hook prompt: references daily logs instead of sessions.md
- PreCompact hook prompt: references daily logs instead of sessions.md
- `documentation-standards.md`: daily log added to required memory updates checklist
- `MEMORY.md` template: references daily logs, added Daily Logs section

### Deprecated
- `sessions.md`: replaced by daily logs (kept for backward compatibility)

---

## [0.4.1] — 2026-02-13 (Native Alignment Release)

### Changed — Native Alignment (Phase 1-3)
- CLAUDE.md radical slim-down (~230 → ~72 lines)
- Standards migration from Skills to `.claude/rules/` with `paths` frontmatter (YAML list format)
- Agent frontmatter modernization (`skills:`, `memory: project` fields)
- Rules paths format: corrected to YAML list per Claude Code docs

### Changed — Memory & Idea System (Phase 4)
- Idea system v2: project-scoped via `$CLAUDE_PROJECT_DIR`, JSONL format
- idea-observer.sh: writes to `~/.claude/cwe/ideas/<project-slug>.jsonl`
- idea-flush.sh: counts only current project's ideas
- session-start.sh: reads memory/sessions.md for resume context, shows idea count
- session-stop.sh: logs sessions to memory/sessions.md, keeps last 50
- Migration: old `.toon` → per-project JSONL on first run
- Memory templates: MEMORY.md, ideas.md, sessions.md, decisions.md, patterns.md, project-context.md
- commands/innovator.md: 4 modes (default/all/review/develop)

### Removed — Redundant Skills (Phase 5)
- 10 skills deleted: 7 standards (→ .claude/rules/), cwe-principles (→ CLAUDE.md), planning (→ native), mcp-usage (obsolete)
- Remaining: auto-delegation, agent-detection, quality-gates

### Added — Hooks Modernization (Phase 6)
- SubagentStop hook for agent execution observability
- subagent-stop.sh: logs agent completions to memory/sessions.md

### Changed — Documentation Consistency
- README.md: v0.4.1, memory system, standards system, idea capture documented
- commands/help.md: v0.4.1, standards system, memory system, idea JSONL
- commands/init.md: memory/ scaffolding, updated ideas.md template, standards reference
- commands/start.md: Shape-Spec Interview option, spec folder structure
- auto-delegation skill: context injection updated from Skills to .claude/rules/
- plugin.json: version 0.4.1, simplified description
- ROADMAP.md: Phase 1-6 marked as completed, summary table updated

### Added — Spec System + Project Documentation (Phase 7)
- Spec folder templates: `templates/specs/` (plan.md, shape.md, references.md, standards.md)
- Shape-Spec Interview: `/cwe:architect shape` with structured interview flow
- docs/ templates: `templates/docs/` (README, ARCHITECTURE, API, SETUP, DEVLOG, decisions/_template)
- VERSION file template as Single Source of Truth for version strings
- `skills/project-docs/SKILL.md`: README generation, docs freshness check, VERSION cascade
- commands/architect.md: shape mode with 5-step interview + spec folder generation
- commands/researcher.md: `docs update|check|adr` modes
- commands/devops.md: `release patch|minor|major` mode with VERSION cascade
- commands/init.md: docs/ scaffolding + VERSION in project structure
- agents/researcher.md: expanded docs responsibilities with project-docs skill
- agents/devops.md: release flow with VERSION SSOT + project-docs skill

### Added — Pre-Commit Safety Gate (Phase 8)
- `hooks/scripts/safety-gate.sh`: scans for secrets, API keys, PII, credentials, dangerous file types
- PreToolUse hook on Bash: triggers safety-gate.sh on git commit/push/add -A
- `skills/safety-gate/SKILL.md`: describes scanning rules + remediation guidance
- .gitignore validation (required entries: .env, *.pem, *.key, node_modules/, .DS_Store)

### Added — Git Workflow Standards (Phase 9)
- `skills/git-standards/SKILL.md`: Conventional Commits format + branch naming conventions
- `hooks/scripts/commit-format.sh`: validates commit message format on git commit -m
- `hooks/scripts/branch-naming.sh`: validates branch names on git checkout -b / git switch -c
- PreToolUse hooks for commit-format.sh and branch-naming.sh
- Auto-generated release notes spec (via /cwe:devops release)

### Added — Project Health Dashboard (Phase 10)
- `skills/health-dashboard/SKILL.md`: project health metrics (code quality, deps, docs, git, security)
- Health score calculation (0-100) with rating system
- CODEOWNERS auto-generation from git history
- `/cwe:quality health` command mode
- Quality agent: health dashboard integration
- Guide agent: health insights for process improvement suggestions

### Added — Always Document Principle
- 6th Core Principle: "Always Document" — every change updates memory, CHANGELOG, docs
- `.claude/rules/documentation-standards.md`: always-active rule with documentation checklist
- Stop hook (prompt-based): forces memory/MEMORY.md + sessions.md update before session end
- PreCompact hook (prompt-based): forces memory save before context compaction
- MCP server installation in `/cwe:init` (playwright, context7, github, filesystem, sequential-thinking)

---

## [0.4.0a] — 2025-02-13

### Changed
- **Skill overlap resolved:** `auto-delegation` and `agent-detection` now have sharp scope boundaries
  - `auto-delegation` = interactive user-request routing (natural language)
  - `agent-detection` = build-phase task-to-agent assignment (structured tasks)
- **Keyword tables synchronized** across auto-delegation, agent-detection, and CLAUDE.md
  - "test" consistently routes to **quality** agent (was inconsistent)
  - Unified canonical keyword list for all 10 agents
- **Greptile references removed** — replaced with Serena tools
- **Version consistency fixed** — `session-start.sh` updated from v0.3.1 to v0.4.0a

### Added
- `CHANGELOG.md` — this file
- `ROADMAP.md` — v0.4.1 planning and design decisions
- `_backup/` — pre-change backup of modified files

---

## [0.4.0a] — Initial Plugin Release

### Added
- Full plugin structure (`.claude-plugin/plugin.json`)
- 10 specialized agents: ask, architect, builder, devops, explainer, guide, innovator, quality, researcher, security
- 13 commands: 3 core (init, start, help) + 10 agent commands
- 13 skills: auto-delegation, agent-detection, quality-gates, planning, cwe-principles, mcp-usage, and 7 domain standards
- Plugin integration: superpowers, serena, feature-dev, frontend-design, code-simplifier, claude-md-management, plugin-dev
- Idea capture system via UserPromptSubmit hook
- Session hooks (start, stop, idea-flush)
- Interactive menus via AskUserQuestion in all commands
- Wave execution algorithm for parallel task orchestration

---

## [0.3.1] — Pre-Plugin Version

### Changed
- Simplified to 12 commands, auto-delegation, superpowers integration

---

## [0.3.0] — Plugin Structure Created

### Added
- Initial plugin directory structure

---

## [0.2.9a] — Last CLI-Focused Version

### Changed
- Final version before plugin migration
