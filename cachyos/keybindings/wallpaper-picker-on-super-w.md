# Wallpaper picker rebind: SUPER+SHIFT+W → SUPER+W

**Date:** 2026-09-21
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Noctalia]]
<!-- graph:end -->

## What
The Noctalia wallpaper picker moved from `SUPER+SHIFT+W` to plain `SUPER+W`. The browser,
which previously answered to both `SUPER+W` and `SUPER+B`, is now on `SUPER+B` only.
`SUPER+SHIFT+W` is free.

## Why
`SUPER+W` and `SUPER+B` were two binds for the same thing (launch Zen), so one was pure
waste. `W` is the obvious mnemonic for Wallpaper, and freeing it let the picker drop from
a two-modifier chord to a single one. Nothing is lost — the browser is still one key away.

## Change
```lua
-- in the LAUNCHER section
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(launchPrefix .. BROWSER))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(noctCall .. "panel-toggle wallpaper"))
```
The old `hl.bind(mainMod .. " + SHIFT + W", ...)` line under "Theming and Wallpaper" was
removed; a comment there points at the new home.

## Notes
- Part of the same 2026-09-21 pass that removed several other redundant or dead binds —
  see [[dead-bind-cleanup]] and [[floating-window-nudge]]. The pattern each time was a
  duplicate or dead bind occupying a good single-modifier key that something more useful
  wanted.
- Deliberately kept the browser on `B` rather than `W`: `B` for browser is at least as
  memorable, and picking the letter that frees a mnemonic for something else is the whole
  point of the change.
- `SUPER+SHIFT+W` is now free and not reserved for anything.
