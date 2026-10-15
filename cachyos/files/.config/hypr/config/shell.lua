-- Which desktop shell this Hyprland session runs.
--
--   "noctalia"  the daily shell (default)
--   "dms"       DankMaterialShell, on trial against Noctalia (vault: cachyos/system/dms-trial.md)
--
-- To switch: change the word below, save, then log out and back in (the shell is
-- started from autostart.lua, which only runs on hyprland.start). Binds pick up the
-- change immediately on save.
-- SHELL_NAME = "noctalia"
SHELL_NAME = "dms"

-- Binds are written in Noctalia's `noctalia msg` vocabulary; shell_cmd() returns that
-- command unchanged for Noctalia, or the DMS equivalent from this table.
local DMS = {
	["window-switcher"] = "dms ipc call launcher openQuery '!'", -- dankHyprlandWindows plugin
	["panel-toggle wallpaper"] = "dms ipc call dankdash wallpaper",
	["settings-toggle"] = "dms ipc call settings toggle",
	["panel-toggle control-center"] = "dms ipc call control-center toggle",
	["panel-toggle launcher"] = "dms ipc call launcher toggle",
	["panel-toggle launcher /emo"] = "dms ipc call launcher openQuery ':e '", -- emojiLauncher plugin
	["panel-toggle session"] = "dms ipc call powermenu toggle",
	["volume-up"] = "dms ipc call audio increment 5",
	["volume-down"] = "dms ipc call audio decrement 5",
	["volume-mute"] = "dms ipc call audio mute",
	["mic-mute"] = "dms ipc call audio micmute",
	["media toggle"] = "dms ipc call mpris playPause",
	["media next"] = "dms ipc call mpris next",
	["media previous"] = "dms ipc call mpris previous",
	["brightness-up"] = "dms ipc call brightness increment 5 ''",
	["brightness-down"] = "dms ipc call brightness decrement 5 ''",
	-- Noctalia pipes screenshots to satty without saving or copying; same here.
	["screenshot-fullscreen"] = "dms screenshot full --stdout --no-file --no-clipboard --no-notify | satty -f -",
	["screenshot-region"] = "dms screenshot region --stdout --no-file --no-clipboard --no-notify | satty -f -",
	["panel-toggle clipboard"] = "dms ipc call clipboard toggle",
	["panel-toggle control-center notifications"] = "dms ipc call notifications toggle",
}

function shell_cmd(noctalia_args)
	if SHELL_NAME == "dms" then
		return DMS[noctalia_args] or ("notify-send 'shell.lua' 'No DMS mapping for: " .. noctalia_args .. "'")
	end
	return "noctalia msg " .. noctalia_args
end

-- The command autostart.lua runs to start the shell itself.
SHELL_START = (SHELL_NAME == "dms") and "dms run" or "noctalia"
