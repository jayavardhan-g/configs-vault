# Per-tag default layout: scroller for 1-4, fair for tag 5

**Date:** 2026-09-14
**Category:** mango
**Files touched:** `~/.config/mango/cfg/layout.conf`, `~/.config/mango/cfg/keybinds.conf`

<!-- graph:begin -->
**Graph:** [[Mango]] · [[Monitors]] · [[Xpad]]
<!-- graph:end -->

## What
Tags 1-4 default to the `scroller` layout (a horizontally-scrolling strip of windows);
tag 5 defaults to `fair`. Applies on both `eDP-1` and `HDMI-A-1` — `tagrule` with no
`monitor_name` applies to every monitor. `tag_num` is 5 (a plain general-purpose tag,
unrelated to the earlier Xpad attempt — see [[xpad-workspace-and-monitor-persistence]],
which was fully reverted before this).

## Why
User had been live-testing layouts via `SUPER+N`'s `circle_layout` cycle and settled on
wanting `scroller` ("horizontal scaling") as the everyday default instead of the previous
`dwindle`, with a dedicated 5th tag on `fair` specifically.

## Change

`~/.config/mango/cfg/layout.conf`:
```
tag_num = 5

tagrule = id:1, layout_name:scroller
tagrule = id:2, layout_name:scroller
tagrule = id:3, layout_name:scroller
tagrule = id:4, layout_name:scroller
tagrule = id:5, layout_name:fair
```

`~/.config/mango/cfg/keybinds.conf` — added, alongside the existing 1-4 view/tag binds:
```
bind = SUPER, 5, view, 5, 0
bind = SUPER+SHIFT, 5, tag, 5, 0
```

## Notes
- `circle_layout = dwindle,tile,scroller,vertical_scroller` (already in `layout.conf`,
  unchanged) still lets `SUPER+N` cycle through those options live on the current tag —
  this just changes what each tag starts on, not what's available to switch to.
- Confirmed live via `mmsg get all-monitors`: both monitors report `layout: "S"` (scroller)
  for tags 1-4 and `layout: "F"` (fair) for tag 5.
