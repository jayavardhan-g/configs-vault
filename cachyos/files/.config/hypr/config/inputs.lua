-- Input configuration

hl.config({
    input = {
        -- sensitivity = -0.25,
        accel_profile = "flat",
	kb_layout = "us",
	kb_options = "caps:swapescape,altwin:swap_ralt_rwin",
	natural_scroll = false,
	touchpad = {
	    natural_scroll = true,
	},
    },

    -- Uncomment the section below to enable software cursors; this can help with cursor display or behavior issues
    -- cursor = {
    --     no_hardware_cursors = 1,
    -- },
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })

-- 3-finger left/right cycles focus through the windows on the current
-- workspace (same as ALT+Tab), the window-level counterpart of the 4-finger
-- workspace swipe. Left = next, right = previous, matching the 4-finger
-- direction sense. A function action fires once per swipe (no live tracking).
-- This replaced 3-finger left = float (removed 2026-11-12; float stays on
-- SUPER+SHIFT+F).
hl.gesture({ fingers = 3, direction = "left",  action = function() hl.dispatch(hl.dsp.window.cycle_next()) end })
hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.window.cycle_next({ next = false })) end })

-- 3-finger DOWN is intentionally left unbound. It used to be:
--     hl.gesture({ fingers = 3, direction = "down", action = "close" })
-- which closed the focused window outright — far too destructive for a gesture
-- that's easy to trigger by accident, and with no undo. Removed on purpose;
-- don't add it back.
