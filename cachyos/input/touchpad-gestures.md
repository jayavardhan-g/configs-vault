# Touchpad gestures: 3-finger swipe cycles windows

**Date:** 2026-11-12
**Category:** input
**Files touched:** `~/.config/hypr/config/inputs.lua` (copy: `cachyos/files/.config/hypr/config/inputs.lua`)

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

## What
3-finger swipe left/right now cycles focus through the windows on the current
workspace (left = next, right = previous), mirroring how the 4-finger swipe moves
between workspaces. 3-finger left = float was removed to make room.

## Why
Jayavardhan wanted a window-level counterpart to the 4-finger workspace swipe, and
asked to drop the 3-finger float gesture (float is still on SUPER+SHIFT+F, see
[[float-toggle]]).

## Change
Final gesture block in `inputs.lua`:
```lua
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left",  action = function() hl.dispatch(hl.dsp.window.cycle_next()) end })
hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.window.cycle_next({ next = false })) end })
```

## Notes
- Hyprland 0.57's Lua `hl.gesture` accepts a function as `action`. It fires once per
  swipe, so there is no live finger-tracking animation like the workspace swipe has.
- `hl.dsp.window.cycle_next` takes `{ next = bool, tiled = bool, floating = bool }`
  (from `LuaBindingsDispatchers.cpp`). Unset `tiled`/`floating` means it cycles all
  windows, the same as the ALT+Tab bind.
- Left = next matches the 4-finger direction sense with natural touchpad scrolling
  ([[scroll-direction]]).
- 3-finger down stays deliberately unbound (it used to be `close`, which was too
  destructive for an easy accidental gesture).
