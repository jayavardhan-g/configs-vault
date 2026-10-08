# SUPER+B also launches the browser (alongside SUPER+W)

**Date:** 2026-09-14
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

## What
`SUPER+B` now launches `$BROWSER` too, in addition to the existing `SUPER+W`. Both keys
do the same thing.

## Why
Matches Mango's `keybinds.conf` (`bind = SUPER, b, spawn, app.zen_browser.zen`), which
uses `B` instead of `W` for the browser. Added rather than replaced since `SUPER+W`
already worked and `B` was free.

## Change
```lua
hl.bind(mainMod .. " + W",          hl.dsp.exec_cmd(launchPrefix .. BROWSER))
hl.bind(mainMod .. " + B",          hl.dsp.exec_cmd(launchPrefix .. BROWSER))
```

## Notes
- Not yet reloaded/tested — set from a session in Mango, not Hyprland (`hyprctl reload`
  next time Hyprland is running, or it'll just apply fresh on next login).
