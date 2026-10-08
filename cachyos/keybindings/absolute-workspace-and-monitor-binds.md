# Bare SUPER+num for workspaces, SUPER+bracket for monitors

**Date:** 2026-09-14
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Monitors]] · [[Xpad]]
<!-- graph:end -->

## What
- `SUPER+1..6` — focus that workspace by absolute number (workspaces 1-3 live on the
  laptop screen, 4-6 on the external monitor; `SUPER+7` still focuses the Xpad workspace).
- `SUPER+SHIFT+1..6` — move the focused window to that workspace by absolute number (new;
  no absolute move-to-workspace bind existed before, only the relative `m~N` one under
  `SUPER+CTRL+SHIFT+num`).
- `SUPER+bracketleft` / `SUPER+bracketright` — focus the laptop (`eDP-1`) / external
  (`HDMI-A-1`) monitor.
- `SUPER+SHIFT+bracketleft` / `SUPER+SHIFT+bracketright` — move the focused window to the
  laptop / external monitor.

## Why
Brought over to match the number-key scheme worked out on the MangoWM trial config
(`SUPER+num` = switch workspace, `SUPER+SHIFT+num` = send window to workspace) so the two
compositors share the same muscle memory. Freed `SUPER+1/2/3` from monitor-focus duty
(their previous job) to take over workspace switching, and relocated monitor-focus to the
bracket keys instead — same idea as Mango's own bracket-key monitor binds, which land on
the physical left-right arrangement of the two monitors.

## Change
```lua
-- Focus/move to monitor (bracketleft = eDP-1 laptop, bracketright = HDMI-A-1
-- external, matching the physical left-right arrangement)
hl.bind(mainMod .. " + bracketleft",  hl.dsp.focus({ monitor = MONITOR1 }))
hl.bind(mainMod .. " + bracketright", hl.dsp.focus({ monitor = MONITOR2 }))
hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ monitor = MONITOR1 }))
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ monitor = MONITOR2 }))

-- Focus on workspace number (absolute; NUM_WPM per monitor, both monitors in use)
for i = 1, NUM_WPM * 2 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
end
-- Move active window to a workspace number (absolute, same numbering as above)
for i = 1, NUM_WPM * 2 do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Extra workspace 7 (Xpad notes), outside the NUM_WPM*2 grid above
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
```

## Notes
- **Superseded:** previously (undocumented, just the setup-template default)
  `SUPER+1/2/3` focused `MONITOR1`/`MONITOR2`/`MONITOR3` and `SUPER+SHIFT+1/2/3` moved the
  window to that monitor, while absolute workspace focus lived on `SUPER+ALT+num`. The
  `MONITOR3` bind was dropped entirely when moving to brackets — `variables.lua`'s
  `MONITOR3 = ""` is unset/unused, so that bind was already a no-op.
- The relative binds are untouched: `SUPER+CTRL+num` (focus `m~N`), `SUPER+CTRL+SHIFT+num`
  (move to `m~N`), and `SUPER+CTRL+Left/Right`/`SUPER+CTRL+H/L` (adjacent workspace, see
  [[workspace-switching]]) still work exactly as before.
