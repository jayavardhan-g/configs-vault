# SUPER+P display-mode menu re-applies monitors.lua

**Date:** 2026-09-25
**Category:** window-management
**Files touched:** `~/.config/hypr/scripts/display-mode.sh` (copy at [`files/.config/hypr/scripts/display-mode.sh`](../files/.config/hypr/scripts/display-mode.sh))

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Monitors]]
<!-- graph:end -->

## What
The SUPER+P menu (Extend / Duplicate / PC screen only / Second screen only) no
longer hard-codes monitor positions and scales. Each mode clears any leftover
disabled/mirror state, runs `hyprctl reload` to re-apply `config/monitors.lua`,
then makes only the one change that mode needs.

## Why
The external monitor behaved as if it were to the left of the laptop. Live
state: eDP-1 at **x=3570, scale 1.25**, HDMI-A-1 at x=1650. That is 1650 + 1920,
i.e. the laptop auto-placed to the right of the external. `monitors.lua` says
eDP-1 at 0x0 / 1.20 and HDMI-A-1 at 1650x0 / 1.0, and `hyprctl reload`
restored exactly that. So the config was correct.

The only thing that sets scale 1.25 was `display-mode.sh`. It carried its own
copy of the layout (both screens at 1.25, external at `position="auto"`),
which had drifted from `monitors.lua`. Any SUPER+P use, or a replug after one,
left the screens in a layout the config doesn't describe.

## Change
`~/.config/hypr/scripts/display-mode.sh`, final state:
```bash
INTERNAL="eDP-1"
EXTERNAL="HDMI-A-1"

reset() {
    hyprctl eval "
        hl.monitor({output=\"$INTERNAL\", disabled=false, mirror=\"\"})
        hl.monitor({output=\"$EXTERNAL\", disabled=false, mirror=\"\"})
    " >/dev/null
    hyprctl reload >/dev/null
}

case "$choice" in
"Extend")             reset ;;
"Duplicate")          reset; hyprctl eval "hl.monitor({output=\"$EXTERNAL\", mirror=\"$INTERNAL\"})" ;;
"PC screen only")     reset; hyprctl eval "hl.monitor({output=\"$EXTERNAL\", disabled=true})" ;;
"Second screen only") reset; hyprctl eval "hl.monitor({output=\"$EXTERNAL\", position=\"0x0\"}) hl.monitor({output=\"$INTERNAL\", disabled=true})" ;;
esac
```
(The full script, including the fuzzel menu, is in the stored copy.)

## Notes
- `reset()` still has to clear disabled/mirror explicitly: `hl.monitor()` patches
  fields incrementally and `monitors.lua` never sets those two, so a reload alone
  would not undo Duplicate or an "only" mode.
- Tested live: from the old script's Extend state (both at 1.25, HDMI at 1536)
  and from Duplicate (`mirrorOf: 0`), reset returned to eDP-1 0 / 1.20 and
  HDMI-A-1 1650 / 1.0. PC screen only and Second screen only were not tested
  live, because they turn a screen off.
- Side effect: every mode now does a full config reload, which also discards
  other runtime-only `hyprctl eval` changes. SUPER+N layouts are safe, since
  they're persisted in `state/workspace-layouts.conf`.
- Change the monitor layout in `monitors.lua` only; SUPER+P picks it up
  automatically.
