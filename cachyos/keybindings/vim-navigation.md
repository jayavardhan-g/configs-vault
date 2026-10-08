# Vim-style hjkl window navigation

**Date:** 2026-08-28
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

## What
`SUPER+h/j/k/l` moves focus between windows (left/down/up/right), `SUPER+SHIFT+h/j/k/l`
moves the active window around, mirroring the existing arrow-key binds.

## Why
User is a vim user and wanted vim-direction muscle memory for window navigation, alongside
the existing arrow-key binds (kept, not removed).

## Change
```lua
-- Change focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Move active window
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
```

## Notes
- This required relocating two pre-existing binds that collided with `J` and `L`:
  - `SUPER+J` (dwindle "togglesplit") → moved to `SUPER+CTRL+J`
  - `SUPER+L` (session lock) → moved to `SUPER+ALT+L` (via `SUPER+CTRL+L` — see
    [[workspace-switching]] for why), then moved again to its current home
    `SUPER+ALT+X`, and is now gone entirely — lock lives in the `SUPER+SHIFT+Q` session
    panel, with no dedicated bind. See [[floating-window-nudge]]
- See [[resize]] for the vim-style resize submap (`SUPER+R` then hjkl), and
  [[master-layout]] which these binds continue to work correctly under.
- See [[finger-ergonomics]] for which hand/finger presses what across all these binds.
