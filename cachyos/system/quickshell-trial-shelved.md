# Quickshell: tried alongside Noctalia, shelved for later

**Date:** 2026-09-30
**Category:** system
**Files touched:** none live. The trial config lived in `~/.config/quickshell/` and was removed; saved copies are in [`quickshell-trial/`](quickshell-trial/) (`shell.qml`, `SideIsland.qml`). Deliberately kept out of `../files/`, which gets overlay-copied onto a fresh machine.

<!-- graph:begin -->
**Graph:** [[Noctalia]] · [[Quickshell]] · [[Xpad]]
<!-- graph:end -->

## What
Status (updated 2026-10-02): **Quickshell is installed and autostarted again**, for the
pomodoro widget ([quickshell-pomodoro-widget.md](quickshell-pomodoro-widget.md)). That
build replaced `~/.config/quickshell/shell.qml`. The trial bar and the left-edge side
island below are still **not** deployed; to add the island back, copy `SideIsland.qml`
in and add `SideIsland {}` to the current `shell.qml`.
Installed `quickshell` 0.3.1, ran a small trial next to Noctalia (a bottom bar plus a
left-edge hover "side island" with media controls and read-only xpad notes), then
removed the config and uninstalled the package. Noctalia stays the only shell.

## Why
Wanted the kind of custom widgets (dynamic islands etc.) seen in Quickshell setups on
Reddit. Noctalia can't do these fully: its Luau plugins add widgets inside Noctalia's
own bar and panels, and can't redraw its popups. Shelved for now, not rejected.

## Change
To pick it back up:
```bash
sudo pacman -S quickshell
mkdir -p ~/.config/quickshell
cp cachyos/system/quickshell-trial/{shell,SideIsland}.qml ~/.config/quickshell/
qs &                 # runs alongside Noctalia; nothing autostarts it
pkill -x qs          # stop
```
`shell.qml` holds the trial bottom bar and loads `SideIsland {}`. Delete the bar's
`Variants { … }` block to keep only the island.

What the island does: an invisible 2px hot edge on the **leftmost** monitor only; the
cursor has to rest there ~150 ms before a rounded card slides in (vertically centred).
It hides ~400 ms after the cursor leaves. It shows MPRIS media (cover art, title,
previous / play-pause / next for the playing player) and the text of every
`~/.config/xpad/content-*` note, re-read each time it opens.

## Notes
- **Noctalia 5 is no longer Quickshell-based.** It's a native C++ binary (no Qt deps),
  so installing Quickshell adds a separate toolkit; it doesn't unlock anything inside
  Noctalia.
- **Quickshell is a toolkit, Noctalia is a finished shell.** In Quickshell you write
  every widget yourself in QML (Qt's UI language) and maintain it. Middle ground if
  revisited: keep Noctalia and run only a custom island/panel from Quickshell next to it.
- **Hyprland's Lua config breaks Quickshell's plain dispatch strings.**
  `Hyprland.dispatch("workspace 2")` fails (`')' expected near '2'`), because Hyprland
  wraps the string in `hl.dispatch(...)`. Send Lua instead:
  `Hyprland.dispatch("hl.dsp.focus({ workspace = 2 })")`. This matches the SUPER+number
  binds in `binds.lua`.
- **Hot edge only on the leftmost screen.** The external monitor sits right of the
  laptop, so a left-edge trigger there would fire on every cross-monitor cursor move.
  The island picks the screen with the smallest `x`. The strip takes the leftmost 2px of
  clicks on that screen.
- **Notification conflict.** Only one process can own `org.freedesktop.Notifications`.
  While Noctalia runs, a Quickshell island can show media, volume, clock and workspaces,
  but not notifications.
- **Replacing Noctalia fully would keep every key combo.** 22 of 112 binds call
  `noctalia msg …`. 11 are hardware keys (volume, mic, media, brightness), best moved to
  `wpctl` / `playerctl` / `brightnessctl` so they don't depend on any shell. The other
  11 would become `qs ipc call <target> <fn>` (via an `IpcHandler` in QML). Also:
  `autostart.lua` (the `noctalia` exec and the notification-service wait) and the
  Noctalia float rule in `windowrules.lua`. Every panel Noctalia provides (launcher,
  clipboard, control centre, window switcher, wallpaper picker, session menu) would
  have to be rebuilt.
- **Cheaper alternative, not tried:** Noctalia community plugin `notoxus/media-island`
  (`noctalia msg plugins enable notoxus/media-island`). It's media-only; read its source
  before enabling.
- Edits to `SideIsland.qml` didn't hot-reload during the trial (only edits to
  `shell.qml` did). Restart `qs` after changing a component file.
