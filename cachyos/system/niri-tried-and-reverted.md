# Tried niri, went back to Hyprland

**Date:** 2026-09-23
**Category:** system
**Files touched:** none persisted (`~/.config/niri/` created for the trial, then deleted)

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Mango]] · [[niri]] · [[NVIDIA]]
<!-- graph:end -->

## What
Installed niri 26.04 + `xwayland-satellite`, logged into it with a config ported from
Hyprland/Mango, then uninstalled both and deleted the config the same day. Hyprland stays
the only daily session; Mango stays installed for a revisit at its 1.0 release (see
[[mango-nvidia-cpu-spin-switched-to-hyprland]]).

## Why
niri was appealing for its scrolling-first layout and built-in Overview (live window
previews — the Alt+Tab-with-previews idea that has no ready-made tool on Hyprland). It
worked well on this hardware, but it's deliberately less configurable, and the things it
lacks are ones this setup relies on:
- no special workspace / scratchpad (the hidden claude/Spotify/labvpn/home apps)
- no master layout, no per-workspace layout switching
- no Lua config or event hooks (sequenced autostart, monitor-hotplug logic)
- no submaps (`SUPER+R` resize mode), no window swallowing

## Change
To undo the trial:
```bash
sudo pacman -Rns niri xwayland-satellite
rm -r ~/.config/niri
```
Then pick Hyprland at the Noctalia greeter once (it remembers the last session picked).

## Notes
Worth knowing if niri is ever retried:
- **Hardware was fine on niri**: both monitors came up correctly (the NVIDIA-wired HDMI
  included) and there was no Mango-style busy-loop. niri used ~18–25% CPU steady, more
  than Hyprland's ~11% but well below Mango's ~50%; temps 63°C, fans 3500 RPM.
- **Screen sharing needs `xdg-desktop-portal-gnome`** — niri's portal config
  (`/usr/share/xdg-desktop-portal/niri-portals.conf`) prefers gnome, which isn't
  installed here, so screencasting wouldn't work without it.
- The physical Print key only sends a key *release*; niri binds fire on press, so it
  would need a different screenshot key.
- Hyprland features niri *does* cover: workspaces following a monitor through
  unplug/replug (built in, no script needed), tabbed columns (≈ groups), window rules,
  blur, gradient focus ring, animations, touchpad gestures, `niri msg` (≈ `hyprctl`).
- The full ported config (binds, input, monitors, look, autostart) is on the unmerged
  git branch `worktree-niri-trial` at `cachyos/files/.config/niri/config.kdl` — a
  starting point if this is ever retried.
