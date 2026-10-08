# Directional focus across the monitor gap

**Date:** 2026-09-21, updated 2026-09-26
**Category:** window-management
**Files touched:** `~/.config/hypr/config/misc.lua` and `~/.config/hypr/config/binds.lua` (copies at [`files/.config/hypr/config/misc.lua`](../files/.config/hypr/config/misc.lua) and [`files/.config/hypr/config/binds.lua`](../files/.config/hypr/config/binds.lua)). On 2026-09-21 nothing was changed.

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Monitors]]
<!-- graph:end -->

## Current state (2026-09-26)
SUPER+H/L (and SUPER+Left/Right) **do** cross to the neighbouring monitor at the
screen edge, landing on the nearest window actually on screen there. This reverses
the 2026-09-21 conclusion below. Two changes made it work:

1. `binds:window_direction_monitor_fallback = false` (misc.lua), see the next
   section. Side effect: at the edge, focus now **stays put** instead of wrapping to
   the first column, which removes the blocker that sank the 2026-09-21 Lua attempt.
2. A `focus_across(dir)` helper in binds.lua for the left/right binds:
   - Dispatch normal directional focus. If the focused window changed, done.
   - Otherwise take the nearest monitor in that direction by `x`. If there isn't
     one, do nothing.
   - On that monitor's active workspace, consider only windows whose span overlaps
     the monitor's logical span (`x .. x + width/scale`), which skips scrolled-off
     columns. Take an on-screen fullscreen window if there is one, otherwise the
     leftmost when going right (rightmost when going left).
   - Focus it, or fall back to `focus({ monitor = name })` if the workspace is empty.

The full function is in the stored `binds.lua`.

Tested live, running the function text extracted verbatim from binds.lua through
`hyprctl eval` (no key-injection tool is installed):
- Laptop's rightmost window, focus right: lands on mpv, the fullscreen window
  showing on HDMI-A-1. What the monitor shows is unchanged.
- ws4's leftmost column, focus left: back to the laptop's rightmost on-screen window.
- Laptop's leftmost window, focus left (no monitor there): stays put.

Gotchas found on the way:
- ws4 had **two** windows flagged fullscreen (mpv on screen, Zen scrolled off).
  Picking "any fullscreen window" focused Zen and scrolled it over mpv. So only
  fullscreen windows that are on screen count.
- `hl.get_monitors()` gives `x` in logical px but `width` in physical px. Divide
  by `scale`.
- Known gap: if the scratchpad is open on the far monitor, the window underneath
  is picked. The monitor object's special-workspace fields came back `nil` with no
  scratchpad open, so it's unclear whether the API exposes that at all.
- The helper is `local`, so `hyprctl eval` can't reach it (see the last note of
  this file). Test it by extracting it as above.

