# Multi-monitor setup: scale, position, workspace count, and monitor keybinds

**Date:** 2026-09-14
**Category:** mango
**Files touched:** `~/.config/mango/cfg/monitors.conf`, `~/.config/mango/cfg/layout.conf`, `~/.config/mango/cfg/misc.conf`, `~/.config/mango/cfg/keybinds.conf`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Mango]] · [[Monitors]]
<!-- graph:end -->

## What
UI scale matched to the Hyprland setup, workspace count reduced from the
default 9 to 4, and a set of keybinds for focusing/moving windows to a
specific monitor by name. Cross-monitor focus-follow via `hjkl`/arrows
(`focus_cross_monitor`) was enabled to match Hyprland initially, then turned
back off on 2026-09-17 — see Notes.

## Why
User wanted parity with the existing two-monitor Hyprland setup (laptop
`eDP-1` + external `HDMI-A-1`, both at 1.25 scale originally, later
adjusted to 1.1) and a smaller, more manageable workspace count.

## Change

`~/.config/mango/cfg/monitors.conf` (current values, scale bumped to `1.2` on
`eDP-1` since the table above, `HDMI-A-1` left at `1`; `x:1670` is a
deliberate ~70px gap, not true edge-to-edge — see Notes):
```
monitorrule = name:eDP-1, x:0, y:0, scale:1.2
monitorrule = name:HDMI-A-1, x:1670, y:0, scale:1
```

`~/.config/mango/cfg/layout.conf`:
```
tag_num = 4
```
(with `tagrule` trimmed to just `id:1` through `id:4` — see [[keybinds]])

`~/.config/mango/cfg/misc.conf` (current value — see Notes for the
2026-09-17 flip from `1` to `0`):
```
focus_cross_monitor = 0
```

`~/.config/mango/cfg/keybinds.conf` — final monitor keybind scheme:
```
# Switch between monitors - bracketleft/right ([ = laptop, ] = monitor,
# matches the physical eDP-1/HDMI-A-1 left-right arrangement) and by
# direction (kept as an alternative)
bind = SUPER, bracketleft, focusmon, eDP-1
bind = SUPER, bracketright, focusmon, HDMI-A-1
bind = SUPER+ALT, Left, focusmon, left
bind = SUPER+ALT, Right, focusmon, right
# Move window to another monitor - lands on whichever tag the destination
# monitor is currently showing (confirmed via source, client_reset_mon_tags)
bind = SUPER+SHIFT, bracketleft, tagmon, eDP-1
bind = SUPER+SHIFT, bracketright, tagmon, HDMI-A-1
bind = SUPER+SHIFT+ALT, Left, tagmon, left
bind = SUPER+SHIFT+ALT, Right, tagmon, right
```
`SUPER+1..4`/`SUPER+SHIFT+1..4` stayed on plain workspace switching/move —
see Notes for why an attempt to match Hyprland's exact `SUPER+1`/`SUPER+2`
monitor-focus convention was tried and abandoned.

## Notes
- **`focusmon`/`tagmon` accept a monitor name directly, not just a
  direction.** Confirmed via the config parser (`src/dispatch/bind.c`):
  the argument is first checked against direction keywords
  (`left`/`right`/etc.); if it doesn't match one, it's used as a literal
  monitor name instead (`match_monitor_spec`). This isn't documented
  anywhere obvious - found by reading the parser directly.
- **Mango's tags are per-monitor, not a shared pool** — unlike Hyprland,
  where workspace numbers are global and get bound to specific monitors.
  Each monitor independently has its own full set of tags 1 through
  `tag_num`, confirmed live via `mmsg get all-tags` (each monitor listed its
  own separate `tags` array with independent `active_tags`/client counts).
  There's no way to "reserve tags 1-5 for the laptop and 6-9 for the
  monitor" the way you could bind Hyprland workspaces to outputs — pressing
  `SUPER+1` on either monitor already only ever affects that monitor's own
  tag 1, they never collide in the first place.
