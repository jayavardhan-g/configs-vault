# Scroll direction: Windows-style per device type

**Date:** 2026-08-28
**Category:** input
**Files touched:** `~/.config/hypr/config/inputs.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

## What
Mouse wheel scrolls "traditionally" (wheel down → content moves down), matching Windows'
default for a mouse. Touchpad two-finger scroll is "natural" (content follows your
fingers), matching Windows' default for a precision touchpad. These are two different
defaults on Windows, so they're configured separately here.

## Why
User wanted scrolling to feel like Windows. `natural_scroll` was initially set to `true`
globally, which is the reversed/natural (macOS-style) direction for a mouse — the opposite
of what was wanted.

## Change
```lua
input = {
    natural_scroll = false,     -- mouse wheel: wheel down = content moves down
    touchpad = {
        natural_scroll = true,  -- two-finger scroll: content follows your fingers
    },
    -- ...other input settings...
},
```

## Notes
- Hyprland's Lua config auto-reloads on file save — no `hyprctl reload` needed, though
  running it manually is harmless.
- **Gotcha hit during setup:** a `hl.config({...})` table literal with **two `input = {...}`
  keys** silently drops the first one (Lua table constructors keep only the last value for
  a duplicate key) — this wiped out `accel_profile`, `kb_layout`, `kb_options`, and
  `natural_scroll` all at once with no error from Hyprland. Verify with
  `hyprctl getoption input:natural_scroll` (and other input options) showing `set: true`
  after any edit to this block, to make sure nothing got silently clobbered.
