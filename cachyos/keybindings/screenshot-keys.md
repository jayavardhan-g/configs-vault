# Screenshot keys: Print, SUPER+Print, F6

**Date:** 2026-09-14
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

## What
- `Print` — full-screen screenshot
- `SUPER+Print` — region/cropped screenshot
- `F6` — region/cropped screenshot (second path to the same action)

## Why
User wanted the physical Print key to take a full-screen shot (it was
previously wired the other way round — plain `Print` did a region capture,
`SUPER+Print` did full-screen) and a laptop Fn-row key for the cropped
capture instead of needing the modifier.

## Change
```lua
hl.bind("Print",               hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(noctCall .. "screenshot-region"))
hl.bind("F6",                  hl.dsp.exec_cmd(noctCall .. "screenshot-region"))
```
(Previous state had `Print` → `screenshot-region` and `SUPER+Print` →
`screenshot-fullscreen` — swapped.)

## Notes
- **This laptop's Fn+F6 hotkey is not the same thing as the `F6` key.**
  Confirmed via `wev`: pressing the physical `F6` key alone sends a clean
  `F6` keysym and correctly triggers this bind. Pressing **Fn+F6** instead
  sends a firmware-level `Super+Shift+S`-style key sequence directly (real
  `S`/`Super_L`/`Shift_L` keycodes captured, no `F6` at all) — which is a
  completely different bind ([[special-workspace-toggle]]'s equivalent, see
  the Mango `tag_special_tag` note in the portable `mango/keybinds.md`). If
  Fn+F6 ever appears to "toggle a workspace" instead of screenshotting, that
  is expected — it's genuinely a different physical key event, not a bug in
  this bind.
- **Physical Print key was confirmed working under Hyprland already** before
  this change (just bound to the wrong action) — unlike on Mango, where the
  same physical key's firmware only sends a release event, never a press,
  which needed a release-triggered bind (`bindr`) there and still doesn't
  fully work due to a deeper engine limitation (see the portable
  `mango/keybinds.md`). Hyprland's more mature input handling doesn't hit
  the same problem.
