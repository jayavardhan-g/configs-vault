# Refresh-rate switcher no longer re-places the laptop panel

**Date:** 2026-09-30
**Category:** window-management
**Files touched:** `~/.config/hypr/scripts/refresh-rate.sh` (copy at [`files/.config/hypr/scripts/refresh-rate.sh`](../files/.config/hypr/scripts/refresh-rate.sh))

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Monitors]]
<!-- graph:end -->

## What
`refresh-rate.sh` (SUPER+ALT+R, and the battery guard's 144/60 Hz switch) now
changes only eDP-1's refresh rate. It no longer sets position and scale.

## Why
After unplugging the HDMI cable, the external monitor came back behaving as if it
were to the left of the laptop. Live state: eDP-1 at **x=3570, scale 1.25**
(`monitors.lua` says 0x0 / 1.20).

`set_hz()` called
`hl.monitor({ output = 'eDP-1', mode = ..., position = 'auto', scale = '1.25' })`,
a stale copy of the layout. `auto` puts the laptop after the already-placed
HDMI-A-1: 1650 + 1920 = 3570. It fires from:
- `battery-refresh-guard.timer` (systemd user timer, every 30 s). It runs the
  script whenever the battery zone changes: charger unplugged while below 50%,
  plugged back in, or dropping below 50% on battery. Unplugging the charger along
  with HDMI is the likely trigger.
- SUPER+ALT+R (manual toggle).

The wrong position then survives HDMI unplug/replug. The same class of bug as
[[display-mode-menu-follows-monitors-lua]]; this was the second stale copy.
Noctalia's lockscreen settings had also recorded eDP-1 as 1536×864 (= 1.25 scale),
another trace of it.

## Change
`set_hz()` in `~/.config/hypr/scripts/refresh-rate.sh`, final state:
```bash
set_hz() {
    hyprctl eval "hl.monitor({ output = '${MONITOR}', mode = '1920x1080@${1}' })"
}
```
(`POS` and `SCALE` variables removed.)

## Notes
- `hl.monitor()` patches only the fields passed. Verified live: mode-only 144 →
  60 → 144 via the script's `toggle` left eDP-1 at x=0 / scale 1.20 each time.
- To fix a machine already in the broken state: `hyprctl reload`.
- Side effect of any `hyprctl reload` (config save, SUPER+P): eDP-1 goes back to
  `monitors.lua`'s `@144`, even while the guard wants 60 Hz on low battery. The
  guard only acts on zone *changes*, so it won't re-apply 60 until the next
  crossing. Not changed.
- Keep monitor position/scale in `monitors.lua` only. Scripts should patch just
  the one field they own.