- **Auto monitor-position broke after a live scale change** — after
  changing `scale` from `1.25` to `1.1` via a live edit + reload, the two
  monitors ended up overlapping (`HDMI-A-1` at `x=1920`, `eDP-1` at
  `x=3456` — stale numbers left over from before the scale change, not
  recalculated). Fix was to stop relying on any auto-placement and pin `x`/
  `y` explicitly for both outputs, recomputed for the current scale
  (`physical_width / scale`, confirmed against `mmsg get all-monitors`
  output each time). If scale changes again, position needs recomputing
  too - it does not self-correct.
- **This bit again (2026-09-16), the opposite direction**: `eDP-1`'s scale
  was later bumped from `1.1` to `1.2` but `HDMI-A-1`'s `x` offset was left
  at `1745` (the value correct for `1.1`: `1920/1.1≈1745`), not recalculated
  for `1.2` (`1920/1.2=1600`). This left a **146px dead zone** between the
  two monitors where no output existed at all - moving the cursor slowly
  toward the right edge of the laptop screen got stuck right at the real
  edge (`x=1599`), while a fast flick's single pointer-motion event covered
  more than 146px in one jump and landed past the gap onto the external
  monitor. This was initially mistaken for a deliberate "slow stops, fast
  crosses" WM feature rather than a stale-offset bug, until `mmsg get
  all-monitors` showed the actual gap. First fixed to `x:1600` (true
  edge-to-edge, gap removed entirely) — but the "stops slow, crosses fast"
  feel turned out to be liked on its own merits once it was understood, so
  it was reintroduced on purpose at roughly half the size: `x:1670`, a
  ~70px gap. Lesson stands even more firmly now: **any scale change on
  either monitor requires recalculating the other's position offset** (true
  edge-to-edge is `x:1600` here) as the baseline, whether or not a
  deliberate gap is then added on top.
- **Tried and abandoned: matching Hyprland's exact `SUPER+1`/`SUPER+2` for
  monitor-focus and `SUPER+SHIFT+1`/`2` for move-to-monitor.** This
  collides directly with plain-digit workspace switching in Mango (unlike
  Hyprland, which reserves bare digits for monitor-focus and puts
  workspaces on `ALT`/`CTRL`-modified digits instead). Went through a full
  remap (workspace switching relocated to `SUPER+ALT+1..4` /
  `SUPER+SHIFT+ALT+1..4`) before deciding it wasn't worth the disruption and
  reverting workspace switching back to plain digits, using
  `bracketleft`/`bracketright` for monitor-focus/move instead - confirmed
  free of any conflict, including checked against every Mango layout's
  documented keybindings (none of them reserve bracket keys either).
- **`circle_layout = dwindle,tile,scroller,vertical_scroller`** was added to
  `layout.conf` so the already-bound `SUPER+N` (`switch_layout`) cycles
  through these on the current tag, for trying different layouts live
  before picking one permanently. Not yet settled on a final choice.
- See [[known-bugs]] for a real, currently-unfixed upstream bug that
  surfaced during this testing: moving a window onto a monitor with an
  active fullscreen client leaves keyboard focus stuck.
- **`focus_cross_monitor` turned back off (2026-09-17)**: after switching
  tag 1 to `vertical_scroller`, `SUPER+j`/`k` started landing on `HDMI-A-1`
  on every vertical edge press - confusing, since the monitors are laid out
  horizontally, not vertically (see [[known-bugs]] for the full
  `monitor_from_direction()` source-level explanation of why `up`/`down`
  specifically triggered this). Since `focus_cross_monitor` is a single flag
  covering all four directions with no per-direction option, and explicit
  monitor switching already exists on `SUPER+[`/`]` (bound above,
  unaffected by this flag - `focusmon`/`tagmon` don't go through
  `focus_cross_monitor` at all), the flag was just turned off entirely
  rather than attempting a partial/scripted fix. Confirmed via `mmsg`:
  `dispatch focusdir,right` no longer changes `get focusing-client`'s
  reported monitor, while `dispatch focusmon,HDMI-A-1` still switches
  normally.
