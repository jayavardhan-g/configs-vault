# Theme Mode pinned to Dark (not Auto)

**Date:** 2026-09-13
**Category:** noctalia
**Files touched:** `~/.local/state/noctalia/settings.toml` (`[theme] mode`)

<!-- graph:begin -->
**Graph:** [[Noctalia]] · [[kitty]]
<!-- graph:end -->

## What
Noctalia's `theme.mode` was `"auto"`. Set it to `"dark"` so the shell (and GTK/Qt/kitty/etc
apps via templates) always stay dark, regardless of time of day.

## Why
Wallpaper auto-rotation (`[wallpaper.automation] enabled = true`) is on, cycling images on
a timer. Some rotations appeared to make the whole theme "go light" even though it's
supposed to stay dark. Root cause was **not** the wallpaper image itself — Noctalia's
`"auto"` theme mode is a **time-of-day** switch (day → light, night → dark; see the
in-app description: "Choose Dark, Light, or Auto based on time of day"), completely
independent of `theme.source = "wallpaper"` (which only controls where *accent colors*
are generated from, not light/dark). The two features happened to change around the same
time, making it look like specific wallpapers triggered light mode, but `noctalia msg
theme-mode-get` returned `light` in the middle of the afternoon regardless of which
wallpaper was active — confirming it was the daytime auto-switch, not the image.

## Change
```sh
noctalia msg theme-mode-set dark
```
This persists `mode = "dark"` under `[theme]` in `~/.local/state/noctalia/settings.toml`
directly (don't hand-edit that file — it's live app state, rewritten by the running
daemon; use the CLI or the Settings panel instead).

Alternative via GUI: open Noctalia settings (`SUPER + Z` in this Hyprland setup, but the
panel itself is portable) → Appearance → **Theme Mode** → `Dark`.

## Notes
- `noctalia msg theme-mode-get` / `theme-mode-set <mode>` / `theme-mode-toggle` are the
  relevant CLI commands (`noctalia msg --help` lists all of them).
- There's a separate, more granular option — `shell-theme-mode` — to pin *just* Noctalia's
  own bar/panels independently of the apps-wide `theme-mode` (which applies through
  matugen-style templates to gtk3/gtk4/qt/kitty/btop/alacritty, per
  `[theme.templates] builtin_ids` in `~/.config/noctalia/config.toml`). Not used here —
  went with pinning the global mode since the light flip was showing up in apps too, not
  just the bar.
- Wallpaper rotation itself (interval, order, folder) is unrelated and unchanged — see
  `[wallpaper.automation]` / `[wallpaper]` in `settings.toml` if that ever needs tuning.
- This is a pure Noctalia-app setting, unrelated to Hyprland/CachyOS — Noctalia ships
  templates for niri/sway/labwc/mango/scroll too, so this same fix applies unchanged on
  any of those. Compare to `cachyos/system/noctalia-greeter-sync-password-prompt.md`,
  which *is* CachyOS-specific because that issue is caused by `run0`/polkit interaction,
  not by Noctalia itself.
