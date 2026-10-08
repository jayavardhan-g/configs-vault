# Mango border width matched to Hyprland; gradient approximated with a flat color

**Date:** 2026-09-14
**Category:** appearance
**Files touched:** `~/.config/mango/cfg/appearance.conf`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Mango]]
<!-- graph:end -->

## What
Set `borderpx = 2` (was `4`) to match Hyprland's `general:border_size = 2`. Set
`focuscolor = 0x82dcccff` (was `0x47add6ff`, an unrelated blue) as a flat-color
approximation of Hyprland's active-border gradient.

## Why
`border_size`/`borderpx` had mismatched since the two configs were first compared —
flagged then, fixed now. Separately, asked whether Mango can do a gradient border like
Hyprland's `active_border` (`CACHYLGREEN -> CACHYDGREEN`, 45°, see
`~/.config/hypr/config/decorations.lua`) — it can't (see Notes) — so picked the closer of
the two gradient stops as a single flat color instead of leaving Mango's border an
unrelated blue.

## Change
`~/.config/mango/cfg/appearance.conf`:
```
borderpx = 2
border_radius = 10

rootcolor = 0x201b14ff
bordercolor = 0x444444ff
# Mango has no gradient-border support at all (confirmed: no "gradient" in
# Mango's source or binary) - this is a flat-color approximation of
# Hyprland's active_border gradient (CACHYLGREEN -> CACHYDGREEN, 45deg, see
# ~/.config/hypr/config/decorations.lua), using the brighter of the two
# stops since a single flat color can't represent a gradient.
focuscolor = 0x82dcccff
```

## Notes
- **Mango has no gradient-border concept at all** — confirmed via `grep -rl gradient` on
  the cached `mango-0.17.0` source tree (zero hits) and `strings /usr/bin/mango | grep -i
  gradient` on the installed binary (zero hits). Border colors are flat, one color per
  state (`bordercolor`/`focuscolor`/`maximizescreencolor`/`urgentcolor`/
  `scratchpadcolor`/`globalcolor`/`overlaycolor`), no multi-stop/angle support like
  Hyprland's `col.active_border.colors`/`angle`.
- `0x82dcccff` is `CACHYLGREEN` (see `~/.config/hypr/config/colors.lua`) — the brighter of
  Hyprland's two gradient stops, picked over `CACHYDGREEN` or a midpoint blend as a
  judgment call, not measured. Revisit if it doesn't read right visually.
- Not yet visually confirmed — set from a session in Hyprland, not Mango. Check next time
  you're in Mango and reload (`SUPER+F5`); unlike opacity, `bordercolor`/`focuscolor` are
  flat state colors read every time a border is drawn, not baked in at window-creation
  time, so this should update live without needing a fresh window.
