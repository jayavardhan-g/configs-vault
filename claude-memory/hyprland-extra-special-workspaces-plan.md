---
name: hyprland-extra-special-workspaces-plan
description: Shelved plan for 7 named Hyprland scratchpads on SUPER+4..0 - its premise (those keys being free) is false
metadata: 
  node_type: memory
  type: project
  originSessionId: 9a81cd6e-4cb2-4e35-b841-e155a43c540e
  modified: 2026-09-21T11:45:35.369Z
---

**Shelved as of 2026-09-21 — the premise was wrong.** The original plan (2026-09-03) was
to bind `SUPER+4` through `SUPER+0` to 7 independent named special workspaces
(`special:<name>`), each an always-available scratchpad, on the stated basis that
"`SUPER+1/2/3` are already taken for monitor focus" and `SUPER+4..0` were unmapped.

Verified against the live config: **that is not true and may never have been.**
`binds.lua` loops `for i = 1, NUM_WPM * 2` with `NUM_WPM = 3`, so `SUPER+1`..`SUPER+6`
all focus workspaces 1-6 (three per monitor, not "monitor focus"), and `SUPER+7` is the
Xpad notes workspace. Only **`SUPER+8`, `SUPER+9` and `SUPER+0`** are actually free.
Building the plan as written would mean taking four real workspaces away.

**Decision:** not worth doing. There is already one special workspace with a smart
context-aware toggle (`SUPER+S` / `SUPER+SHIFT+S`) plus 7 numbered workspaces. The plan's
own open question — *what each of the 7 scratchpads would be for* — went unanswered for
the whole time it sat here, which is the sign it was a capability idea rather than a felt
need.

**If a second scratchpad is ever actually wanted:** put it on `SUPER+8` (free) and
generalize `toggle_window_special` in `binds.lua` to take a target-name argument instead
of assuming the single unnamed `special`. That is a small change — no reason to pre-build
seven of them. See [[lead-with-simpler-options]].

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Monitors]] · [[Xpad]]
<!-- graph:end -->
