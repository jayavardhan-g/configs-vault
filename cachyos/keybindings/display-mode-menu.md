# Windows-style display mode menu: SUPER+P

**Date:** 2026-09-13
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`, `~/.config/hypr/scripts/display-mode.sh` (new)

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Monitors]]
<!-- graph:end -->

## What
`SUPER+P` opens a `fuzzel --dmenu` popup with four choices — Extend, Duplicate, PC
screen only, Second screen only — mirroring Windows' Win+P panel for the laptop panel
(`eDP-1`) + external monitor (`HDMI-A-1`) setup. Picking one applies immediately via
`hyprctl eval` calling the Lua `hl.monitor()` API (this Hyprland build — v0.56.2 — uses a
native Lua config, so the legacy `hyprctl keyword monitor ...` command doesn't work; it
errors with "keyword can't work with non-legacy parsers. Use eval."). The existing
`SUPER+P` → `hyprpicker` (color picker) bind was moved to `SUPER+SHIFT+P` to free the key,
since the user rarely uses the color picker.

## Why
User wanted Windows' Win+P quad-mode toggle for a laptop + single external monitor dock
setup, discoverable via a keypress rather than remembering `hyprctl` invocations.

## Change
`~/.config/hypr/scripts/display-mode.sh` (new, `chmod +x`):
```bash
#!/usr/bin/env bash
set -euo pipefail

INTERNAL="eDP-1"
EXTERNAL="HDMI-A-1"
SCALE="1.25"

choice=$(printf '%s\n' "Extend" "Duplicate" "PC screen only" "Second screen only" \
    | fuzzel --dmenu --prompt "Display mode: ")

[ -z "$choice" ] && exit 0

case "$choice" in
"Extend")
    hyprctl eval "
        hl.monitor({output=\"$INTERNAL\", mode=\"preferred\", position=\"0x0\", scale=\"$SCALE\", disabled=false, mirror=\"\"})
        hl.monitor({output=\"$EXTERNAL\", mode=\"preferred\", position=\"auto\", scale=\"$SCALE\", disabled=false, mirror=\"\"})
    "
    ;;
"Duplicate")
    hyprctl eval "
        hl.monitor({output=\"$INTERNAL\", mode=\"preferred\", position=\"0x0\", scale=\"$SCALE\", disabled=false, mirror=\"\"})
        hl.monitor({output=\"$EXTERNAL\", mode=\"preferred\", position=\"auto\", scale=\"$SCALE\", disabled=false, mirror=\"$INTERNAL\"})
    "
    ;;
"PC screen only")
    hyprctl eval "
        hl.monitor({output=\"$INTERNAL\", mode=\"preferred\", position=\"0x0\", scale=\"$SCALE\", disabled=false, mirror=\"\"})
        hl.monitor({output=\"$EXTERNAL\", disabled=true})
    "
    ;;
"Second screen only")
    hyprctl eval "
        hl.monitor({output=\"$EXTERNAL\", mode=\"preferred\", position=\"0x0\", scale=\"$SCALE\", disabled=false, mirror=\"\"})
        hl.monitor({output=\"$INTERNAL\", disabled=true})
    "
    ;;
esac
```

`~/.config/hypr/config/binds.lua`:
```lua
hl.bind(mainMod .. " + P",          hl.dsp.exec_cmd(launchPrefix .. os.getenv("HOME") .. "/.config/hypr/scripts/display-mode.sh"))
...
hl.bind(mainMod .. " + SHIFT + P",  hl.dsp.exec_cmd("hyprpicker -a -n"))
```
(The second line replaces the old `hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -a -n"))`.)

Package install: `sudo pacman -S fuzzel` (needed the popup menu; no other Wayland
dmenu-style tool — wofi/rofi-wayland/zenity/kdialog — was installed on this machine).

## Notes
- **Every `hl.monitor()` field not passed is left at its previous value, not reset** —
  confirmed live: after mirroring `HDMI-A-1` onto `eDP-1` then calling `hl.monitor` again
  without `mirror`/`disabled`, the old mirror and disabled state stuck. Every branch above
  passes `disabled=false, mirror=""` explicitly even when irrelevant to that mode, so
  switching between any two modes always fully resets the other's state.
- `hyprctl monitors` (no args) hides mirrored/duplicate outputs from its listing; use
  `hyprctl monitors all` to actually see a mirrored monitor's `mirrorOf` field.
- `SUPER+P` was already bound to `hyprpicker` before this change — moved it to
  `SUPER+SHIFT+P` rather than picking a different key for the display menu, since Win+P
  parity was the point and the user doesn't use the color picker often.
- Considered **kanshi** (auto-applies a saved layout profile on monitor connect/disconnect,
  no menu needed at all for a fixed desk setup) as a better long-term fit than a manual
  menu — not set up yet, still just this menu.
- Ported to Mango too (2026-09-14) — see the portable `mango/display-mode-menu.md`.
  That version is missing the "Duplicate" option entirely: Mango has no
  mirror/clone monitor capability at all, confirmed by searching its full source tree.
