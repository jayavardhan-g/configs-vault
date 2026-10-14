-- replace uosc's "Drop files or URLs to play here" idle screen with the file browser;
-- it starts in the NAS media folder (uosc.conf), or ~/Videos when the NAS isn't reachable
local nas = '/mnt/nas/media'

local function show_browser()
	mp.commandv('script-message-to', 'uosc', 'disable-elements', mp.get_script_name(), 'idle_indicator')
	if mp.get_property_bool('idle-active') then
		mp.commandv('script-binding', 'uosc/open-file')
	end
end

mp.add_timeout(1, function()
	-- touching /mnt/nas triggers the automount, so check off the main thread with a timeout
	mp.command_native_async({
		name = 'subprocess', playback_only = false, capture_stdout = true,
		args = {'timeout', '5', 'test', '-d', nas},
	}, function(_, res)
		if not res or res.status ~= 0 then
			local opts = mp.get_property_native('options/script-opts', {})
			opts['uosc-default_directory'] = '~/Videos'
			mp.set_property_native('options/script-opts', opts)
		end
		mp.add_timeout(0.2, show_browser)
	end)
end)
