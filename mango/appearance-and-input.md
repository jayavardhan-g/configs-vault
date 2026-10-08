# Appearance and input matched to the Hyprland setup

**Date:** 2026-09-13
**Category:** mango
**Files touched:** `~/.config/mango/cfg/appearance.conf`, `~/.config/mango/cfg/input.conf`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Mango]]
<!-- graph:end -->

## What
Tightened the default gaps (including a separate special-tag-only gap
setting most guides don't mention), matched the special-tag border color to
the normal focus color, and carried over the same keyboard/scroll input
preferences already set up on Hyprland.

## Why
The `cachyos-mango-noctalia` skeleton's default gaps (20/40px) were much
larger than the tuned Hyprland values (1/3px), and the special-tag
scratchpad window specifically sat with an even bigger, separately-configured
margin. Input prefs (CapsLock/Escape swap, Right-Alt-as-Super, per-device
scroll direction) were already decided for Hyprland and just needed
replicating.

## Change

`~/.config/mango/cfg/appearance.conf`:
```
gappih = 1
gappiv = 1
gappoh = 3
gappov = 3
# Special tag (tag 0 / SUPER+S scratchpad) has its own separate gap settings
# in mangowm 0.17.0+ - matched to the same values as above.
special_gappih = 1
special_gappiv = 1
special_gappoh = 3
special_gappov = 3
```
```
scratchpadcolor = 0x47add6ff   # was 0x516c93ff - now identical to focuscolor
```

`~/.config/mango/cfg/input.conf`:
```
# CapsLock -> Escape, Right Alt -> Super (matches the Hyprland setup)
xkb_rules_options = caps:swapescape,altwin:swap_ralt_rwin

# Windows-style scroll direction per device type (matches the Hyprland setup):
# mouse wheel traditional, touchpad two-finger scroll natural.
mouse_natural_scrolling = 0
trackpad_natural_scrolling = 1
```

## Notes
- **`special_gappih`/`special_gappiv`/`special_gappoh`/`special_gappov` are
  a completely separate set of options from the normal `gappi*`/`gappo*`
  ones**, specific to the special-tag (tag 0) overlay, defaulting to
  `10/10/20/20` regardless of what the normal gaps are set to. Confirmed by
  reading `src/config/parse_config.c` directly in the 0.17.0 source — not
  documented anywhere obvious, and the default 20px margin looks exactly
  like a rendering bug if you don't know this option exists. There's also a
  `special_dim` option (default `0.5`) that dims the background while the
  special tag is shown - left at default, not touched.
- Border **color** for a special-tag window only diverges from a normal
  focused window's `focuscolor` when Mango's internal `is_in_scratchpad` flag
  is set — which the `tag_special_tag` dispatcher (see [[keybinds]]) does
  **not** set, only the older minimize-pile mechanism does. So in practice
  the two already look identical without this change; matching
  `scratchpadcolor` to `focuscolor` here is a belt-and-suspenders move for
  the edge case, not a fix for an actually-observed difference. Confirmed by
  reading `get_border_color()` in `src/manage/client.c` directly.
- XKB options use a different key name than Hyprland: `xkb_rules_options`
  here vs Hyprland's `kb_options`, same comma-separated value format
  otherwise. Confirmed via Mango's own docs
  (`mangowm.github.io/docs/configuration/input`) rather than guessed.
- A live `reload_config` (`SUPER+F5`) does **not** reliably re-apply XKB
  changes to an already-running keyboard — needed a full logout/login for
  `caps:swapescape`/`altwin:swap_ralt_rwin` to actually take effect, same as
  on Hyprland.
