# Interaction settings not previously explored: hot corners, floating snap, speed-gated scroller focus

**Date:** 2026-09-16
**Category:** mango
**Files touched:** `~/.config/mango/cfg/misc.conf`, `~/.config/mango/cfg/layout.conf`

<!-- graph:begin -->
**Graph:** [[Mango]]
<!-- graph:end -->

## What
Enabled three interaction settings that exist in Mango's default config but
were never sourced into this setup: hot-corner overview trigger, floating-
window edge/corner snapping, and a speed threshold gating when hovering
steals focus onto an off-screen scroller column.

## Why
Came up after noticing the two-monitor cursor-crossing behavior documented
in [[multi-monitor-setup]] (which turned out to be a stale monitor-offset
bug, not a real feature) and asking what other under-explored Mango settings
existed. These three were picked out of the full default config
(`/etc/mango/config.conf`) as genuine, working equivalents of that same
"physical interaction gated by a threshold" feel.

## Change

`~/.config/mango/cfg/misc.conf`:
```
# Hot corner: push the cursor into a screen corner to trigger overview
# (like GNOME's hot corner). hotarea_size is the corner trigger zone in px;
# hotarea_disable_on_fullscreen keeps a fullscreen video/game from
# triggering it accidentally.
enable_hotarea = 1
hotarea_size = 10
hotarea_disable_on_fullscreen = 1

# Windows-style edge/corner snap zones for floating windows (drag near a
# screen edge to snap-resize into a half/corner).
enable_floating_snap = 1
snap_distance = 30
```

`~/.config/mango/cfg/layout.conf` (added next to the existing
`edge_scroller_pointer_focus = 1`; started at `8`, raised to `20` the next
day — see Notes):
```
edge_scroller_focus_allow_speed = 20
```

## Notes
- **`edge_scroller_focus_allow_speed` is the real version of the "slow
  stops, fast crosses" feel** the monitor-gap bug was mistaken for. Read
  directly from Mango's source (`src/input/pointer.c`, ~line 1072): on every
  pointer-motion event, `speed = sqrt(dx^2 + dy^2)` — the raw pixel delta of
  *that single event*, not a real-world speed unit. Hovering onto a
  scroller-tiled window that's off-screen/at the edge of the current view
  only steals focus when `speed >= edge_scroller_focus_allow_speed`; the
  default `0.0` means virtually any movement passes (since speed is only
  ever exactly `0` when the pointer doesn't move at all), so the gate was
  effectively disabled before this change. `8` was picked as a starting
  threshold - a slow, deliberate move is typically 1-3px/event, a fast flick
  is 10px+/event - not an officially documented recommended value; `8`
  turned out to trigger too easily (felt like it fired on a slow move), so
  it was raised to `20` (2026-09-17). Tune up (stricter, needs a faster
  flick) or down (looser) if `20` still doesn't feel right; only takes a
  `reload_config` (`SUPER+F5`) to test, no relogin needed.
- **`SUPER`+scroll (`axisbind`) and the 4-finger left/right swipe
  (`gesturebind`) looked broken but weren't** (2026-09-17): both call
  `..._have_client` dispatch functions (`viewtoleft_have_client`,
  `viewprev_have_client`, etc.), which intentionally skip to a tag only if
  it actually has a client - they no-op if every other tag is empty.
  Confirmed directly: `mmsg dispatch viewtoright_have_client` with tags 2-5
  empty did nothing; after opening a throwaway window on tag 2 and dispatching
  the same function again, the active tag actually changed. 4-finger up/down
  (`enteroverview`/`leaveoverview`) don't depend on tag contents, which is
  why those worked immediately while left/right appeared dead. Not a config
  bug - matches [[keybinds]]'s existing binds using the same convention.
- **`snap_distance = 30` is Mango's own compiled-in default** for
  `enable_floating_snap` - written explicitly here anyway for documentation
  clarity, even though only the `enable_floating_snap = 1` line actually
  changes behavior.
- Confirmed all three actually parse: `mmsg dispatch reload_config` returned
  `{"success":true}` and `mmsg get all-monitors` reflected the
  [[multi-monitor-setup]] position fix made in the same session, with no
  parse errors surfaced.
