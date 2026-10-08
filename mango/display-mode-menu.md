# Windows-style display mode menu: SUPER+P (ported from Hyprland)

**Date:** 2026-09-14
**Category:** mango
**Files touched:** `~/.config/mango/cfg/keybinds.conf`, `~/.config/mango/scripts/display-mode.sh` (new)

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Mango]] · [[Monitors]]
<!-- graph:end -->

## What
`SUPER+P` opens a `fuzzel --dmenu` popup with three choices — Extend, PC
screen only, Second screen only — for the laptop panel (`eDP-1`) + external
monitor (`HDMI-A-1`) setup, same idea as the existing Hyprland version (see
`cachyos/keybindings/display-mode-menu.md`) but using Mango's `mmsg dispatch`
IPC instead of `hyprctl eval`. **No "Duplicate" (mirror) option** — see
Notes, this is a real capability gap, not a naming difference.

This freed up `SUPER+P` from region-screenshot duty in Mango, since `Print`
and `F6` already cover that (see [[keybinds]]).

## Why
User wanted the same Win+P-style quad-mode toggle on Mango that already
existed on Hyprland.

## Change
`~/.config/mango/scripts/display-mode.sh` (new, `chmod +x`):
```bash
#!/usr/bin/env bash
set -euo pipefail

INTERNAL="eDP-1"
EXTERNAL="HDMI-A-1"

choice=$(printf '%s\n' "Extend" "PC screen only" "Second screen only" \
    | fuzzel --dmenu --prompt "Display mode: ")

[ -z "$choice" ] && exit 0

case "$choice" in
"Extend")
    mmsg dispatch enable_monitor,"$INTERNAL"
    mmsg dispatch enable_monitor,"$EXTERNAL"
    ;;
"PC screen only")
    mmsg dispatch enable_monitor,"$INTERNAL"
    mmsg dispatch disable_monitor,"$EXTERNAL"
    ;;
"Second screen only")
    mmsg dispatch disable_monitor,"$INTERNAL"
    mmsg dispatch enable_monitor,"$EXTERNAL"
    ;;
esac
```

`~/.config/mango/cfg/keybinds.conf`:
```
bind = SUPER, p, spawn, /home/jayavardhan/.config/mango/scripts/display-mode.sh
```
(replaces the old `bind = SUPER, p, spawn, noctalia msg screenshot-region`)

## Notes
- **Mango has no mirror/clone/duplicate monitor capability at all**,
  confirmed exhaustively: no `mirror` string anywhere in the dispatch table
  (`src/config/parse_config.c`), no such function in any of the 82 `.c`/`.h`
  files in the full 0.17.0 source tree (the one incidental hit, in
  `src/input/trackpad.c`, is an unrelated touchpad swipe-gesture setting
  named `mirror_view`), and no mention in the monitors wiki page either.
  This isn't fixable from config — it would need to be built upstream.
- `enable_monitor`/`disable_monitor`/`toggle_monitor` (confirmed via source)
  each take a single monitor-name argument, e.g.
  `mmsg dispatch enable_monitor,eDP-1`. There's also `sleep_monitor`/
  `wakeup_monitor` (untested, presumably DPMS-style power control rather
  than layout-affecting).
- Unlike the Hyprland version, this script doesn't need to pass
  `mode=preferred`/scale/position on every call — those stay whatever
  [[multi-monitor-setup]] already configured in `monitors.conf`;
  enable/disable doesn't touch them.
- Absolute path used in the `spawn` bind (`/home/jayavardhan/...`) rather
  than `$HOME`-relative, as a safe default — not confirmed either way
  whether Mango's config parser expands `$HOME` in `spawn` argument strings
  the way `os.getenv` does in Hyprland's Lua config, so didn't rely on it.
