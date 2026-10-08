# Scroller width-preset cycle: ALT+X → SUPER+U

**Date:** 2026-09-15
**Category:** keybindings
**Files touched:** `~/.config/mango/cfg/keybinds.conf`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Mango]]
<!-- graph:end -->

## What
Rebound the scroller-layout width-preset cycle (`switch_proportion_preset`) from
`ALT+X` to `SUPER+U`.

## Why
Same root cause as [[float-toggle]]: [[right-alt-as-super]] means Right Alt sends
Super, not Alt, so any `ALT+...` bind only works with the **left** Alt key. `X`
is also a left-hand letter (left ring finger in touch typing), so `ALT+X` was a
same-hand, non-thumb chord (left pinky + left ring) — awkward to press, not just
a stretch.

`SUPER+X` and `SUPER+SHIFT+X` were both already taken (control center panel,
and `incgaps`). Considered `SUPER+CTRL+X` (right thumb + right pinky, per
[[finger-ergonomics]]'s rule of putting modifiers on the hand opposite the
letter) as one option, but landed on `SUPER+U` instead — `u` was a free
right-hand letter with no other bind on it, so this needs only a single thumb
modifier instead of stacking two. No mnemonic tie to "proportion"/"preset"; it
was picked purely for being the simplest available chord. Bare `CTRL+X` was
ruled out entirely as a candidate regardless of letter choice — it's the
universal "cut" shortcut in virtually every app, and a global compositor bind
on it would hijack that everywhere.

## Change
`~/.config/mango/cfg/keybinds.conf`, scroller layout section — final state:
```
# Scroller layout - demoted off SUPER+X since X now matches Hyprland's
# control-center key. Moved off ALT+X too - right Alt now sends Super (see
# right-alt-as-super), so Alt+anything only works with the left Alt key, and
# X is also a left-hand letter, making ALT+X an awkward same-hand chord.
# SUPER+U is a free right-hand letter, so this is single-thumb-modifier only
# (no mnemonic tie to "proportion", just the simplest available chord).
bind = SUPER+SHIFT, e, set_proportion, 1.0
bind = SUPER, u, switch_proportion_preset,
```
Applied live with `mmsg dispatch reload_config` — no restart needed; reload log
showed no keybinding-conflict warnings.

## Notes
- Full copy of the file lives at
  [`files/.config/mango/cfg/keybinds.conf`](../files/.config/mango/cfg/keybinds.conf).
- `SUPER+SHIFT+E` (reset scroller window to full width, `set_proportion 1.0`)
  is unaffected and stays as-is.
- Hyprland port: both resize binds now un-maximize the window first, see
  [[colresize-unmaximize-first]].
