# Mango cursor theme matched to Hyprland's

**Date:** 2026-09-15
**Category:** appearance
**Files touched:** `~/.config/mango/cfg/appearance.conf`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Mango]]
<!-- graph:end -->

## What
Set `cursor_theme = Bibata-Modern-Ice` in Mango's config (was `capitaine-cursors`).
`cursor_size = 24` was already correct.

## Why
Mango is an alternate window manager installed alongside Hyprland on this machine, and
its shipped default config (from `/etc/skel/.config/mango/cfg/appearance.conf`) sets
`cursor_theme = capitaine-cursors` — an unrelated theme nobody chose here. Hyprland's
actual cursor is `Bibata-Modern-Ice` size `24`, set via `XCURSOR_THEME`/`HYPRCURSOR_THEME`
in `~/.config/uwsm/env` and mirrored in `~/.config/gtk-3.0/settings.ini`
(`gtk-cursor-theme-name`). Asked to make Mango's cursor match Hyprland's.

## Change
`~/.config/mango/cfg/appearance.conf`:
```
# Matched to Hyprland's actual cursor (set in ~/.config/uwsm/env via
# XCURSOR_THEME/HYPRCURSOR_THEME, also mirrored in gtk-3.0/settings.ini) -
# mango's stock default here was capitaine-cursors, unrelated to Hyprland.
cursor_theme = Bibata-Modern-Ice
cursor_size = 24
```
Applied live with `mmsg dispatch reload_config` (same effect as the `SUPER+F5` bind in
`keybinds.conf`) — no restart needed.

## Notes
- Confirmed `Bibata-Modern-Ice` is installed at `~/.local/share/icons/Bibata-Modern-Ice`
  before switching, so Mango wouldn't silently fall back to its built-in cursor for a
  missing theme.
- If Hyprland's cursor theme/size ever changes (edit `~/.config/uwsm/env`), update this
  file's `cursor_theme`/`cursor_size` to match and reload Mango the same way.
