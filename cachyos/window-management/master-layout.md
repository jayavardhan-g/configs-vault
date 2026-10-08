# Master layout (one big window + others share the rest)

**Date:** 2026-08-28
**Category:** window-management
**Files touched:** `~/.config/hypr/config/decorations.lua`, `~/.config/hypr/config/binds.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

## What
Global tiling layout switched from Hyprland's default `dwindle` to `master`.
`SUPER+M` swaps the focused window into the master slot.

## Why
With 4+ windows open, the user wanted one app to take half the screen with the rest
sharing the remaining half — evenly, and staying correct as windows are added/removed.
`dwindle` is a binary-split tree: moving a window with `SUPER+SHIFT+<direction>` only
**swaps its position** with a neighbor, it doesn't change split ratios, so windows stayed
stuck at whatever share they already had (looked "quartered" instead of becoming a real
half). `master` is purpose-built for this: one master window gets a configurable share
(`mfact`, default `0.55`) and everything else stacks/splits the remainder evenly,
automatically.

## Change
`~/.config/hypr/config/decorations.lua`:
```lua
general = {
    layout = "master",
    -- ...gaps, borders, colors unchanged...
},
```

`~/.config/hypr/config/binds.lua`:
```lua
hl.bind(mainMod .. " + M", hl.dsp.layout("swapwithmaster"))
```

## Notes
- This is a **global** default (every workspace), not per-workspace. Hyprland supports
  per-workspace layout overrides via `hl.workspace_rule({ workspace = ..., layout = ... })`
  (see commented example in `~/.config/hypr/config/workspaces.lua`) if a mix is ever
  wanted instead.
- Existing `SUPER+CTRL+J` bind (`layout("togglesplit")`) is a **dwindle-only** message —
  it's now inert (no-op) under master layout. Not removed, just unused; could be
  repurposed for a master-specific message like `orientationnext` (rotates whether the
  master half is left/right/top/bottom).
- The vim hjkl focus/move binds ([[vim-navigation]]) and resize binds ([[resize]]) all
  continue to work unchanged under master — `hl.dsp.focus`/`window.move`/`window.resize`
  are layout-agnostic.
- `SUPER+N` now cycles this live between `master`, `dwindle`, and `scrolling` — see
  [[layout-cycle]]. `master` remains the startup default set here; the bind only changes
  it for the running session.
- **Stack resize is a shared-boundary operation, not independent sizing.** Resizing a
  stack window's height/width changes the boundary it shares with its neighbor — grow one,
  shrink the other. For a window at the edge of the stack (nothing beyond it but the
  screen/dock edge), "grow" in that outward direction is a dead end since there's nothing
  to take space from. See [[resize]] for the specific `J`-does-nothing-at-the-bottom
  symptom and the workaround (shrink the neighbor instead).
