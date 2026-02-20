#!/usr/bin/env python3
"""Claude Code Statusline — Context + Usage (single line)
Installed by CWE /cwe:init to ~/.claude/statusline.py
"""
import json, sys, os

data = json.load(sys.stdin)

# ── Colors ──
B = '\033[1m'
DIM = '\033[2m'
GREEN = '\033[32m'
YELLOW = '\033[33m'
RED = '\033[31m'
CYAN = '\033[36m'
MAGENTA = '\033[35m'
R = '\033[0m'

# ── Model ──
model = data.get('model', {}).get('display_name', '?')

# ── Context Window ──
cw = data.get('context_window', {})
pct = cw.get('used_percentage')
window_size = cw.get('context_window_size', 0) or 0

cu = cw.get('current_usage') or {}
input_tk = (cu.get('input_tokens', 0) or 0) + \
           (cu.get('cache_creation_input_tokens', 0) or 0) + \
           (cu.get('cache_read_input_tokens', 0) or 0)

def fk(n):
    return f"{n/1000:.0f}k" if n >= 1000 else str(n)

# ── Cost / Duration / Lines ──
cd = data.get('cost', {})
cost = cd.get('total_cost_usd', 0) or 0
dur = cd.get('total_duration_ms', 0) or 0
added = cd.get('total_lines_added', 0) or 0
removed = cd.get('total_lines_removed', 0) or 0

m, s = dur // 60000, (dur % 60000) // 1000

# ── Context bar ──
BAR_W = 8
if pct is not None:
    p = int(pct)
    c = GREEN if p < 50 else YELLOW if p < 75 else RED
    filled = max(p * BAR_W // 100, 1 if p > 0 else 0)
    bar = f"{c}{'━' * filled}{DIM}{'─' * (BAR_W - filled)}{R}"
    ctx = f"context {bar} {c}{B}{p}%{R} {DIM}{fk(input_tk)}/{fk(window_size)}{R}"
else:
    ctx = f"context {DIM}{'─' * BAR_W} 0% 0/{fk(window_size)}{R}" if window_size else f"context {DIM}--{R}"

# ── Currency config from CWE settings ──
currency = "EUR"
try:
    proj = os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd())
    cfg = os.path.join(proj, '.claude', 'cwe-settings.yml')
    if os.path.isfile(cfg):
        with open(cfg) as f:
            for line in f:
                if line.strip().startswith('currency:'):
                    currency = line.split(':', 1)[1].strip().upper()
except Exception:
    pass

# Conversion rates from USD
rates = {"USD": 1.0, "EUR": 0.92, "GBP": 0.79, "CHF": 0.88, "JPY": 149.5, "CAD": 1.36, "AUD": 1.53}
symbols = {"USD": "$", "EUR": "EUR", "GBP": "GBP", "CHF": "CHF", "JPY": "JPY", "CAD": "CAD", "AUD": "AUD"}
rate = rates.get(currency, 1.0)
sym = symbols.get(currency, currency)
converted = cost * rate

parts = []
if cost > 0:
    parts.append(f"{YELLOW}{sym} {converted:.2f}{R}")
parts.append(f"time {CYAN}{m}m{s:02d}s{R}")
if added or removed:
    parts.append(f"lines {GREEN}+{added}{R}{DIM}/{R}{RED}-{removed}{R}")

right = f"  {DIM}|{R}  ".join(parts)

# ── Output ──
dir_name = os.path.basename(data.get('workspace', {}).get('current_dir', ''))
print(f"{CYAN}{dir_name}{R}  {DIM}|{R}  {ctx}  {DIM}|{R}  {right}")
