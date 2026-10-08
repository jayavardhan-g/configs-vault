# Smart special-workspace (scratchpad) toggle

**Date:** 2026-08-28
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Monitors]]
<!-- graph:end -->

## What
`SUPER+SHIFT+S` is context-aware: on a normal window it sends it to the special workspace
(hide/"minimize"); on a window already in the special workspace, it instead pulls it back
to whatever workspace is currently active on its monitor. `SUPER+S` still just
shows/hides the special workspace overlay (unchanged).

## Why
Originally `SUPER+SHIFT+S` only ever sent windows *into* special. Bringing a window back
out permanently required `SUPER+CTRL+SHIFT+<number>` (send to a specific numbered
workspace) — clunky for a single common action. This makes the same key do both
directions.

## Change
```lua
local function toggle_window_special()
    local win = hl.get_active_window()
    if not win or not win.workspace then return end
    if win.workspace.special then
        local target = win.monitor and win.monitor.active_workspace
        if target then
            hl.dispatch(hl.dsp.window.move({ workspace = target.id }))
        end
    else
        hl.dispatch(hl.dsp.window.move({ workspace = "special" }))
    end
end
hl.bind(mainMod .. " + SHIFT + S", toggle_window_special)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special())
```

## Notes
- **Mental model:** the special workspace is a single hidden overlay *per monitor*, not
  tied to any one regular workspace. `SUPER+S` toggles whether that overlay is visible on
  top of whichever workspace is currently active — it does not auto-hide when you switch
  workspaces. If it's toggled on, it stays shown across every workspace switch on that
  monitor until you toggle it off again. This is expected Hyprland behavior, not a bug.
- The special workspace can hold multiple windows at once, tiled among themselves using
  the same layout as everywhere else (currently `master`, see [[master-layout]]) — sending
  several different apps there builds up a "combo" that all show/hide together as one
  `SUPER+S` toggle.
- Verified live via `hyprctl repl`: `window.workspace.special` correctly reports `true`
  for a window sitting in special, and `window.monitor.active_workspace` correctly
  resolves to the real underlying workspace (not the special one) even while special is
  toggled visible.
- See [[finger-ergonomics]] for the recommended fingering on `SUPER+S`/`SUPER+SHIFT+S` —
  `S` is a left-hand letter, so it's one of the two binds that don't follow the
  right-hand-does-hjkl pattern.
