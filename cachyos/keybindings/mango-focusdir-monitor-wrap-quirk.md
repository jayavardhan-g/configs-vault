# Known quirk: SUPER+hjkl focus-direction wraps to the other monitor from any edge

**Date:** 2026-09-15
**Category:** keybindings
**Files touched:** none — documented only, not fixed (deliberately left as-is)

<!-- graph:begin -->
**Graph:** [[Mango]] · [[Monitors]]
<!-- graph:end -->

## What
`SUPER+h/j/k/l` (`focusdir`, see [[vim-navigation]]) is supposed to move focus to
the nearest window in that direction, crossing onto the other monitor only when
that's the *geometrically* correct direction to cross in (monitor layout is
`eDP-1` laptop at x:0, `HDMI-A-1` external monitor at x:1745, so only "right from
laptop" / "left from monitor" should ever cross). In practice, running out of
windows locally in **any** of the four directions (h, j, k, or l) jumps to the
other monitor — e.g. `SUPER+h` from the leftmost window on the laptop screen
incorrectly jumps to the monitor on the right, and `SUPER+k`/`SUPER+j` at a
top/bottom edge do the same, even though nothing is above/below either monitor.

## Why
Root-caused in Mango's compiled source, not a config option:
`monitor_from_direction()` (`src/manage/monitor.c` in mangowc, the upstream repo
for the currently-installed custom-built `mangowm 0.17.0`, newer than the
`cachyos` repo's `0.16.1`) first tries `wlr_output_layout_adjacent_output()` for
a real monitor in the requested direction; if that finds nothing, it falls back
to `wlr_output_layout_farthest_output()` in the **opposite** direction instead
of giving up. With exactly two side-by-side monitors, that fallback always
resolves to "the other monitor" no matter which of the four directions was
pressed, since it's the only other monitor that exists.

`focus_cross_monitor = 1` in `misc.conf` (needed for the *correct* case —
crossing right from the laptop's rightmost window, or left from the monitor's
leftmost window) is what enables this code path at all; there is no separate
config flag to allow only the correct-direction crossings and suppress the
opposite-direction fallback.

## Fix (not applied)
Would require patching `monitor_from_direction()` to drop the
`wlr_output_layout_farthest_output` fallback (keep only the real adjacent-output
check), then rebuilding/reinstalling Mango via `shelly` and re-applying the
patch on every future Mango update. Declined for now — not worth rebuilding and
restarting the live compositor for this. Revisit if it becomes annoying enough,
or if upstream mangowc fixes this itself.

## Notes
- This only bites at the true edges (leftmost window on the laptop, rightmost on
  the monitor, or top/bottom edge on either) where there's no window left to
  focus locally — normal same-monitor `hjkl` focus movement is unaffected.
- Cross-referenced from [[vim-navigation]] and
  [[mango-workspace-cycle-wrap]] (a different, already-fixed wrap issue — that
  one was workspace switching via a real config option, `tag_carousel`; this one
  is monitor-focus wrapping with no equivalent option).
