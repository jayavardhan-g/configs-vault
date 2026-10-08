-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    -- Clear any Claude Code daemon left over from a PREVIOUS Hyprland session.
    --
    -- That daemon is long-lived and caches WAYLAND_DISPLAY from whatever session
    -- started it. When Hyprland restarts it comes up on a NEW socket, but a
    -- surviving daemon keeps pointing at the old one, so every clipboard read it
    -- makes fails and image paste silently stops working, with no error anywhere.
    --
    -- Measured 2026-09-21: the daemon started 12:03 holding
    -- WAYLAND_DISPLAY=wayland-0, Hyprland came up 12:07 on wayland-1, and
    -- /run/user/1000/wayland-0 no longer existed. Proof it was the cause:
    --   WAYLAND_DISPLAY=wayland-0 wl-paste --list-types
    --     -> Failed to connect to a Wayland server: No such file or directory
    --   WAYLAND_DISPLAY=wayland-1 wl-paste --list-types  -> image/png
    --
    -- Done at START rather than in the shutdown hook below, deliberately: a crash
    -- or a hard kill never runs a shutdown hook, and that is exactly the case that
    -- strands a daemon. At this point in a fresh session there is nothing worth
    -- keeping — any daemon still alive here already holds the wrong socket.
    hl.exec_cmd("pkill -f 'claude daemon' || true")

    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("gnome-keyring-daemon --start --components=pkcs11,secrets")
    hl.exec_cmd("noctalia")
    -- Quickshell, alongside Noctalia: hosts the pomodoro widget (SUPER+C).
    hl.exec_cmd("qs -d")
    -- Removed: hl.exec_cmd("xhost +SI:localuser:root") — CachyOS boilerplate
    -- that grants the local root account access to the X (XWayland) display, so
    -- that root GUI apps like `sudo gparted` don't fail with "cannot open
    -- display". xhost was never installed here, so the line failed silently at
    -- every login — proof it was never needed. Removing it only tightens access,
    -- never loosens it. If a root GUI app is ever needed, use pkexec instead.
    -- Hyprland doesn't run XDG autostart (/etc/xdg/autostart/*.desktop) on its
    -- own, so limine-snapper-sync's own "you booted a snapshot, restore now?"
    -- notification (normally launched that way) never fires. Launching it
    -- here is limine-snapper-sync's own documented workaround for WMs like
    -- this one; it no-ops immediately if the current boot isn't a snapshot.
    -- Waits for noctalia's own org.freedesktop.Notifications service (started
    -- by the "noctalia" exec_cmd just above, but not synchronously ready) —
    -- confirmed on a real snapshot boot that firing this immediately races
    -- noctalia's startup and the popup silently never appears.
    hl.exec_cmd(
        "bash -c 'for i in $(seq 1 30); do busctl --user list 2>/dev/null | grep -q org.freedesktop.Notifications && break; sleep 0.5; done; exec limine-snapper-restore --notify'"
    )
    -- Xpad is deliberately NOT auto-started any more — it's launched by hand,
    -- only when notes are actually wanted. scripts/xpad-launch.sh still exists
    -- and is still the only correct way to start it (it forces XWayland, which
    -- is what makes pad positions persist at all — see the script's own header),
    -- so the launcher entry at ~/.local/share/applications/xpad.desktop points
    -- at that script rather than at the bare `xpad` binary. That override
    -- shadows the system /usr/share/applications/xpad.desktop, whose plain
    -- `Exec=xpad` would start it as a native Wayland client and silently save
    -- every pad's position as x=0 y=0.
    --
    -- To restore auto-start, just uncomment the line below; nothing else here
    -- depends on it (the hotplug gate and the shutdown hook both no-op when
    -- Xpad isn't running).
    -- hl.exec_cmd("~/.config/hypr/scripts/xpad-launch.sh")

    -- XPAD_HOTPLUG_ARMED was removed here. It existed only to gate the
    -- xpad-note-translating monitor.added hook in windowrules.lua, which raced
    -- Xpad's startup at boot. That hook is gone — workspaces.lua now moves the
    -- whole workspace back to its monitor instead, which re-projects floating
    -- windows by itself and touches no window directly, so there is nothing
    -- left to race and nothing to arm.

    -- Auto-hidden apps: routed straight into the special workspace by matching
    -- window_rules in windowrules.lua (titles below must match those rules
    -- exactly). Launched sequentially — each one only after the previous
    -- window has actually mapped — rather than all at once, because Hyprland
    -- assigns master-layout master/stack-order to whichever window's surface
    -- maps *first*, not whichever hl.exec_cmd call fired first. Firing all
    -- four back-to-back races them against each app's own startup latency:
    -- confirmed on a real restart that claude (kitty -> fish -> the Claude
    -- CLI booting) lost that race and ended up in a stack slot instead of
    -- master. wait_then polls for a window (hl.get_windows) every 200ms and
    -- gives up after ~10s (falling through with a nil window rather than
    -- blocking the rest of the chain forever), so one unusually slow app
    -- can't stop the others from launching.
    --
    -- Toggle via AUTOSTART_HIDDEN_APPS in config/variables.lua; takes effect
    -- on the next full Hyprland restart (this hook doesn't rerun on a plain
    -- `hyprctl reload`).
    if AUTOSTART_HIDDEN_APPS then
    local function wait_then(filter, tries_left, fn)
        local w = hl.get_windows(filter)[1]
        if w or tries_left <= 0 then
            fn(w)
        else
            hl.timer(function() wait_then(filter, tries_left - 1, fn) end, { timeout = 200, type = "oneshot" })
        end
    end

    hl.exec_cmd("kitty --title special-claude --directory ~/claude -e fish -c claude")
    wait_then({ title = "special-claude" }, 50, function(claude)
        -- Force master explicitly too, as a safety net — cheap no-op if
        -- claude is already master (expected, since it should be the only
        -- window in the freshly-emptied special workspace at this point).
        if claude then
            hl.dispatch(hl.dsp.focus({ window = claude }))
            hl.dispatch(hl.dsp.layout("swapwithmaster"))
            hl.dispatch(hl.dsp.layout("mfact exact 0.45"))
        end

        hl.exec_cmd("flatpak run com.spotify.Client")
        wait_then({ class = "^(spotify)$" }, 50, function(spotify)
            hl.exec_cmd("kitty --title special-labvpn -e fish -c labvpn")
            wait_then({ title = "special-labvpn" }, 50, function(labvpn)
                hl.exec_cmd("kitty --title special-home")
                wait_then({ title = "special-home" }, 50, function(home)
                    -- spotify (biggest) > home (medium) > labvpn (smallest).
                    -- Master layout's stack is a nested split (spotify vs
                    -- {labvpn, home}, then labvpn vs home within that):
                    -- resizing the *top* stack window (spotify) rescales the
                    -- labvpn/home pair proportionally while preserving
                    -- whatever ratio they already had, but resizing a
                    -- *middle* window (labvpn) only moves its own boundary
                    -- with the window below it (home), leaving spotify
                    -- untouched. So order matters — set the labvpn/home
                    -- ratio first, then grow spotify (which shrinks both
                    -- proportionally without disturbing that ratio):
                    if labvpn then
                        hl.dispatch(hl.dsp.focus({ window = labvpn }))
                        hl.dispatch(hl.dsp.window.resize({ x = 0, y = -80, relative = true }))
                    end
                    if spotify then
                        hl.dispatch(hl.dsp.focus({ window = spotify }))
                        hl.dispatch(hl.dsp.window.resize({ x = 0, y = 150, relative = true }))
                    end
                end)
            end)
        end)
    end)
    end
end)

-- Xpad only writes each pad's position to disk on a clean quit — confirmed
-- live: killing it (SIGTERM/pkill) leaves every pad's saved position at
-- "x 0 y 0" no matter what, while `xpad --quit` (its own IPC shutdown
-- command) correctly saves the real coordinates. A logout/shutdown that just
-- kills the process would silently lose position every time, so ask it to
-- quit cleanly first, before whatever normally kills app processes on
-- session teardown gets to it.
hl.on("hyprland.shutdown", function ()
    hl.exec_cmd("xpad --quit")
end)
