# Freed bare middle-click from Mango's fullscreen toggle

**Date:** 2026-09-15
**Category:** keybindings
**Files touched:** `~/.config/mango/cfg/keybinds.conf`

<!-- graph:begin -->
**Graph:** [[Mango]]
<!-- graph:end -->

## What
Removed Mango's `mousebind = NONE, btn_middle, togglemaximizescreen, 0` — a
global, unmodified middle-click bind that toggled fullscreen (the same action as
`SUPER+D`).

## Why
It intercepted every plain middle-click compositor-wide before it reached any app,
breaking normal browser use of middle-click (open link in new tab, paste selection,
close tab). `SUPER+D` already does the same fullscreen toggle from the keyboard, so
nothing is lost by dropping the mouse duplicate.

## Change
`~/.config/mango/cfg/keybinds.conf`, mouse button bindings section — final state:
```
# Mouse Button Bindings.
# btn_left and btn_right can't bind none mod key
mousebind = SUPER, btn_left, moveresize,curmove
mousebind = SUPER, btn_right, moveresize, curresize
# Removed: mousebind = NONE, btn_middle, togglemaximizescreen, 0
# Bare (unmodified) middle-click was globally intercepted for
# togglemaximizescreen, stealing it from apps (e.g. browser middle-click
# paste/open-link-in-tab/close-tab). SUPER+D already does the same toggle
# via keyboard, so no functionality is lost by dropping the mouse duplicate.
```
Applied live with `mmsg dispatch reload_config` (same effect as the `SUPER+F5` bind) —
no restart needed.

## Notes
- Full copy of the file lives at
  [`files/.config/mango/cfg/keybinds.conf`](../files/.config/mango/cfg/keybinds.conf).
- If Mango ever needs a middle-click bind again, gate it with a modifier (e.g.
  `mousebind = SUPER, btn_middle, ...`) rather than `NONE`, so it doesn't shadow
  app-level middle-click.
