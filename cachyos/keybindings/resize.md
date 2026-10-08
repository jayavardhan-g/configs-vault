# Window resizing: submap and reset

**Date:** 2026-08-28 (updated 2026-09-21 — submap made sticky, direct-resize chord

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

removed; see Notes)
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`

## What
Two ways to resize the focused window, plus a way to reset a window back to its
default tiled size:

1. `SUPER+R` enters a vim-style resize **submap** — while active, `h/j/k/l` resizes in
   20px steps (hold to repeat) as many times as you like. The mode is **sticky**: it stays
   until you explicitly leave it with `Esc`, `Enter` or `SUPER+R`.
2. `SUPER` + right-click drag resizes freely with the mouse.
3. `SUPER+SHIFT+R` resets the focused window's size back to its default tiled share, and
   resets the master/stack ratio back to Hyprland's default (`0.55`).

## Why
User wanted vim-key resizing. The reset bind was added after manual resize testing left
two windows uneven — see Notes.

There used to be a third path, `SUPER+CTRL+SHIFT+h/j/k/l` for direct 40px steps with no
mode to enter or exit. It existed **only** because the submap was accidentally one-shot
and so couldn't do more than one nudge per invocation. Once the submap was fixed to be
sticky, a three-modifier chord for the same job stopped earning its keystrokes and was
removed — see Notes.

## Change
```lua
-- Submap: SUPER+R to enter, hjkl to resize any number of times,
-- Esc/Enter/SUPER+R to exit. NOTE: no second string argument to
-- define_submap - passing one makes the submap one-shot (see Notes).
hl.define_submap("resize", function()
    hl.bind("H", hl.dsp.window.resize({ x = -20, y = 0,   relative = true }), { repeating = true })
    hl.bind("L", hl.dsp.window.resize({ x = 20,  y = 0,   relative = true }), { repeating = true })
    hl.bind("K", hl.dsp.window.resize({ x = 0,   y = -20, relative = true }), { repeating = true })
    hl.bind("J", hl.dsp.window.resize({ x = 0,   y = 20,  relative = true }), { repeating = true })
    hl.bind("escape",    hl.dsp.submap("reset"))
    hl.bind("Caps_Lock", hl.dsp.submap("reset"))  -- see caps:swapescape note
    hl.bind("Return",    hl.dsp.submap("reset"))
    hl.bind(mainMod .. " + R", hl.dsp.submap("reset"))
end)
hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))

