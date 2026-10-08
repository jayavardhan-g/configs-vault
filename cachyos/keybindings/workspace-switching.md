# hjkl workspace switching

**Date:** 2026-08-28
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Monitors]]
<!-- graph:end -->

## What
`SUPER+CTRL+H` / `SUPER+CTRL+L` switch to the previous/next workspace on the current
monitor (same behavior as the existing `SUPER+CTRL+Left/Right`, just with vim keys).

## Why
User wanted a vim-key equivalent of adjacent-workspace switching. Went through two
iterations before landing here — see history below, kept for context since the reasoning
(ergonomics of Alt vs Ctrl once Right Alt = Super) is non-obvious.

## Change
```lua
hl.bind(mainMod .. " + CONTROL + H", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + L", hl.dsp.focus({ workspace = "m+1" }))
```

Session lock collided with `SUPER+CTRL+L` during this change and was bumped along. It no
longer has a dedicated bind at all — it's reached through the session panel on
`SUPER+SHIFT+Q`. See [[floating-window-nudge]] for the full history.

## Notes / history
1. First attempt: plain `CTRL+ALT+H/L` (no Super) — global regardless of Hyprland's mod
   key. Worked, but inconsistent with every other bind in this config using `SUPER` as
   the base modifier.
2. Changed to `SUPER+ALT+H/L` to match convention.
3. Final: changed to `SUPER+CTRL+H/L`, freeing up `ALT+H/L`. Reasoning: since
   [[right-alt-as-super]] makes Right Alt send Super, `SUPER+CTRL+H/L` can be pressed as
   **Right Alt + Left Ctrl + h/l** — entirely on the left hand / home row, no reach to the
   physical Super key. This bumped session-lock off `SUPER+CTRL+L` (where it had briefly
   lived, see [[vim-navigation]]) to `SUPER+ALT+L`. It moved once more to `SUPER+ALT+X`
   to free the `l` slot for the floating-window nudge, and was then dropped altogether —
   see [[floating-window-nudge]].
