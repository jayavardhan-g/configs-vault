# Xpad notes pinned to a monitor-aware workspace 7

**Date:** 2026-09-12
**Category:** window-management
**Files touched:** `~/.config/hypr/config/workspaces.lua`, `~/.config/hypr/config/windowrules.lua`, `~/.config/hypr/config/binds.lua`, `~/.config/hypr/config/autostart.lua`, `~/.config/hypr/scripts/xpad-launch.sh`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Monitors]] · [[Xpad]]
<!-- graph:end -->

## What
[[xpad-sticky-notes]] (installed separately — see that entry for the app itself) is
wired into Hyprland as workspace 7: a dedicated workspace for sticky notes that lives on
the external monitor (`MONITOR2`/HDMI-A-1) when connected, and automatically falls back
to the laptop screen (`MONITOR1`/eDP-1) when it isn't — same mechanism workspaces 4-6
already use. Notes float freely (arranged like a corkboard, not tiled) and stay put
across reboots and monitor connect/disconnect cycles. `SUPER+7` jumps to it and
`SUPER+SHIFT+7` sends the focused window there (the latter was missing until
2026-09-21 — see [[dead-bind-cleanup]]).

## Why
User wants notes to "stay on a workspace and survive reboot," specifically following
whichever monitor is currently the external one rather than being fixed to a single
physical screen.

## Change

`~/.config/hypr/config/workspaces.lua` — added:
```lua
-- Extra workspace for Xpad notes. Bound to MONITOR2 (external): lives on the
-- external monitor when connected, and Hyprland's default monitor-removal
-- fallback merges it onto MONITOR1 (laptop) when MONITOR2 isn't present, the
-- same mechanism workspaces 4-6 already rely on.
hl.workspace_rule({ workspace = "7", monitor = MONITOR2, default = true, persistent = true })
```

`~/.config/hypr/config/binds.lua` — added (outside the existing `NUM_WPM*2` loop, which
only covers workspaces 1-6):
```lua
-- Extra workspace 7 (Xpad notes), outside the NUM_WPM*2 grid above
hl.bind(mainMod .. " + ALT + 7", hl.dsp.focus({ workspace = 7 }))
```

`~/.config/hypr/config/windowrules.lua` — added two rules/hooks:
```lua
-- Xpad notes: pinned to workspace 7 so they always open in the same place
-- instead of wherever focus happens to be. Floating rather than tiled since
-- workspace 7 holds nothing else to tile against, and notes are meant to be
-- arranged freely at their own size like a corkboard. center = false
-- explicitly overrides the generic "float=true -> center=true" rule above,
-- which every Xpad note also matches (it's floating too) — without this
-- override every note snaps to the same centered spot on open, which is
-- what was actually causing them to stack on top of each other, independent
-- of any position-persistence issue.
hl.window_rule({ match = { class = "^(xpad)$" }, workspace = "7", float = true, center = false })

-- Floating windows keep their absolute global-space position; that position
-- doesn't get re-projected when their workspace's monitor is reassigned. So
-- when workspace 7 was carried on MONITOR1 (because MONITOR2 was absent at
-- boot) and MONITOR2 then connects, the notes' stale coordinates can still
-- land inside MONITOR1's region even though Hyprland now reports them as
-- being on MONITOR2 — they render on the laptop, on top of whatever's there,
-- while MONITOR2 shows an empty workspace 7. The fix used to re-center each
-- misplaced note (hl.dsp.window.center()), which does move it onto the
-- right monitor but collapses every note to the same centered point —
-- confirmed live, that's what was causing them to overlap specifically on
-- reconnect. Translating by the offset between the two monitors' x instead
-- preserves each note's position relative to the others. Gated on
-- XPAD_HOTPLUG_ARMED (set in autostart.lua) so this only runs for a real
-- post-boot reconnect, not for monitor.added firing during Hyprland's own
-- startup — which would otherwise race Xpad restoring its notes' saved
-- positions and wrongly "fix" them.
hl.on("monitor.added", function()
    if not XPAD_HOTPLUG_ARMED then return end
    hl.timer(function()
        local target, source = nil, nil
        for _, m in ipairs(hl.get_monitors()) do
            if m.name == MONITOR2 then target = m end
            if m.name == MONITOR1 then source = m end
        end
        if not target or not source then return end
        local dx = target.x - source.x

        for _, w in ipairs(hl.get_windows({})) do
            if w.class == "xpad" and w.at.x < target.x then
                hl.dispatch(hl.dsp.focus({ window = w }))
                hl.dispatch(hl.dsp.window.move({ x = dx, y = 0, relative = true }))
            end
        end
    end, { timeout = 1000, type = "oneshot" })
end)
```

