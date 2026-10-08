# Float toggle rebind: SUPER+ALT+Space → SUPER+SHIFT+F

**Date:** 2026-08-29
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

## What
The "toggle window floating" bind moved from `SUPER+ALT+Space` to `SUPER+SHIFT+F`.

## Why
`SUPER+ALT+Space` requires two thumb-category modifiers (Super and Alt, per
[[finger-ergonomics]]) plus Space, which is itself a thumb-region key — there's no
separate hand to offload onto, and no third contact point available once both thumbs are
occupied holding modifiers. A same-thumb "roll" from Right Alt (=Super, see
[[right-alt-as-super]]) onto Space was tried and felt unreliable in practice: a single
thumb can't cleanly hold one key down and press an adjacent one at the same instant.
Rather than force an awkward fingering, the bind was moved to a combo that fits the
existing `SUPER+SHIFT+<letter>` pattern already used elsewhere (e.g. window-move binds).
`SUPER+F` was the first choice (mirrors fullscreen's `SUPER+F`... actually was already
taken by fullscreen, see Notes) so `SUPER+SHIFT+F` was used instead.

## Change
```lua
hl.bind(mainMod .. " + SHIFT + F",   hl.dsp.window.float({ action = "toggle" }))
```
(Replaces the old `hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))` line.)

## Notes
- `SUPER+F` was considered first (clean 2-key chord, no third contact point) but is
  already bound to plain fullscreen (`hl.dsp.window.fullscreen()`), so it wasn't free.
- Fingering: left thumb (Super) + left pinky (Shift), right index (F) — same
  hand-split pattern as `SUPER+SHIFT+h/j/k/l` window-move binds. See
  [[finger-ergonomics]] for the full reference table.
- General lesson kept for future binds: avoid combos that need two thumb-category
  modifiers (Super + Alt) held simultaneously with a third thumb-region key (Space) —
  there's no clean fingering for that shape once both thumbs are already committed.
