# Known bug: moving a window onto a monitor with a fullscreen client leaves focus stuck

**Date:** 2026-09-14
**Category:** mango (upstream bug, not a config issue)
**Version confirmed on:** 0.17.0 (also present, unfixed, on the `main` branch as of this date)

<!-- graph:begin -->
**Graph:** [[Mango]] · [[Monitors]]
<!-- graph:end -->

## What
Moving a window from one monitor to another (`tagmon`, see [[keybinds]]) while
the destination monitor has an active **fullscreen** client causes keyboard
focus to get stuck on neither the moved window nor the fullscreen one.
`SUPER+D`, unfullscreen, and any other focus-dependent action stop working
until the fullscreen window is manually re-focused with a mouse click.

## Why it happens
Confirmed directly in `src/dispatch/bind.c`, `tag_monitor()` (same in the
0.17.0 tag and the current `main` branch — genuinely unfixed upstream, not
something an upgrade would resolve):

```c
client_set_monitor(c, m, newtags, true);   // internally re-focuses using
                                            // server.selected_monitor, which
                                            // is STILL the OLD/source
                                            // monitor at this point
...
server.selected_monitor = c->mon;          // updated too late - after the
                                            // focus-restore call above
...
if (c->isfloating) {                       // explicit re-focus only exists
    ...                                     // for FLOATING windows
    client_focus(c, 1);
}
```
For a normal **tiled** window (the common case), there's no equivalent
explicit re-focus step at all once `selected_monitor` is finally corrected —
the only focus assignment that happened targeted the wrong (source) monitor.

## Why the obvious fix doesn't work
A same-monitor `focusmon` call right after `tagmon` (to force a correct
re-focus) doesn't help either — `focus_monitor()` early-returns if the
target is already `server.selected_monitor`, which `tag_monitor()` has
already (incorrectly, per above) set to the destination by the time such a
follow-up call would run.

## What would fix it (not implemented)
A "bounce" workaround is possible in principle — `tagmon` to the
destination, then `focusmon` to the *source* (forces a real switch, which
does correctly refocus), then `focusmon` back to the destination (now a real
switch again, correctly refocuses there) — chained via a spawned shell
script calling `mmsg dispatch` three times instead of a single clean bind.
**Not implemented**: `warpcursor` is on by default, so this would make the
mouse cursor visibly jump to the other monitor and back on every
cross-monitor window move, not just the ones that hit this bug. Decided the
side effect wasn't worth it for an edge case (fullscreen + cross-monitor
move at the same time) - just click the fullscreen window to refocus it
manually when this happens.

## Notes
- No GitHub milestones or roadmap exist for this project (checked
  `/repos/mangowm/mango/milestones` and the README) - no way to know if or
  when this gets fixed upstream. Worth re-checking release notes
  (`https://github.com/mangowm/mango/releases`) after future updates.
- This is unrelated to the [[version-bug-upgrade]] issues (those were
  missing-feature/stale-behavior bugs fixed by upgrading past 0.16.1) - this
  one is a genuine, currently-live logic bug in the latest code.

# Known limitation: `focus_cross_monitor` can't be restricted to specific directions

**Date:** 2026-09-17
**Category:** mango (upstream limitation, not a config issue)
**Version confirmed on:** 0.17.0

## What
`focus_cross_monitor = 1` (see [[multi-monitor-setup]]) is a single global
flag covering all four `focusdir` directions - there's no config option to
enable it for `left`/`right` only and disable it for `up`/`down`. After
switching tag 1 to the `vertical_scroller` layout, `SUPER+j`/`k` (up/down
focus, no more content in that direction on the current monitor) started
jumping to `HDMI-A-1` - confusing, since the monitors are laid out
horizontally (`eDP-1` left, `HDMI-A-1` right, see [[multi-monitor-setup]]),
so "up"/"down" landing on the other monitor doesn't match the physical
layout the way `SUPER+h`/`l` crossing does.

## Why it happens
Confirmed in `src/manage/monitor.c`, `monitor_from_direction()`: it first
tries `wlr_output_layout_adjacent_output()` for the exact requested
direction - correctly finds nothing for `up`/`down` (no monitor is
physically above/below). It then falls back to
`wlr_output_layout_farthest_output()` searching the *other three*
directions (`dir` XORed out of the full direction mask) - with only two
monitors, that fallback always finds `HDMI-A-1`, regardless of whether
`up`/`down` was actually requested. This fallback is unconditional C logic,
not gated by any per-direction config - `config.focus_cross_monitor` is
checked once in `focus_direction()` (`src/dispatch/bind.c`) before calling
`focus_monitor()` for any of the four directions alike.

## What would fix a *per-direction* version of this (not implemented)
Two options surfaced for keeping `left`/`right` crossing while dropping only
`up`/`down`, neither shipped:
1. A wrapper script bound to `SUPER+j`/`k` instead of a plain `focusdir`
   bind: dispatch the normal up/down focus move, check if the selected
   monitor changed, and if so `dispatch focusmon` back to the original one.
   Same class of "bounce" workaround as the fullscreen-focus bug above, with
   the same open risk - `warpcursor` is on by default, so this could cause a
   visible cursor jump-and-return on every vertical edge press.
2. Rebind `up`/`down` to Mango's own `focus_window_or_workspace` dispatcher
   instead of `focusdir` - it falls back to switching to the next/prev tag
   with a client instead of jumping monitors, no custom script needed. But
   this changes what happens at the edge (tag-shift) rather than making it a
   true no-op.

## Actual resolution (2026-09-17)
Since explicit monitor switching already existed on `SUPER+[`/`]`
(`focusmon`/`tagmon`, unaffected by `focus_cross_monitor` entirely - see
[[multi-monitor-setup]]), neither per-direction workaround above was needed
in the end: `focus_cross_monitor` was just turned off globally
(`0` in `misc.conf`), giving up `SUPER+h`/`l` monitor-crossing too, in
exchange for zero scripting and zero risk of a cursor-bounce glitch.
Confirmed via `mmsg`: `dispatch focusdir,right` no longer changes the
focused monitor (checked against `get focusing-client`), while
`dispatch focusmon,HDMI-A-1` still switches normally. Revisit the
per-direction options above only if bracket-key-only monitor switching ever
feels insufficient.