## Update (2026-09-26): `window_direction_monitor_fallback = false`
The gap did **not** fully stop SUPER+H from crossing monitors. From the laptop's
leftmost window, SUPER+H jumped to a window on the external's workspace 4. The
reason: scrolling-layout columns that are scrolled off-screen keep global
coordinates outside their own monitor. ws4's Zen sat at x=-1222 (to the left of
the laptop) and qBittorrent at x=696 (inside the laptop's region). The fallback's
direction search considers windows on other monitors' visible workspaces by
geometry alone, so a hidden column counted as "to the left".

Measured live: with the fallback `true`, focus-left landed on ws4 every press.
With `false`, focus stayed put on 20 of 20 presses. SUPER+SHIFT+hjkl window moves
didn't cross monitors with either value, so turning it off loses nothing. Now set
in `misc.lua`:
```lua
binds = {
    movefocus_cycles_fullscreen = true,
    window_direction_monitor_fallback = false,
},
```
This replaces the earlier stance (a `misc.lua` comment said the fallback was
deliberately left `true`). If the gap is ever closed (`position = "1600x0"`), turning the
fallback back on is no longer the complete answer: re-test for off-screen scrolling
columns first.

Seen 3 times during testing, never reproduced afterwards: focus-left jumped into the
hidden scratchpad's kitty and opened it. Hyprland's direction search skips invisible
workspaces, so this was most likely a test artefact (a preceding test had just
toggled the scratchpad). If SUPER+H ever opens the scratchpad, it's a separate bug.

Also note `monitors.lua` currently has HDMI-A-1 at **x=1650** (a 50px gap), not the
1700 / 100px this entry describes. The reasoning is unchanged; 50px is still 25x
the 2px adjacency threshold.

## What (2026-09-21, superseded, see Current state above)
`SUPER+L` / `SUPER+H` (and the arrow equivalents) do **not** move focus to the other
monitor when you're on the last window at a screen edge. This is a consequence of the
deliberate 100px dead zone configured in `~/.config/hypr/config/monitors.lua` (which
carries its own long comment on why the gap exists and how to re-derive it), not a bug. An
attempt to work around it in Lua was written, tested and **reverted** — it cannot work.
Use `SUPER+bracketleft` / `SUPER+bracketright` to change monitor deliberately.

## Why it happens
Hyprland has `binds:window_direction_monitor_fallback` for exactly this, and it is
already `true` (verified with `hyprctl getoption`). It never fires because of how
Hyprland decides which windows are candidates — `isAdjacent()` in
`src/desktop/state/WindowQuery.cpp`:

```cpp
constexpr double STICK_THRESHOLD = 2.0;
const double delta = aEdge - bEdge;
if (std::abs(delta) < STICK_THRESHOLD) return true;  // touching
if (delta >= 0) return false;                        // a real gap -> not adjacent
```

The tolerance is **2 logical px**. The live geometry:

| monitor | logical span | scale |
|---|---|---|
| eDP-1 | 0 → 1600 (1920/1.2) | 1.2 |
| HDMI-A-1 | 1700 → 3620 | 1 |

That is a **100px gap — 50x the threshold**, so no window on the far screen is ever a
candidate and the fallback has nothing to fall back to. Reproduced live in both
directions by dispatching `hl.dsp.focus({direction=...})` repeatedly and watching
`hyprctl monitors`: focus moved within the monitor, then stopped or wrapped, never
crossing.

## Why the Lua workaround can't work
The obvious fix is a wrapper: dispatch focus, check whether the focused window changed,
and if it didn't, focus the nearest monitor in that direction by position. It was written
and it loads fine, but the edge-detection premise is false:

**The scrolling layout WRAPS focus instead of refusing to move.** Measured on eDP-1 ws1
with two windows, pressing focus-right repeatedly:

```
press 1 -> addr 0x…029450  x [803, 5]
press 2 -> addr 0x…d5d170  x [6, 5]     <- wrapped back to the first column
press 3 -> addr 0x…029450  x [803, 5]
press 4 -> addr 0x…d5d170  x [6, 5]
```

The focused window changes on *every* press, so "focus didn't move" is never true and the
fallback branch is unreachable. Detecting the edge would mean comparing window
*positions* to spot a backwards jump, plus restoring focus when there turns out to be no
monitor to cross to — more machinery and more edge cases (floating windows, the other
three layouts, `scrolling` with `direction = down`) than the problem is worth. Reverted.

## Decision (2026-09-21): keep the dead zone
Presented as a straight trade — cross-monitor `hjkl` focus, or the pointer dead zone, not
both. **Chose to keep the dead zone**, so `SUPER+hjkl` deliberately stops at the screen
edge and changing monitor is an explicit `SUPER+bracketleft` / `SUPER+bracketright`.
No config change was made; this entry exists to explain why the behaviour is what it is.

To reverse the decision later it is one line in `monitors.lua` — close the gap and
Hyprland's own `binds:window_direction_monitor_fallback` starts working with no custom
code at all:
```lua
position = "1600x0",   -- instead of "1700x0"
```
The cost of that is the dead zone, whose whole purpose is stopping the pointer drifting
onto the external screen by accident. The focus behaviour is downstream of that trade,
not a separate problem to solve.

## Notes
- `focus({ monitor = "+1" / "-1" })` works but **wraps by monitor index** — from the
  rightmost monitor, `+1` returns to the laptop. Not usable as a directional fallback.
  Verified live.
- `focus({ monitor = "l" })` / `"r"` is **not supported** by the Lua API — it returns
  `hl.focus.monitor: monitor not found`. Only monitor names and relative `+n`/`-n` work.
- `hl.notify` does not exist in this Hyprland's Lua API, which is worth knowing when
  trying to debug a keybind from `hyprctl dispatch`.
- A `local function` in `binds.lua` is **not reachable** from `hyprctl dispatch` — that
  runs in the global scope, so testing a bind's helper that way gives
  `attempt to call a nil value`, which looks like a broken helper but isn't.
