# Floating-window nudge on SUPER+ALT (and the session-lock move it forced)

**Date:** 2026-09-21
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

## What
`SUPER+ALT+h/j/k/l` and `SUPER+ALT+arrows` nudge a **floating** window by 50px
(hold to repeat). Session lock, which held `SUPER+ALT+L`, was moved out of the way to
free the `l` slot — and then **dropped entirely**: there is no dedicated lock bind any
more, lock is reached via the session panel on `SUPER+SHIFT+Q`.

Tiled windows ignore these — they're positioned by the layout. Use `SUPER+SHIFT+hjkl`
to move those within the layout instead.

## Why
The nudge binds needed a home with vim keys. Three candidates were considered:

- **`CTRL+SHIFT+arrows`** (Mango's original) — rejected. That chord is word-by-word text
  selection in every terminal, browser and editor; a global bind swallows it everywhere.
- **`CTRL+ALT+hjkl/arrows`** — used briefly, then rejected. Same swallowing problem in
  weaker form (`CTRL+ALT+Left/Right` is back/forward in JetBrains IDEs and workspace
  switching in GNOME/KDE), and it breaks the "SUPER is the base modifier" convention
  every other bind in this config follows. This exact chord had already been tried and
  abandoned once before on that same consistency ground — see [[workspace-switching]]
  history item 1.
- **`SUPER+ALT+hjkl/arrows`** — chosen. Super is grabbed by the compositor, so a
  `SUPER+...` bind can never collide with an application shortcut.

## Change
```lua
hl.bind(mainMod .. " + ALT + h", hl.dsp.window.move({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + l", hl.dsp.window.move({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + k", hl.dsp.window.move({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + j", hl.dsp.window.move({ x = 0, y = 50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + Left", hl.dsp.window.move({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + Right", hl.dsp.window.move({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + Up", hl.dsp.window.move({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + Down", hl.dsp.window.move({ x = 0, y = 50, relative = true }), { repeating = true })

-- No dedicated lock bind. The old SUPER+ALT+L line was deleted, not relocated;
-- lock lives in the session panel (SUPER+SHIFT+Q).
```

## Notes
- **Why lock is NOT on `SUPER+L`, the Windows spot.** It was asked for and turned down
  for a concrete reason: `SUPER+L` is vim focus-right (see [[vim-navigation]]), one of
  the most-used binds here, and lock was deliberately moved *off* `SUPER+L` in the first
  place to free it for exactly that. Binding both would not override —
  **Hyprland executes every matching keybind rather than letting a later one win**, so
  `SUPER+L` would focus right *and* lock the screen on a single press. Verified in
  `KeybindManager.cpp`: on a match the loop sets `found = true` and keeps iterating; only
  a `submap` handler breaks out early.
- **Lock bind history, now ended:** `SUPER+L` → `SUPER+CTRL+L` → `SUPER+ALT+L` →
  `SUPER+ALT+X` → **removed**. Each move was caused by a vim-key bind wanting the letter
  back; see [[vim-navigation]] and [[workspace-switching]] for the first two. `SUPER+ALT+X`
  lasted only minutes: it repeated a mistake already recorded in
  [[scroller-proportion-preset-remap]] — Right Alt sends Super, so the ALT must be the
  **left** Alt, and `X` is a left-hand letter too, making it a cramped same-hand claw.
  Rather than hunt for a fifth home, the dedicated bind was dropped: the session panel on
  `SUPER+SHIFT+Q` already offers lock alongside logout/reboot/shutdown, and locking is
  infrequent enough not to need its own chord. **Don't re-add one without reading this.**
- **Fingering:** [[right-alt-as-super]] makes Right Alt send Super, so `SUPER+ALT+...`
  needs the **left** Alt key — press it as Right Alt (Super) + Left Alt + the letter.
  Same two-thumb shape as the `SUPER+ALT+F` fake-fullscreen bind. This is the one cost of
  choosing `SUPER+ALT` over `CTRL+ALT`: for `hjkl` binds [[finger-ergonomics]] prefers all
  modifiers on the left hand, which `CTRL+ALT` (left pinky + left thumb) would have done.
  Judged the lesser cost, since nudging a floating window is infrequent while an app
  shortcut being swallowed is permanent.
- Both `hjkl` and arrows are bound to the same action on purpose — the focus and
  move-window binds already do this, so it matches house style rather than duplicating.
- `SUPER+ALT` now holds only: `F` (fake fullscreen), `R` (refresh-rate toggle), and
  `hjkl` + arrows (nudge). `X` (lock) and `C` (a duplicate session-panel bind) were both
  removed on the same day; `SUPER+ALT+C`, `SUPER+ALT+X` and the whole of `CTRL+ALT` are
  free.
