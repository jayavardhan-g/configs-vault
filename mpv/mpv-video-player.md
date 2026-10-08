# mpv video player

**Date:** 2026-09-14
**Category:** mpv
**Files touched:** none (default config used, no `~/.config/mpv/` customization yet)

<!-- graph:begin -->
**Graph:** [[mpv]]
<!-- graph:end -->

## What
Installed `mpv` as the local video player — no player was installed by default.

## Why
Needed something to play video files; picked mpv over VLC/Celluloid for being minimal
and keyboard-driven, matching the rest of this setup (tiling WM, vim-style binds).

## Change
```bash
sudo pacman -S mpv
```
Installs clean from the official CachyOS repos (`cachyos-extra-v3`) — no AUR needed.

## Notes
- No custom `~/.config/mpv/mpv.conf` written yet — using stock defaults. If that changes,
  update this entry with the config rather than creating a separate one.
