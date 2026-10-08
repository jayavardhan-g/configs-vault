# Tried and reverted: dedicated Xpad tag on Mango

**Date:** 2026-09-14
**Category:** mango
**Files touched:** none (fully reverted — was `~/.config/mango/cfg/layout.conf`,

<!-- graph:begin -->
**Graph:** [[Mango]] · [[Monitors]] · [[Xpad]]
<!-- graph:end -->

`~/.config/mango/cfg/rules.conf`, `~/.config/mango/cfg/keybinds.conf`)

## What was tried
Ported the Hyprland feature (`cachyos/window-management/xpad-workspace-and-monitor-persistence.md`
— notes on a dedicated workspace, monitor-aware) to Mango: bumped `tag_num` 4→5, added a
`windowrule = appid:xpad, tags:5, isfloating:1, ...` to pin Xpad windows there, and
`SUPER+5`/`SUPER+SHIFT+5` binds matching the existing 1-4 pattern. Fully reverted 2026-09-14
— Mango is back to `tag_num = 4`, the `appid:xpad` windowrule is removed, and the tag-5
binds are removed. No Mango config now differs from stock because of Xpad.

## Why reverted
The dedicated-tag approach was built in stages, each catching a real problem:

1. **Auto-launch on startup + auto-migrate-to-external-monitor via a background watcher
   daemon** — built, live-verified working end to end (real Xpad app, real notes, real
   external-monitor disable/enable round trip). Reverted first: repeatedly restarting
   Xpad during that testing exposed that Xpad **autosaves its position on its own**, not
   only on a clean `--quit`, and can write a broken transient position to disk during its
   own internal startup race. This corrupted both notes' real saved positions twice
   during testing (caught and restored both times from values captured earlier in the
   same session). User asked to drop the automation and place notes manually instead.

2. **Manual placement (switch to tag 5, launch Xpad there yourself)** — still didn't work
   as expected: notes kept opening on the laptop screen regardless of which monitor had
   focus. Root-caused to Xpad's own behavior, not Mango's: a disposable test window using
   the *exact same* `windowrule` (floating, `tags:5`, same fields) correctly followed
   Mango's focused monitor every time it was tested live — so the placement mechanism
   itself works. Xpad specifically did not, even with focus confirmed on `HDMI-A-1` via
   `mmsg get all-monitors`'s `active` field beforehand. Most likely explanation (not
   fully confirmed): Xpad is a single long-running process, and asking it for another
   note while it's already running doesn't re-derive the current compositor focus — it
   defaults to wherever its own internal state points (probably fixed from when it first
   started). A fresh-process launch was suggested as a next test to isolate this, but the
   user asked to abandon the approach entirely before that was tried.

Net result: a dedicated tag for Xpad doesn't reliably solve "notes open on the monitor I
want" on Mango, because the actual blocker is inside Xpad's own multi-window handling, not
anything Mango-side config can fix. **Don't retry the dedicated-tag/windowrule approach on
Mango without first confirming (via a genuinely fresh Xpad process per note, not "new
note" from an already-running instance) whether Xpad ever respects current compositor
focus for anything other than its very first window.**

## Notes (general Mango/mmsg facts learned along the way, may be useful for unrelated features)
- **`mmsg`'s `active` field on a monitor means "currently focused," not
  "connected/enabled."** A monitor can be fully connected and rendering a fullscreen
  client while showing `active:false`, simply because another monitor was last focused.
  The real "is this monitor known to the compositor" signal is presence of its name in
  `mmsg get all-monitors`' `monitors` array.
- **A new client's initial monitor assignment follows Mango's currently-focused monitor**
  (confirmed live, repeatedly, with plain disposable windows, both tiled and floating via
  a `windowrule` matching `isfloating:1` + explicit `width`/`height`) — `mmsg dispatch
  focusmon,<name>` reliably controls where the next new window lands.
- **`isfloating:1` in a `windowrule` silently does nothing without `width`/`height` in
  the same rule** — confirmed live: alone it left a window tiled; adding explicit
  `width`/`height` made it float immediately. The seed size doesn't stick permanently —
  a `mmsg dispatch resizewin,...` right after creation cleanly overrides it.
- **`tagmon,<dest> client,<id>`** moves a client to another monitor but drops it onto
  whatever tag the *destination* monitor currently happens to be showing (per a
  pre-existing comment in this machine's `keybinds.conf` referencing
  `client_reset_mon_tags`), not the tag it came from. Following it with `mmsg dispatch
  tagsilent,<tag>,0 client,<id>` fixes the tag without switching the destination
  monitor's visible view (unlike the non-silent `tag` dispatch, confirmed live to also
  yank the destination's current view to match).
- **Mango's own monitor-removal handling moves every client from a removed monitor onto
  the remaining one, preserving each client's exact tag number** — confirmed live via
  `mmsg dispatch disable_monitor,<name>` with real windows present, and reversed
  correctly on `enable_monitor`. Caveat: only tested via that software toggle, which
  keeps the same output object alive (stays listed in `mmsg get all-monitors` even while
  disabled) — a genuine cable unplug/replug likely destroys and recreates the output
  object instead, which was not independently verified.
- **`tag_num` is a single global setting, not per-monitor** — confirmed live via `mmsg
  get all-monitors`: every monitor always reports the same `tag_num`.
- **Xpad's own saved position coordinates are in a different space than what `mmsg`
  reports/accepts** — confirmed live: a *correctly* self-restored note's saved `x` in its
  `~/.config/xpad/info-*` file differed from its live `mmsg` `x` by roughly 400px, with
  no consistent scale/offset relating different notes' numbers. Don't attempt an `mmsg
  movewin`/`resizewin`-based fix using Xpad's saved info-file values directly — this was
  tried and contributed to the position corruption above.
