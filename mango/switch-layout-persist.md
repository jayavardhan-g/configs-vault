# SUPER+n persists the layout it cycles to

**Date:** 2026-09-14
**Category:** mango
**Files touched:** `~/.config/mango/cfg/keybinds.conf`, `~/.config/mango/scripts/switch-layout-persist.sh` (new)

<!-- graph:begin -->
**Graph:** [[Mango]]
<!-- graph:end -->

## What
`SUPER+n` still cycles the current tag's layout through `circle_layout` exactly as
before, but now also writes the result into `layout.conf`'s `tagrule` for that tag id —
so whatever you land on survives a Mango restart, instead of only lasting for the
session (Mango's own `switch_layout` dispatch is runtime-only, confirmed live that a
plain `reload_config` reverts it back to whatever `tagrule` says).

## Why
User wants to experiment with layouts live via `SUPER+n` (as already set up in
[[default-layout-per-tag]]) without a separate manual step to make a chosen layout
permanent.

## Change

`~/.config/mango/cfg/keybinds.conf`:
```
# Switch layout - persists the result into layout.conf's tagrule so it
# survives a restart, instead of only lasting for the session (see
# switch-layout-persist.sh)
bind = SUPER, n, spawn, /home/jayavardhan/.config/mango/scripts/switch-layout-persist.sh
```

`~/.config/mango/scripts/switch-layout-persist.sh` (new):
```bash
#!/usr/bin/env bash
set -uo pipefail

LAYOUT_CONF="$HOME/.config/mango/cfg/layout.conf"

mmsg dispatch switch_layout >/dev/null 2>&1
sleep 0.15

monitor=$(mmsg get all-monitors | jq -r '.monitors[] | select(.active==true) | .name')
[ -z "$monitor" ] && exit 0

tag_info=$(mmsg get tags "$monitor" | jq -r '.active_tags[0] as $t | .tags[] | select(.index==$t) | "\(.index) \(.layout)"')
tag_id=$(awk '{print $1}' <<<"$tag_info")
symbol=$(awk '{print $2}' <<<"$tag_info")
[ -z "$tag_id" ] && exit 0

layout_name=$(mmsg get layouts | jq -r --arg s "$symbol" '.layouts[] | select(.symbol==$s) | .name')
[ -z "$layout_name" ] && exit 0

python3 - "$LAYOUT_CONF" "$tag_id" "$layout_name" <<'PYEOF'
import re, sys

path, tag_id, layout_name = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    lines = f.readlines()

pattern = re.compile(rf"^tagrule\s*=\s*id:{tag_id}\s*,\s*layout_name:\S+")
replacement = f"tagrule = id:{tag_id}, layout_name:{layout_name}\n"

found = False
for i, line in enumerate(lines):
    if pattern.match(line.strip()):
        lines[i] = replacement
        found = True
        break

if not found:
    last_tagrule = max((i for i, l in enumerate(lines) if l.strip().startswith("tagrule")), default=len(lines) - 1)
    lines.insert(last_tagrule + 1, replacement)

with open(path, "w") as f:
    f.writelines(lines)
PYEOF
```

## Notes
- Reads the symbol-to-name mapping live from `mmsg get layouts` rather than
  hardcoding it, so it stays correct if a future Mango version adds/renames layouts.
- Rewrites the specific `tagrule = id:<N>, layout_name:...` line for whichever tag id
  was actually active on the currently-focused monitor (`.active==true`) at the time —
  since `tagrule` here has no `monitor_name` (applies to every monitor, see
  [[default-layout-per-tag]]), the new layout takes effect for that tag id everywhere,
  not just the monitor you cycled it on.
- If no `tagrule` line exists yet for that tag id (e.g. a tag beyond what's currently
  configured), the script appends a new one after the last existing `tagrule` line
  rather than failing silently.
- Confirmed live: cycling tag 3 from `scroller` to `vertical_scroller` updated both the
  live layout and the `layout.conf` line, and a subsequent `reload_config` kept
  `vertical_scroller` (proving it's now the persisted value, not a leftover runtime
  state) rather than reverting to the old `scroller`.
