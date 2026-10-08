# Mango transparency: opacity vs. blur, and what's actually live

**Date:** 2026-09-14
**Category:** appearance
**Files touched:** `~/.config/mango/cfg/appearance.conf`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Mango]]
<!-- graph:end -->

## What
Investigated why Mango's windows looked more "see-through" than Hyprland's, and why
several attempted fixes appeared to do nothing. Ended up reading Mango's actual C source
(a cached copy of the `mango-0.17.0` tarball, extracted during a prior session) rather
than guessing from the config file/binary alone. Net result: `unfocused_opacity` left at
`0.75` (tune further on a **freshly opened window**, see Notes), blur's
`brightness`/`contrast`/`saturation` confirmed live and left neutral at `1.0`, blur
strength raised via `num_passes`/`radius`/`blur_optimized`.

## Why
Mango's `appearance.conf` never set an opacity value at all, so windows ran on Mango's
compiled-in default. Multiple opacity values were tried (`0.85`, `0.95`, `0.5`, `1`) with
no visible change reported each time, which looked like a dead/broken config key — until
checking the source showed why. Separately, blur's color-matrix parameters
(`brightness`/`contrast`/`saturation`) were suspected dead too, for the same "no visible
change" reason, but turned out to be a false alarm caused by testing only a subtle value
change.

## Change
Final pass: exact-mirrored every blur/opacity value Hyprland's `decorations.lua` either
sets explicitly or leaves at a real (queried, not guessed) internal default —
`hyprctl getoption` was run directly while logged into Hyprland to get the true live
numbers for values `decorations.lua` never overrides itself.

`~/.config/mango/cfg/appearance.conf`:
```
# Mango's real compiled-in default is 1.0 (fully opaque) for both
# focused_opacity and unfocused_opacity - confirmed in source
# (parse_config.c ~3986). Earlier attempts to set this appeared to do
# nothing because client.c (~1909-1910) only copies config.unfocused_opacity
# into a window at CREATION time - reload_config (SUPER+F5) re-parses the
# file but never re-applies opacity to windows already open, only to ones
# opened afterward. Test any new value on a freshly-opened window, not an
# existing one.
unfocused_opacity = 0.85
focused_opacity = 0.95

blur = 1
blur_layer = 0
blur_optimized = 0
# num_passes/radius/brightness/contrast/noise mirror Hyprland's real live
# defaults (queried via hyprctl getoption while logged into Hyprland,
# since decorations.lua never overrides them itself):
# decoration:blur:passes=4, size=5, brightness=1.0, contrast=0.8916,
# noise=0.0117.
blur_params_num_passes = 4
blur_params_radius = 5
blur_params_noise = 0.0117
blur_params_brightness = 1.0
blur_params_contrast = 0.8916
# No true Hyprland equivalent to mirror here: Hyprland uses a different
# "vibrancy" algorithm (decoration:blur:vibrancy, default 0.1696) instead
# of a flat saturation multiplier, on a different scale entirely (0 = no
# effect there, vs 1.0 = no effect here) - left neutral rather than
# guessing a translated number. Confirmed this key is live (not dead
# config) by briefly setting it to 0 and seeing the blurred backdrop
# render in grayscale.
blur_params_saturation = 1.0
```

## Notes
- **`focused_opacity`/`unfocused_opacity` are only applied at window CREATION time, not
  on reload.** `client.c:1909-1910` sets `c->focused_opacity`/`c->unfocused_opacity` from
  `config.focused_opacity`/`config.unfocused_opacity` inside the per-client init block,
  which only runs once when a window is first mapped. `reload_config` (`SUPER+F5`) calls
  `parse_config()` + `reset_option()`, and `reset_option()`'s refresh list
  (`reapply_cursor_style`/`reapply_property`/`reapply_rootbg`/`reapply_keyboard`/
  `reapply_pointer`/`reapply_master`/`reapply_tagrule`/`reapply_monitor_rules`) never
  touches an existing client's opacity fields. **So changing the value and reloading does
  nothing to windows that are already open — only windows opened afterward pick up the
  new value.** Always test opacity changes on a brand-new window.
- **Mango's real default is `1.0` (fully opaque) for both `focused_opacity` and
  `unfocused_opacity`** (`parse_config.c` ~3986-3987) — corrects an earlier wrong
  assumption in this same investigation that Mango defaulted to something more
  transparent than Hyprland. It never did; the original "too much transparency"
  complaint was from blur, not opacity, the whole time.
- **`focused_opacity` does exist as a real, separate config key** (`parse_config.c:608`)
  — corrects an earlier wrong claim in this file (and told to the user directly) that no
  such key exists in Mango. It's real; it just wasn't visible in a naive `strings`
  search because `"focused_opacity"` sits as a substring inside the longer
  `"unfocused_opacity"` string in the binary's string table.
- **`blur_params_brightness`/`contrast`/`saturation` ARE live, not dead config** —
  corrects a second wrong claim made mid-investigation (that these are parsed but never
  forwarded to the renderer, based on the absence of separate
  `wlr_scene_set_blur_brightness/contrast/saturation` calls). Mango actually forwards all
  three through a single bundled call in `reset_blur_params()`
  (`parse_config.c:4250-4254`): `wlr_scene_set_blur_data(scene, num_passes, radius,
  noise, brightness, contrast, saturation)`. Unlike opacity, this runs for every open
  monitor on every `reload_config`, so it applies live to already-open windows. Confirmed
  empirically too: setting `blur_params_saturation = 0` and reloading rendered the
  blurred backdrop in grayscale, then reverted back to `1.0`.
- Lesson for future investigation here: prefer reading the actual Mango source (cached in
  this session's scratch dir as an extracted `mango-0.17.0` tarball, or re-download from
  the AUR/upstream if unavailable) over inferring behavior from `strings`/`nm` on the
  compiled binary alone — the binary-only approach produced two separate wrong
  conclusions in this same investigation before the source settled both.
- **Still not an exact mirror — three things have no Mango equivalent at all:**
  `fullscreen_opacity` (Hyprland: `1.0`, always fully opaque when fullscreened),
  `dim_special` (Hyprland: `0.3`, dims everything else when the special/scratchpad
  workspace is open), and `blur.special` (Hyprland: `true`, blurs only the scratchpad
  backdrop specifically). None of these concepts exist as config keys in Mango.
- **`border_size` still doesn't match** — Hyprland `general:border_size = 2`, Mango
  `borderpx = 4` — flagged early on when first comparing the two configs and never
  resolved; left alone here since it wasn't part of this blur/opacity pass.
