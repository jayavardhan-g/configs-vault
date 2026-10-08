# Tighter gaps + orange-only active border

**Date:** 2026-09-01
**Category:** appearance
**Files touched:** `~/.config/hypr/config/decorations.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

## What
Reduced the spacing between and around tiled windows, and changed window borders so only
the focused window shows a visible border (an orange-to-transparent diagonal gradient) —
unfocused windows now have no visible border at all.

## Why
User wanted less dead space between window edges, and a border scheme that highlights only
the active window rather than outlining every window equally.

## Change

`~/.config/hypr/config/decorations.lua` — inside the existing `hl.config({ general = {...} })`
block:
```lua
hl.config({
    general = {
        layout = "master",
        gaps_in = 1,
        gaps_out = 3,
        extend_border_grab_area = 10,
        resize_on_border = true,
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgba(ff5e00cc)", "rgba(00000000)" },
                angle = 45,
            },
            inactive_border = {
                colors = { "rgba(00000000)" },
            }
        },
    },
    -- group = {...} and decoration = {...} blocks unchanged, see file
})
```
`gaps_in` was `3`, `gaps_out` was `8`. `active_border`/`inactive_border` previously used the
`CACHYLGREEN`/`CACHYDGREEN` gradient and `CACHYGRAY` (see `colors.lua`) for both active and
inactive borders equally.

## Notes
- **Inactive border is `rgba(00000000)` (zero alpha), not removed** — `border_size` stays at
  `2` so the layout reservation is unchanged; the border is just invisible on unfocused
  windows. This is the standard way to get a "border only on focus" look without touching
  `border_size`.
- **Active border gradient fades to fully transparent, not just a darker shade** — one end
  of the diagonal (`angle = 45`) is `00000000`, so the border visually vanishes on that side
  of the focused window rather than just dimming. Confirmed as the intended look (glow-off
  effect); if this ever reads as a rendering glitch instead, swap the transparent endpoint
  for a low-alpha version of the same hue (e.g. `rgba(ff5e0033)`) to keep the border visible
  all the way around while still fading.
- Several other active-border palettes were tried live before settling on orange (white/gray,
  the original Cachy green gradient, a Dracula-theme purple/blue, magenta/cyan) — not
  recorded here individually since they were superseded in the same sitting, not separate
  decisions.
- Not re-verified via a fresh Hyprland restart (both changes apply live via Hyprland-Lua's
  auto-reload / `hyprctl reload`, and were visually confirmed by the user at the time).
