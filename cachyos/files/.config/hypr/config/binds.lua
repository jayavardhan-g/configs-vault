local mainMod = "SUPER"
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")
local HOME = os.getenv("HOME")

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation
-- Force-kill picker: the cursor becomes a crosshair, then you click the window
-- to kill. Escape cancels the mode.
--
-- It CANNOT be bound to any chord containing Escape, which is what SUPER+Escape
-- used to be. Escape is kill mode's own cancel key, and the check runs on key
-- RELEASE as well as press (KeybindManager.cpp, handleInternalKeybinds):
--
--     if (g_pInputManager->getClickMode() == CLICKMODE_KILL) {
--         if (keysym == XKB_KEY_Escape) {
--             g_pInputManager->setClickMode(CLICKMODE_DEFAULT);
--
-- exec_cmd is async, so the sequence was: press fires the bind -> hyprctl kill
-- turns kill mode on a few ms later -> the release of that same Escape key
-- cancels it immediately. The crosshair appeared and vanished in one press.
--
-- SUPER+ALT+Q pairs with SUPER+Q (close window): same letter, more force. The
-- extra modifier is deliberate - this kills without asking the app to save.
hl.bind(mainMod .. " + ALT + Q", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D", hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

-- Fake fullscreen, ported from Mango's SUPER+ALT+F (togglefakefullscreen):
-- tell the application it is fullscreen without actually making it so, which
-- gets a video player or game to switch to its fullscreen UI while the window
-- stays a normal tile. internal = 0 keeps Hyprland's own state unchanged;
-- client = 2 is the fullscreen state reported to the app.
--
-- action = "toggle" is REQUIRED, not optional: without it the dispatcher only
-- ever sets the state, so repeated presses leave fullscreen_client pinned at 2
-- with no way to clear it (verified — three presses in a row all read
-- fsClient=2, and only the toggle form brought it back to 0).
--
-- Two things that make this look broken when it isn't:
--   * It needs the LEFT Alt key. kb_options has altwin:swap_ralt_rwin, so Right
--     Alt sends Super and this chord collapses to plain SUPER+F.
--   * It changes no geometry at all — the window keeps its exact size. Apps
--     that don't re-render when told they're fullscreen (terminals, file
--     managers) show no visible change whatsoever. Test it on mpv or a video.
hl.bind(mainMod .. " + ALT + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 2, action = "toggle" }))

-- Show the focused window on every workspace, ported from Mango's SUPER+G
-- (toggleglobal). Hyprland's pin is the equivalent and is a toggle.
-- Caveat: pin only applies to FLOATING windows — on a tiled window it's a
-- no-op, so pair it with SUPER+SHIFT+F if the window isn't floating yet.
hl.bind(mainMod .. " + G", hl.dsp.window.pin())

-- Nudge a floating window by 50px, ported from Mango's CTRL+SHIFT+arrows
-- (movewin +/-50).
--
-- Deliberately NOT on bare CTRL+SHIFT+arrows like Mango had it: that chord is
-- word-selection in terminals, browsers and editors, and a global bind would
-- swallow it everywhere — the same reason bare middle-click was freed from
-- togglemaximizescreen.
--
-- Also deliberately NOT on bare CTRL+ALT+hjkl (which this briefly used): the
-- same swallowing problem in weaker form (CTRL+ALT+Left/Right is back/forward
-- in JetBrains IDEs, workspace switching in GNOME/KDE), plus it breaks the
-- SUPER-is-the-base-modifier convention every other bind here follows. Super
-- is grabbed by the compositor, so SUPER+... can never collide with an app.
--
-- Fingering note: kb_options has altwin:swap_ralt_rwin, so Right Alt sends
-- Super — press these as Right Alt (Super) + LEFT Alt + hjkl. Two thumbs,
-- same as SUPER+ALT+F.
--
-- Tiled windows ignore this (they're positioned by the layout); use
-- SUPER+SHIFT+hjkl to move those within the layout instead.
hl.bind(mainMod .. " + ALT + h", hl.dsp.window.move({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + l", hl.dsp.window.move({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + k", hl.dsp.window.move({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + j", hl.dsp.window.move({ x = 0, y = 50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + Left", hl.dsp.window.move({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + Right", hl.dsp.window.move({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + Up", hl.dsp.window.move({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + Down", hl.dsp.window.move({ x = 0, y = 50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CONTROL + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + M", hl.dsp.layout("swapwithmaster"))

-- Cycle the CURRENT WORKSPACE's layout, remembering the choice across restarts.
-- Matches Mango's SUPER+N (circle_layout + switch-layout-persist.sh).
--
-- The implementation lives in config/workspaces.lua, next to the workspace
-- rules it mutates. It's called through a closure rather than passed directly
-- because hyprland.lua requires THIS file before workspaces.lua — at load time
-- WS_CYCLE_LAYOUT doesn't exist yet, but by the time a key is pressed it does.
--
-- Replaces an earlier version that cycled the global general:layout (changing
-- every workspace at once) and forgot the choice on restart.
hl.bind(mainMod .. " + N", function()
	WS_CYCLE_LAYOUT()
end)

-- Reload the config, matching Mango's SUPER+F5 (reload_config). There's no
-- reload dispatcher in Hyprland's Lua API, so this shells out to hyprctl.
--
-- Largely a convenience: misc:disable_autoreload is off, so Hyprland already
-- reloads whenever a config file is saved. This forces one WITHOUT touching a
-- file — e.g. to discard runtime-only changes made through hyprctl eval, or to
-- re-read the persisted workspace-layout state file after editing it by hand.
hl.bind(mainMod .. " + F5", hl.dsp.exec_cmd("hyprctl reload"))

-- Scrolling-layout column width, matching Mango's SUPER+U
-- (switch_proportion_preset) and SUPER+SHIFT+E (set_proportion 1.0).
--
-- Both are native layoutmsgs — no glue needed:
--   colresize +conf  steps to the next width in scrolling:explicit_column_widths
--                    and wraps at the end
--   colresize 0.95   sets the focused column to an absolute proportion of the
--                    monitor. Any float works (0.5, 0.8, ...)
--
-- 0.95 rather than 1.0 reproduces Mango's scroller_structs = 40: the column
-- stops just short of the screen edges and the layout centres it, so the
-- columns either side stay visible as a thin strip and you can tell there's
-- more to scroll to. Measured symmetric peek per side, confirming it centres:
--   0.85 -> 144px   0.90 -> 96px   0.95 -> 48px   1.00 -> 0px   (on 1920 logical)
-- On the 1600-logical laptop 0.95 works out to exactly 40px a side — the same
-- number Mango used. Drop to 0.90 if the strip is too thin to notice.
--
-- For genuinely full width there's already SUPER+D (window.fullscreen mode 1),
-- which is the equivalent of Mango's togglemaximizescreen.
--
-- The preset list is Hyprland's default, 0.333 / 0.5 / 0.667 / 1.0 — four stops
-- rather than Mango's three (0.5 / 0.8 / 1.0). Verified live on eDP-1 (1600px
-- logical): the cycle produced 525 -> 791 -> 1057 -> 1588 px. To match Mango
-- exactly instead, set scrolling.explicit_column_widths = "0.5, 0.8, 1.0".
--
-- These are harmless on master/dwindle workspaces: a layout that doesn't
-- understand the message just ignores it, so the keys simply do nothing there.
--
-- Both drop fullscreen/maximize (SUPER+D / SUPER+F) before resizing. A bare
-- colresize on a maximized window leaves it in a broken half-state, reproduced
-- live on 2026-09-24: the column shrinks on screen but the window keeps
-- fullscreen = 1, so the next relayout snaps it back to full width ("forgets"
-- the resize), and a focus-away-and-back throws it off-screen (x=1522 on the
-- 1600px laptop). binds:movefocus_cycles_fullscreen (misc.lua) makes this easy
-- to hit, since maximize carries over as you move between windows. A
-- non-maximized column keeps its width across focus and workspace switches.
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

-- Change focus.
--
-- Left/right cross to the neighbouring monitor at the screen edge (added
-- 2026-09-26, see [[monitor-gap-blocks-directional-focus]] in the configs repo).
-- Hyprland's own binds:window_direction_monitor_fallback can't do this: the
-- dead zone in monitors.lua is far wider than its 2px adjacency threshold, and
-- with it on, it matched scrolled-off columns on the other monitor instead, so
-- it's disabled in misc.lua. That's also what makes this helper possible. With
-- the fallback off, focus at the edge STAYS PUT instead of wrapping (the
-- blocker for the 2026-09-21 attempt), so "focused window didn't change" now
-- reliably means "at the edge".
--
-- On the far monitor it picks the nearest window actually on screen (leftmost
-- when going right, rightmost when going left), or the on-screen fullscreen
-- window if there is one. Scrolled-off columns are skipped, so crossing never
-- changes what that monitor shows. Known gap: if the scratchpad is open on the
-- far monitor, the window underneath is picked, since the Lua API doesn't say
-- whether a special workspace is shown.
local function focus_across(dir)
	return function()
		local before = hl.get_active_window()
		hl.dispatch(hl.dsp.focus({ direction = dir }))
		local after = hl.get_active_window()
		if before and after and before.address ~= after.address then return end

		local cur
		for _, m in ipairs(hl.get_monitors()) do
			if (before and m.name == before.monitor.name) or (not before and m.focused) then cur = m end
		end
		if not cur then return end

		local target
		for _, m in ipairs(hl.get_monitors()) do
			if dir == "right" and m.x > cur.x and (not target or m.x < target.x) then target = m end
			if dir == "left" and m.x < cur.x and (not target or m.x > target.x) then target = m end
		end
		if not target then return end

		-- monitor x/width are physical px; window coordinates are logical
		local x0, x1 = target.x, target.x + target.width / target.scale
		local pick
		for _, w in ipairs(hl.get_windows({})) do
			if w.workspace and w.workspace.id == target.active_workspace.id and w.mapped and not w.hidden then
				local wx0, wx1 = w.at.x, w.at.x + w.size.x
				if wx1 > x0 and wx0 < x1 then
					if w.fullscreen ~= 0 then
						pick = w
						break
					end
					if not pick
						or (dir == "right" and wx0 < pick.at.x)
						or (dir == "left" and wx1 > pick.at.x + pick.size.x) then
						pick = w
					end
				end
			end
		end

		if pick then
			hl.dispatch(hl.dsp.focus({ window = pick }))
		else
			hl.dispatch(hl.dsp.focus({ monitor = target.name }))
		end
	end
end
hl.bind(mainMod .. " + Left", focus_across("left"))
hl.bind(mainMod .. " + Right", focus_across("right"))
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "down" }))
-- vim-style focus movement
hl.bind(mainMod .. " + H", focus_across("left"))
hl.bind(mainMod .. " + L", focus_across("right"))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd(shell_cmd("window-switcher")))

-- Move active window around workspaces & monitors
hl.bind(mainMod .. " + SHIFT + Up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + Left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + Down", hl.dsp.window.move({ direction = "d" }))
-- vim-style window movement
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + mouse_up", hl.dsp.window.move({ monitor = "-1" }))
hl.bind(mainMod .. " + SHIFT + mouse_down", hl.dsp.window.move({ monitor = "+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + Right", hl.dsp.window.move({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + Left", hl.dsp.window.move({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "m+1" }))
for i = 1, NUM_WPM do
	local key = i % 10
	hl.bind(mainMod .. " + SHIFT + CONTROL + " .. key, hl.dsp.window.move({ workspace = "m~" .. i }))
end

-- Move & Resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- vim-style resize submap: SUPER+R to enter, hjkl to resize as many times as
-- you like, Esc/Enter/SUPER+R to leave. The mode is sticky - it stays until
-- you explicitly exit it.
--
-- The second argument to hl.define_submap is NOT a formality: it sets the
-- submap's `reset` field, and Hyprland reads that as "the submap to jump to
-- after any non-submap bind in here fires", i.e. it makes the whole submap
-- ONE-SHOT. Passing "reset" (as this used to) is what made the first h/j/k/l
-- press resize once and then drop straight back to default. KeybindManager,
-- right after running a bind's dispatcher:
--
--     if (k->handler != "submap" && !k->submap.reset.empty()) {
--         auto submapAfter = Config::Actions::state()->m_currentSubmap;
--         if (submapBefore == submapAfter)
--             Config::Actions::setSubmap(k->submap.reset);
--     }
--
-- Note what that implies about the previous attempted workaround (a handler
-- that re-dispatched `submap resize` after each resize): it can't work. The
-- check compares the submap name before and after the dispatch, so
-- re-asserting the SAME name leaves them equal and the auto-reset fires
-- anyway. Omitting the reset argument entirely is the actual fix - with
-- submap.reset empty the branch never runs.
--
-- Also verified, contrary to the old comment here: window.resize does not
-- drop the submap on its own. Dispatching it by hand from hyprctl while in
-- the submap leaves `hyprctl submap` reading "resize" across repeated calls.
hl.define_submap("resize", function()
	hl.bind("H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
	hl.bind("L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
	hl.bind("K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
	hl.bind("J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })
	hl.bind("escape", hl.dsp.submap("reset"))
	-- kb_options has caps:swapescape, so the physical Esc key emits Caps_Lock
	-- and only the CapsLock-position key emits Escape. Bind both so whichever
	-- key you reach for actually leaves the mode.
	hl.bind("Caps_Lock", hl.dsp.submap("reset"))
	hl.bind("Return", hl.dsp.submap("reset"))
	hl.bind(mainMod .. " + R", hl.dsp.submap("reset"))
end)
hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))

-- SUPER+CONTROL+SHIFT+hjkl used to be a second, submap-free way to resize in
-- 40px steps. It only existed because the submap above was accidentally
-- one-shot and therefore useless for more than a single nudge. Now that the
-- submap is sticky, a three-modifier chord for the same job isn't worth the
-- finger contortion, so it's gone. SUPER+CONTROL+SHIFT+hjkl is free again -
-- note the Left/Right members of that same chord family are still live above
-- as move-window-to-ADJACENT-WORKSPACE (m-1/m+1), not move-to-monitor.
-- Moving a window between monitors is SUPER+SHIFT+bracketleft/bracketright.

-- Reset the focused window's size back to its default tiled share, and
-- reset the master/stack ratio back to Hyprland's default (0.55)
local function reset_window_size()
	hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
	hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
	hl.dispatch(hl.dsp.layout("mfact exact 0.55"))
end
hl.bind(mainMod .. " + SHIFT + R", reset_window_size)

-- Zoom
local function zoomfunction(value)
	local zoomvalue = hl.get_config("cursor:zoom_factor")
	if (zoomvalue + value) > 3.0 then
		hl.config({ cursor = { zoom_factor = 3.0 } })
	elseif (zoomvalue + value) < 1.0 then
		hl.config({ cursor = { zoom_factor = 1.0 } })
	else
		hl.config({ cursor = { zoom_factor = zoomvalue + value } })
	end
end
hl.bind(mainMod .. " + Minus", function()
	zoomfunction(-0.3)
end, { repeating = true })
hl.bind(mainMod .. " + Plus", function()
	zoomfunction(0.3)
end, { repeating = true })

--# Zoom with keypad
hl.bind(mainMod .. " + code:82", function()
	zoomfunction(-0.3)
end, { repeating = true })
hl.bind(mainMod .. " + code:86", function()
	zoomfunction(0.3)
end, { repeating = true })

------------------
---- LAUNCHER ----
------------------

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(launchPrefix .. TERMINAL))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(launchPrefix .. FILE_MANAGER))
-- EDITOR is a terminal program (nvim), so it needs TERMINAL to draw in - same
-- shape as the btop bind below. Previously this was `launchPrefix .. EDITOR`,
-- which handed the bare command to uwsm with no terminal: nvim started, had
-- nowhere to render, and exited immediately, so the bind did nothing visible.
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e " .. EDITOR))
-- SUPER+C ("clock") toggles the Quickshell pomodoro panel (~/.config/quickshell/).
-- It used to open the calculator, which is rarely used and stays on its own
-- XF86Calculator key below. qs is autostarted (autostart.lua); if it isn't
-- running, the bind starts it and retries once.
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("sh -c 'qs ipc call pomodoro toggle || { qs -d && sleep 1 && qs ipc call pomodoro toggle; }'"))
hl.bind("XF86Calculator", hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
-- Browser is on B only. SUPER+W used to be a second browser bind; W now means
-- Wallpaper (moved here from SUPER+SHIFT+W), which is the more obvious mnemonic
-- and costs nothing since B already covers the browser.
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(launchPrefix .. BROWSER))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(shell_cmd("panel-toggle wallpaper")))
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e btop"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(shell_cmd("settings-toggle")))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(shell_cmd("panel-toggle control-center")))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(shell_cmd("panel-toggle launcher")))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd(shell_cmd("panel-toggle launcher /emo")))
-- There is deliberately NO dedicated lock bind. Lock is reached through the
-- session panel on SUPER+SHIFT+Q, which is now the single way in.
--
-- History, so this doesn't get "helpfully" re-added: lock lived on SUPER+L,
-- then SUPER+CTRL+L, then SUPER+ALT+L, then briefly SUPER+ALT+X. It can't go
-- back to the Windows-style SUPER+L, because that's vim focus-right and
-- Hyprland runs EVERY matching bind rather than letting a later one override —
-- SUPER+L would focus right AND lock on the same press. SUPER+ALT+X was worse
-- than it looked: Right Alt sends Super, so the ALT has to be the LEFT Alt, and
-- X is a left-hand key too, making it a cramped same-hand claw (the same reason
-- ALT+X was abandoned for the scroller preset bind).
-- Removed: SUPER+ALT+C, a second bind for the same session panel already on
-- SUPER+SHIFT+Q. One way in is enough. SUPER+ALT+C is free.
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(shell_cmd("panel-toggle session")))
-- Power button opens the same session menu instead of powering off at once (an
-- accidental press shut the laptop down). Needs logind to leave the key alone:
-- HandlePowerKey=ignore in /etc/systemd/logind.conf.d/power-key.conf. A long hold
-- still forces the machine off in hardware.
hl.bind("XF86PowerOff", hl.dsp.exec_cmd(shell_cmd("panel-toggle session")))
hl.bind(
	mainMod .. " + P",
	hl.dsp.exec_cmd(launchPrefix .. os.getenv("HOME") .. "/.config/hypr/scripts/display-mode.sh")
)

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(shell_cmd("volume-up")), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(shell_cmd("volume-down")), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(shell_cmd("volume-mute")), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(shell_cmd("mic-mute")), { locked = true })

-- Media
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(shell_cmd("media toggle")), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(shell_cmd("media toggle")), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(shell_cmd("media next")), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(shell_cmd("media previous")), { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(shell_cmd("brightness-up")), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(shell_cmd("brightness-down")), { locked = true, repeating = true })

-------------------
---- UTILITIES ----
-------------------

-- Screen Capture
-- SUPER+SHIFT+P used to run `hyprpicker -a -n` (a Wayland colour picker), but
-- hyprpicker was never installed, so the bind had always been dead. Removed
-- rather than installing it - no need for a colour picker here.
-- SUPER+SHIFT+P is now free.
hl.bind("Print", hl.dsp.exec_cmd(shell_cmd("screenshot-fullscreen")))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(shell_cmd("screenshot-region")))
hl.bind("F6", hl.dsp.exec_cmd(shell_cmd("screenshot-region")))

-- Theming and Wallpaper
-- The wallpaper picker moved to plain SUPER+W (see the LAUNCHER section) once
-- W was freed up by dropping the duplicate browser bind. SUPER+SHIFT+W is free.

-- Toggle laptop panel refresh rate between 144Hz and 60Hz
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/refresh-rate.sh toggle"))

-- Clipboard
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(shell_cmd("panel-toggle clipboard")))

-- Notifications
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(shell_cmd("panel-toggle control-center notifications")))

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Focus/move to monitor (bracketleft = eDP-1 laptop, bracketright = HDMI-A-1
-- external, matching the physical left-right arrangement)
hl.bind(mainMod .. " + bracketleft", hl.dsp.focus({ monitor = MONITOR1 }))
hl.bind(mainMod .. " + bracketright", hl.dsp.focus({ monitor = MONITOR2 }))
hl.bind(mainMod .. " + SHIFT + bracketleft", hl.dsp.window.move({ monitor = MONITOR1 }))
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ monitor = MONITOR2 }))

-- Focus on workspace number
-- Absolute (NUM_WPM per monitor; MONITOR1 and MONITOR2 are both in use, so cover both ranges)
for i = 1, NUM_WPM * 2 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
end
-- Move active window to a workspace number (absolute, same numbering as above)
for i = 1, NUM_WPM * 2 do
	local key = i % 10
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end
-- Relative
for i = 1, NUM_WPM do
	local key = i % 10
	hl.bind(mainMod .. " + CONTROL + " .. key, hl.dsp.focus({ workspace = "m~" .. i }))
end

-- Extra workspace 7 (Xpad notes), outside the NUM_WPM*2 grid above. Needs both
-- halves spelled out by hand: the loops above only cover 1..NUM_WPM*2, so
-- without the SHIFT line workspace 7 would be the one workspace you could jump
-- to but couldn't send a window to.
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = "7" }))

-- Move to adjacent workspaces and next empty on a given monitor
hl.bind(mainMod .. " + CONTROL + Right", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + Left", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + Down", hl.dsp.focus({ workspace = "emptym" }))
hl.bind(mainMod .. " + CONTROL + H", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + L", hl.dsp.focus({ workspace = "m+1" }))

-- Scroll through existing workspaces & monitors
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + mouse_up", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.focus({ workspace = "m+1" }))

-- Special workspace (scratchpad)
-- SHIFT+S sends the focused window to special, or pulls it back to its monitor's
-- current normal workspace if it's already sitting in special.
local function toggle_window_special()
	local win = hl.get_active_window()
	if not win or not win.workspace then
		return
	end
	if win.workspace.special then
		local target = win.monitor and win.monitor.active_workspace
		if target then
			hl.dispatch(hl.dsp.window.move({ workspace = target.id }))
		end
	else
		hl.dispatch(hl.dsp.window.move({ workspace = "special" }))
	end
end
hl.bind(mainMod .. " + SHIFT + S", toggle_window_special)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special())