-- Mouse resize
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Reset focused window's size + master ratio
local function reset_window_size()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.layout("mfact exact 0.55"))
end
hl.bind(mainMod .. " + SHIFT + R", reset_window_size)
```

## Notes
- **Removed 2026-09-21: `SUPER+CTRL+SHIFT+h/j/k/l` (direct 40px resize).** It was only
  ever a workaround for the one-shot-submap bug below — with the submap fixed, it was a
  three-modifier chord duplicating something `SUPER+R` then `hjkl` now does comfortably.
  To bring it back, re-add:
  ```lua
  hl.bind(mainMod .. " + CONTROL + SHIFT + H", hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), { repeating = true })
  hl.bind(mainMod .. " + CONTROL + SHIFT + L", hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), { repeating = true })
  hl.bind(mainMod .. " + CONTROL + SHIFT + K", hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), { repeating = true })
  hl.bind(mainMod .. " + CONTROL + SHIFT + J", hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), { repeating = true })
  ```
  **`SUPER+CTRL+SHIFT+hjkl` is now free.** The rest of that chord family is still in use
  and was deliberately left alone: `Left`/`Right` and `mouse_up`/`mouse_down` move a
  window to the **adjacent workspace on the same monitor** (`m-1`/`m+1`), and `1`/`2`/`3`
  send it to a relative workspace (`m~1..3`). Moving a window to another *monitor* is a
  different bind — `SUPER+SHIFT+bracketleft`/`bracketright`. If those freed hjkl slots get
  reused, the natural fit is vim-key equivalents of the `Left`/`Right`
  move-to-adjacent-workspace binds — not yet done.
- **Fixed 2026-09-21 — the submap used to exit after a single resize.** `SUPER+R` then `h`
  resized once and dropped straight back to `default`, so every step needed `SUPER+R`
  again. Cause: **`hl.define_submap`'s optional second string argument is not decoration —
  it sets the submap's `reset` field, which Hyprland treats as "the submap to jump to
  after any non-`submap` bind in here fires".** Passing `"reset"` therefore declared the
  whole submap *one-shot*. Confirmed in Hyprland 0.56.2 source:
  - `src/config/lua/bindings/LuaBindingsToplevel.cpp` (`hlDefineSubmap`) — `reset` is only
    populated when the call has ≥3 args and arg 2 is a string; `define_submap(name, fn)`
    leaves it empty.
  - `LuaBindingsToplevel.cpp:143` — `kb.submap.reset = mgr->m_currentSubmapReset;`, so
    every bind defined in the submap inherits it.
  - `src/managers/KeybindManager.cpp:819-823` — after running a bind's dispatcher:
    ```cpp
    if (k->handler != "submap" && !k->submap.reset.empty()) {
        auto submapAfter = Config::Actions::state()->m_currentSubmap;
        if (submapBefore == submapAfter)
            Config::Actions::setSubmap(k->submap.reset);
    }
    ```
  **Fix: drop the `"reset"` argument** — `hl.define_submap("resize", function() ... end)`.
  With `submap.reset` empty that branch never runs and the mode is sticky.
- **A workaround that looks right but cannot work:** an earlier attempt wrapped each
  resize in a helper that re-dispatched `hl.dsp.submap("resize")` right after resizing, on
  the theory that `window.resize` was knocking the submap out. Read the snippet above —
  the guard compares the submap name *before* and *after* the dispatcher, so re-asserting
  the **same** name leaves `submapBefore == submapAfter` and the auto-reset fires anyway.
  That theory was also just wrong: dispatching `window.resize` by hand from `hyprctl`
  while inside the submap leaves `hyprctl submap` reading `resize` across repeated calls,
  so the dispatcher never dropped the mode on its own.
- **`Caps_Lock` is bound as an exit key on purpose.** `kb_options` in `inputs.lua` carries
  `caps:swapescape` (set alongside the remap in [[right-alt-as-super]]), so
  the physically-labelled `Esc` key emits `Caps_Lock` and only the CapsLock-position key
  emits `Escape`. Binding both means either physical key leaves the mode. Harmless: the
  bind only exists inside this submap.
- **Debugging these binds on Hyprland 0.56.x:** `hyprctl dispatch` arguments are now **Lua
  expressions**, not the old space-separated strings. `hyprctl dispatch submap resize`
  fails with a Lua syntax error and silently does nothing; the working form is
  `hyprctl dispatch 'hl.dsp.submap("resize")'`. Check the live state with
  `hyprctl submap`, and list what actually registered with
  `hyprctl binds -j | jq '.[] | select(.submap=="resize")'`. Note that `hyprctl binds`
  does **not** expose the `reset` field, so a one-shot submap is indistinguishable from a
  sticky one in its output — that trap is only visible in the config source.
- **API detail:** a dispatcher built inside a custom Lua function (as opposed to passed
  directly as `hl.bind`'s second argument) must be wrapped in `hl.dispatch(...)` to
  actually fire — `hl.dsp.window.move({...})` alone just constructs the dispatcher object,
  it doesn't run it.
- **How the reset works:** toggling a tiled window to floating and back reinserts it into
  the layout tree, which forces Hyprland to recompute sizes for the *whole* tiling tree on
  that workspace — so resetting one window's focus is enough to fix every window's size on
  that workspace, not just the focused one. Verified live: two windows drifted to
  `805px`/`765px` from manual testing, one `SUPER+SHIFT+R` press brought both back to the
  correct default `864px`/`706px` split.
- `mfact exact 0.55` is Hyprland's compiled-in default master ratio — confirmed via
  `hyprctl getoption master:mfact`.
- **Known quirk (2026-08-29): grow/shrink is asymmetric for the last window in a stack.**
  Under [[master-layout]], a stack window's height is a shared boundary with its neighbor,
  not an independent size. For the **bottom-most** window in a vertical stack (nothing
  below it but the screen/dock edge):
  - `K` (shrink, `y = -40`) always works — it just reduces that window's own share, and the
    freed space goes to the window above. This is why shrinking the bottom window visibly
    *grows the window above it* — expected, not a bug.
  - `J` (grow, `y = +40`) does **nothing** — growing requires physical room to expand into,
    and the bottom-most window has none below it (screen/reserved-dock edge). There's no
    window below to take space from, so the grow is a dead end.
  - **Workaround:** to make the bottom window bigger, focus the window *above* it instead
    and shrink that one with `K` — shrinking a neighbor is always well-defined, unlike
    growing into empty space. Dragging the shared border directly with
    `SUPER + right-click drag` also works in both directions, since it manipulates the
    boundary itself rather than issuing a directional grow/shrink command.
  - This is inherent to how tiling-window resize works (a shared-boundary operation), not
    something fixable by remapping keys — the same asymmetry would apply to whichever key
    means "grow" for the edge-most window in any stack.
- See [[finger-ergonomics]] for the recommended fingering on the `SUPER+R` submap bind.
