# Disable focus-follows-mouse (sloppyfocus)

**Date:** 2026-09-20
**Category:** window-management
**Files touched:** `~/.config/mango/cfg/misc.conf`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Mango]]
<!-- graph:end -->

## What
Set `sloppyfocus = 0` in Mango's `misc.conf`. Mango (a dwm-family compositor) defaults to
"sloppy focus" — moving the pointer over any window steals keyboard focus to it, with no
click needed. Switched to click-to-focus instead.

## Why
Jayavardhan found focus jumping to whatever window the pointer happened to cross
(e.g. while reaching for a scrollbar, or just moving across the screen) annoying and
disruptive to keyboard-driven focus (`SUPER+hjkl`, `SUPER+Tab`).

## Change
`~/.config/mango/cfg/misc.conf`:
```
# Focus follows mouse (dwm-family default is on): just moving the pointer
# over another window would steal focus to it. Click-to-focus instead.
sloppyfocus = 0
```

Apply with `SUPER+F5` (bound to `reload_config`) — Mango has no reload signal, only that
keybind; there's no CLI/IPC way to trigger it externally.

Stored copy: [files/.config/mango/cfg/misc.conf](../files/.config/mango/cfg/misc.conf).

## Notes
- `sloppyfocus` isn't present in Mango's shipped default config
  (`/etc/skel/.config/mango/cfg/misc.conf`) — it's a compiled-in default (on) only
  discoverable via `strings /usr/bin/mango`, not documented in any shipped config file or
  comment.
- Distinct from `edge_scroller_pointer_focus` in `layout.conf` (see `layout.conf`'s own
  comments) — that one is scoped to hovering onto an off-screen scroller-layout column and
  was intentionally kept on; this one is the general "any window, any layout" case.
- Distinct from `focus_cross_monitor` just above it in `misc.conf` — that one is about
  keyboard-driven focus movement (`SUPER+hjkl`) crossing monitor boundaries, unrelated to
  mouse-driven focus.
