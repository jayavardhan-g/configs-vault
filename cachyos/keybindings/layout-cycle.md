# SUPER+N cycles layout engine: master → dwindle → scrolling

**Date:** 2026-09-14
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

## What
`SUPER+N` cycles Hyprland's live `general:layout` between `master` (the current default,
see [[master-layout]]), `dwindle`, and `scrolling`.

## Why
Wanted a Mango-style "switch layout" key (Mango's `SUPER+N` cycles its own
`circle_layout` list of layout engines). While implementing it, confirmed this Hyprland
build actually ships a built-in horizontal-scrolling layout engine —
`Layout::Tiled::CScrollingAlgorithm` in `/usr/bin/Hyprland`, with `scrolling:column_width`
/ `scrolling:direction` / `scrolling:explicit_column_widths` config keys — that had never
been turned on in this config before. `master` and `dwindle` were the only two layouts
actually configured (`general.layout = "master"` in `decorations.lua`, plus a
`dwindle = { preserve_split = true }` block in `misc.lua`), so this bind also gives
`dwindle` a way to be reached live without editing `decorations.lua` by hand.

## Change
```lua
-- Cycle the active layout engine: master -> dwindle -> scrolling -> master
local LAYOUTS = { "master", "dwindle", "scrolling" }
local function cycle_layout()
    local current = hl.get_config("general:layout")
    local idx = 1
    for i, name in ipairs(LAYOUTS) do
        if name == current then idx = i end
    end
    hl.config({ general = { layout = LAYOUTS[(idx % #LAYOUTS) + 1] } })
end
hl.bind(mainMod .. " + N", cycle_layout)
```

## Notes
- `scrolling` is untested/untuned territory — no `scrolling:*` options have been set, so
  it runs on whatever Hyprland's built-in defaults are. Revisit `scrolling:column_width`
  etc. once it's actually been used for a while.
- The cycle reads the *current* live value via `hl.get_config` each press (same pattern
  as the existing `zoomfunction` in this file) rather than tracking its own index
  variable, so it stays correct even if the layout is changed some other way (e.g. a
  per-workspace `hl.workspace_rule(..., layout = ...)` override) between presses.
- Startup default is still `master`, set in `decorations.lua` — this bind only changes the
  layout for the running session, not what you boot into.
- **Known quirk: maximizing a window in `scrolling` breaks directional focus out of that
  monitor.** `SUPER+D` (maximize, `fullscreen({mode=1})`) pulls the window out of the
  scrolling layout's column list entirely (confirmed in the binary —
  `ScrollingFullscreenHandler`/`columnCoversMonitor` — maximize is tracked as a distinct
  state, not just a wide column). With no sibling column left to find, `focusdir` (e.g.
  `SUPER+L`) finds no candidate on the current monitor and immediately falls through to
  `binds:window_direction_monitor_fallback` (on by default), jumping focus to the next
  monitor instead of doing nothing or erroring.
  - **Tested against MangoWM for comparison (2026-09-14): does NOT reproduce there.**
    Mango's `togglemaximizescreen` keeps the maximized window in the scroller's focus
    traversal order — `SUPER+L` after maximizing in Mango steps to the next sibling
    window first, and only crosses to the next monitor once siblings are exhausted. So
    this is a genuine Hyprland scrolling-layout limitation, not something fixable by
    matching Mango's config — the two compositors' scroller implementations handle a
    maximized window's place in the focus order differently.
  - **Workaround:** resize the window wide instead of maximizing it (e.g.
    `SUPER+CTRL+SHIFT+L`/the `SUPER+R` resize submap) — a resized-but-not-maximized column
    stays part of the normal column list, so `focusdir` still finds it correctly.
  - **Decision (2026-09-14):** left `binds:window_direction_monitor_fallback` at its
    default (`true`) rather than disabling it globally — the jump only bites in this
    specific maximize+scrolling combination, and disabling it would also remove the
    (probably wanted) monitor-crossing fallback for `master`/`dwindle`. Revisit if this
    default starts causing surprises outside the scrolling+maximize case too.