`~/.config/hypr/config/autostart.lua` — inside the existing `hl.on("hyprland.start", ...)`
block, added:
```lua
    -- See scripts/xpad-launch.sh: forces XWayland (needed for Xpad to
    -- actually persist pad positions) and cleans up its occasional spurious
    -- blank pad on login.
    hl.exec_cmd("~/.config/hypr/scripts/xpad-launch.sh")

    -- Xpad notes are floating and keep an absolute global-space position
    -- that doesn't get re-projected when their workspace moves monitors (see
    -- windowrules.lua's monitor.added hook, which repairs that after a real
    -- runtime hotplug). But monitor.added also fires for monitors that are
    -- already connected at this initial boot, and running the same repair
    -- then races Xpad's own startup — it can catch each note's window before
    -- Xpad has applied its saved x/y, "fixing" a note that was never
    -- actually broken by force-centering it. XPAD_HOTPLUG_ARMED gates the
    -- repair out until boot has had time to settle, so it only ever runs for
    -- genuine post-boot reconnects.
    XPAD_HOTPLUG_ARMED = false
    hl.timer(function() XPAD_HOTPLUG_ARMED = true end, { timeout = 8000, type = "oneshot" })
```
and, at the top level (outside the `hyprland.start` block, since it needs its own hook):
```lua
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
```

`~/.config/hypr/scripts/xpad-launch.sh` (new, `chmod +x`):
```bash
#!/usr/bin/env bash
# Launch Xpad under XWayland, and guard against its spurious extra blank pad.
#
# GDK_BACKEND=x11: Xpad saves each pad's position by querying its own window
# geometry, which native Wayland clients cannot do (Wayland deliberately
# doesn't let a client know its absolute screen position) — confirmed live,
# every pad's saved info file showed "x 0 y 0" under native Wayland. Under
# XWayland the same app correctly saved and restored real coordinates. This
# is the only way pads land back where you left them.
#
# Xpad's own --no-new flag ("don't create a pad if none exist") reliably
# prevents a blank pad in an isolated manual launch, but at real login it's
# racing dbus/gsettings/session startup and intermittently still creates one
# anyway (reproduced live: a single process, launched with --no-new, still
# opened an unwanted blank pad — cause not pinned down, but confirmed
# independent of the once-duplicated autostart entry). Rather than chase that
# race further, this closes whatever blank pad appears shortly after launch,
# regardless of why it appeared.
set -uo pipefail

export GDK_BACKEND=x11

XPAD_DIR="$HOME/.config/xpad"

# Notes that had real content before this launch — used below to tell a
# leftover blank pad from a note the user starts typing into right away.
existing_notes=$(find "$XPAD_DIR" -maxdepth 1 -name 'content-*' -size +0c 2>/dev/null | wc -l)

xpad --no-new &

# Give Xpad a few seconds to map its windows before checking.
sleep 3

close_blank_pads() {
    hyprctl eval '
        local wins = hl.get_windows({})
        for _, w in ipairs(wins) do
            if w.class == "xpad" and w.title == "" then
                hl.dispatch(hl.dsp.focus({ window = w }))
                hl.dispatch(hl.dsp.window.close())
            end
        end
    ' >/dev/null 2>&1
}

# Only step in if there were already real notes — an empty-titled pad on a
# totally fresh install (no notes yet) is legitimate, not the bug.
if [ "$existing_notes" -gt 0 ]; then
    close_blank_pads
fi
```

## Notes

