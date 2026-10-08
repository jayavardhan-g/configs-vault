# Ported emoji picker bind (SUPER+.) from Hyprland to Mango

**Date:** 2026-09-15
**Category:** keybindings
**Files touched:** `~/.config/mango/cfg/keybinds.conf`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Mango]] · [[Noctalia]]
<!-- graph:end -->

## What
Added `bind = SUPER, period, spawn, noctalia msg panel-toggle launcher /emo` to
Mango's keybinds, opening Noctalia's launcher pre-seeded with the `/emo` command
(its emoji-picker mode).

## Why
`SUPER+.` was a working Hyprland bind (`~/.config/hypr/config/binds.lua:143`,
`mainMod + period` -> `noctalia msg panel-toggle launcher /emo`) but was never
carried over when switching window managers to Mango — Mango's
`keybinds.conf` had no `period` bind at all, so the key did nothing. Same gap
pattern as [[mango-middle-click-freed]].

## Change
`~/.config/mango/cfg/keybinds.conf`, Noctalia keybinds section — final state:
```
# Noctalia specific keybinds.
bind = SUPER, space, spawn, noctalia msg panel-toggle launcher
# Emoji picker (carried over from Hyprland's SUPER+period bind - opens the
# launcher pre-seeded with the /emo command).
bind = SUPER, period, spawn, noctalia msg panel-toggle launcher /emo
bind = SUPER, x, spawn, noctalia msg panel-toggle control-center
bind = SUPER, w, spawn, noctalia msg panel-toggle noctalia/wallhaven:browser
bind = SUPER, v, spawn, noctalia msg panel-toggle clipboard
bind = SUPER+SHIFT, q, spawn, noctalia msg panel-toggle session
```
Applied live with `mmsg dispatch reload_config` — no restart needed.

## Notes
- Full copy of the file lives at
  [`files/.config/mango/cfg/keybinds.conf`](../files/.config/mango/cfg/keybinds.conf).
- The Hyprland-era bind in `~/.config/hypr/config/binds.lua` is left as-is for
  reference/rollback; it's inert while Mango is the running compositor.
- If other Hyprland binds turn out to be similarly un-ported, check
  `~/.config/hypr/config/binds.lua` against `~/.config/mango/cfg/keybinds.conf`
  side by side rather than waiting for each one to be noticed missing.
