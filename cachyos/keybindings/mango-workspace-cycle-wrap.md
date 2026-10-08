# Workspace switching (SUPER+CTRL+h/l) wraps around at the ends

**Date:** 2026-09-15
**Category:** keybindings
**Files touched:** `~/.config/mango/cfg/layout.conf`

<!-- graph:begin -->
**Graph:** [[Mango]]
<!-- graph:end -->

## What
Enabled `tag_carousel = 1` in `layout.conf`. `SUPER+CTRL+h`/`SUPER+CTRL+l`
(`viewtoleft`/`viewtoright`, see [[workspace-switching]]) now wrap: from tag 5,
going right lands on tag 1; from tag 1, going left lands on tag 5.

## Why
By default Mango's `viewtoleft`/`viewtoright` dispatchers clamp at the first/last
tag instead of cycling — pressing `SUPER+CTRL+l` on the last workspace (5) did
nothing. This is a config option, not a keybind change: confirmed in Mango's
source (`src/dispatch/bind.c`, `view_shift_tag()`) that the clamp-vs-wrap choice
is gated on `config.tag_carousel` (default `0`), independent of which keys are
bound to `viewtoleft`/`viewtoright`.

## Change
`~/.config/mango/cfg/layout.conf`, top of file — final state:
```
# Number of workspaces (tags). Default 9, max 31.
tag_num = 5

# Wrap workspace switching around at the ends (SUPER+CTRL+h/l /
# viewtoleft/viewtoright): tag 5 -> 1 going right, tag 1 -> 5 going left.
# Default 0 (clamps at the ends instead of cycling).
tag_carousel = 1
```
Applied live with `mmsg dispatch reload_config` — no restart needed. Verified via
`mmsg dispatch view,5,0` then `mmsg dispatch viewtoright,0` landing back on tag 1
(and the reverse from tag 1 landing on tag 5).

## Notes
- Full copy of the file lives at
  [`files/.config/mango/cfg/layout.conf`](../files/.config/mango/cfg/layout.conf).
- `tag_carousel` also affects the `have_client`-variant dispatchers
  (`viewtoleft_have_client`/`viewtoright_have_client`, used when cycling to the
  nearest tag that actually has a client) the same way, per the same source
  function.