- **Undocumented `hl.monitor` fields discovered while testing this:** `disabled = true`
  and `disabled = false` toggle a monitor on/off at runtime (e.g.
  `hyprctl eval 'hl.monitor({output = "HDMI-A-1", disabled = true})'`) — not shown in any
  example in this repo, found by trial. Useful for testing monitor-hotplug behavior
  without physically unplugging anything. `hyprctl keyword monitor ...` (the classic
  syntax) does *not* work on this Lua config ("keyword can't work with non-legacy
  parsers") — same restriction noted in [[refresh-rate]].
- **`hyprctl dispatch <name> <args>` doesn't accept classic-style arguments** on this
  Lua-config build either — e.g. `hyprctl dispatch closewindow address:0x...` fails to
  parse. Use `hyprctl eval` with a full Lua snippet instead
  (`hl.dispatch(hl.dsp.window.close())` etc.), same as `hl.monitor` above.
- **`hl.get_windows({...})` filters by class/address are unreliable** — `hl.get_windows({class = "^(xpad)$"})` (regex, matching `window_rule` syntax) silently returned zero
  results, and `hl.get_windows({address = "0x..."})` returned the *wrong* window
  entirely. The reliable pattern, used throughout the hooks above: call
  `hl.get_windows({})` with no filter to get every window, then filter manually in Lua
  (`if w.class == "xpad" then ...`). Window fields are `w.class`, `w.title`,
  `w.address`, and `w.at` (a table with `.x`/`.y`, *not* an array — `w.at[1]` is `nil`).
- **Bug (fixed same day): a stale systemd-generated autostart unit kept double-launching
  Xpad.** Xpad had auto-created `~/.config/autostart/xpad.desktop` on its own first run
  (an XDG autostart entry, `Exec=xpad` with no flags). Deleting that file alone didn't
  stop it: `systemd-xdg-autostart-generator` had already generated
  `app-xpad@autostart.service` from it into `/run/user/1000/systemd/generator.late/`,
  and a generated unit doesn't get removed just because its source `.desktop` file
  disappears — only `systemctl --user daemon-reload` re-runs the generator against
  current files. Confirmed live via `systemctl --user list-units` (`app-xpad@autostart.service` showing `loaded active running`, with systemd itself warning "changed on
  disk, the version systemd has loaded is outdated") and via `ps` (a plain
  `/usr/bin/xpad`, no `--no-new`, launched with `PPID` = the systemd --user manager, not
  this config's own autostart chain). This unit respawns on every login (it's
  `PartOf=graphical-session.target`, which restarts each session) using its stale
  definition, racing the properly-flagged launch from `xpad-launch.sh` above — explains
  both the recurring blank pad and some of the position confusion seen while debugging
  this. **Fix:** `systemctl --user stop app-xpad@autostart.service`,
  `systemctl --user disable app-xpad@autostart.service`,
  `systemctl --user daemon-reload` — confirmed gone from `list-units` afterward. If a
  `~/.config/autostart/xpad.desktop` ever reappears (Xpad seems to create it itself,
  cause not investigated further), delete it *and* run `daemon-reload`, not just the
  delete.
- **Verified live, repeatedly, using the real monitors** (not simulated): the full
  disconnect → reconnect round trip via the `disabled` toggle above. Moved both real
  notes to distinct positions, disabled `HDMI-A-1` (workspace 7 correctly fell back to
  `eDP-1`, translating both notes by the same delta — Hyprland's native behavior,
  unmodified), then re-enabled it (workspace 7 moved back to `HDMI-A-1`, and the
  `monitor.added` hook correctly translated both notes back to their exact original
  coordinates, no overlap). Also verified the full autostart chain end-to-end: killed
  Xpad, ran `xpad-launch.sh` directly (simulating what `hyprland.start` does), confirmed
  no blank pad, `xwayland: true`, and both notes landing at their last-saved position.
- **Bug (fixed same day): the reconnect-repair hook used to call
  `hl.dsp.window.center()`** instead of the translate-by-delta approach shown above.
  It does move a misplaced note back onto the correct monitor, but centering has no
  memory of where the note was relative to the others — every repaired note ends up at
  the same centered point, which is what caused visible overlap specifically right
  after a reconnect (not on every launch). Fixed by computing
  `dx = target.x - source.x` between the two monitors and applying that as a relative
  move instead, which preserves each note's position relative to the others. This is
  the second time centering caused this exact symptom in this feature — see the
  `float=true -> center=true` override above, which was the first.
- Takes effect on next full Hyprland restart for the `autostart.lua` changes (that
  hook doesn't rerun on a plain `hyprctl reload`, same caveat as
  [[persistent-special-workspace-apps]]); the `windowrules.lua` changes apply
  immediately on `hyprctl reload`.
- Attempted on Mango too (2026-09-14), fully reverted — see `mango/xpad-workspace-and-monitor-persistence.md`
  for the full story. Auto-launch/auto-migrate automation was built and verified working,
  but reverted after it triggered an Xpad startup-race bug that briefly corrupted saved
  note positions; a manual-placement fallback (a dedicated tag 5, opened by hand) was
  tried next but didn't work either — Xpad itself doesn't respect Mango's current focus
  when creating an additional note from an already-running instance. Mango is back to
  stock tag config with no Xpad-related changes at all. This Hyprland version is
  unaffected and still works as documented above (Hyprland-Lua's `hl.on`/`hl.dispatch`
  hooks don't have the same focus-tracking gap).
