# Scrolling column resize (SUPER+U) un-maximizes first

**Date:** 2026-09-24
**Category:** window-management
**Files touched:** `~/.config/hypr/config/binds.lua` (copy at [`files/.config/hypr/config/binds.lua`](../files/.config/hypr/config/binds.lua))

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

## What
SUPER+U (`colresize +conf`) and SUPER+SHIFT+E (`colresize 0.95`) now drop the
focused window out of fullscreen/maximize before resizing its column.

## Why
On scrolling workspace 1, SUPER+U on Zen and VS Code resized sometimes and not
other times. A resized window also didn't keep its width: switching away hid it
completely, and switching back showed it maximized again. Both windows turned
out to be stuck at `fullscreen: 1` (SUPER+D maximize).

Reproduced on test windows on workspace 3:
- A normal column: `colresize +conf` works and the width **does** persist across
  focus changes and workspace switches. The layout itself is fine.
- A maximized column: `colresize` shrinks it on screen (1588 → 523px) but the
  window keeps `fullscreen = 1`. That half-state causes both symptoms: the next
  relayout snaps it back to full width, and focusing away and back moved it
  to x=1522 on the 1600px laptop, i.e. almost entirely off-screen.

`binds:movefocus_cycles_fullscreen = true` (misc.lua) makes this easy to hit,
because the maximize carries over as you move between windows. That option was
kept as-is: the fix is in the resize binds, not in the focus behaviour.

## Change
`~/.config/hypr/config/binds.lua`, replacing the two plain `hl.dsp.layout` binds:
```lua
local function colresize(arg)
	return function()
		local w = hl.get_active_window()
		if w and w.fullscreen ~= 0 then
			hl.dispatch(hl.dsp.window.fullscreen({ mode = w.fullscreen }))
		end
		hl.dispatch(hl.dsp.layout("colresize " .. arg))
	end
end
hl.bind(mainMod .. " + U", colresize("+conf"))
hl.bind(mainMod .. " + SHIFT + E", colresize("0.95"))
```
Hyprland auto-reloads on save; `hyprctl configerrors` was empty afterwards.

## Notes
- `HL.Window` is userdata, not a table, so you can't `pairs()` over it. The field
  is `w.fullscreen` (0/1/2). `fullscreen_client` also exists; `fullscreen_mode`
  does not.
- Passing the window's own mode to `window.fullscreen` toggles it off. This covers
  SUPER+D (mode 1) and SUPER+F (mode 2).
- Tested live: maximized window + new SUPER+U → 523 → 790 → 1057px, `fs:0` each
  time, and the width held through focus left/right and a ws1↔ws3 round trip.
- The key choice itself (SUPER+U, from the Mango days) is in
  [[scroller-proportion-preset-remap]].
