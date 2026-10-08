# Xpad — desktop sticky notes

**Date:** 2026-09-12
**Category:** xpad
**Files touched:** none (package install + CLI usage only — Hyprland wiring is separate, see [[xpad-workspace-and-monitor-persistence]])

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Monitors]] · [[Xpad]] · [[CachyOS]]
<!-- graph:end -->

## What
Installed `xpad` (`pacman -S xpad`) as a desktop sticky-notes app — notes are plain
windows (no tray dependency), saved as one file pair per note under `~/.config/xpad/`
(`content-XXXX` for the text, `info-XXXX` for size/color/position). Two flags matter for
reliable operation:
- `xpad --no-new` — launch flag. Plain `xpad` with no flags creates a fresh blank pad on
  every launch regardless of whether saved pads already exist; `--no-new` skips that.
- `xpad --quit` — the *only* way a pad's position actually gets saved (see Notes).

## Why
Wanted sticky notes that survive a reboot and stay on a specific workspace. Tried the
already-installed x-apps `sticky` first — it does correctly autosave note content to
`~/.config/sticky/notes.json` on every edit — but its entire UI is a tray icon, and that
icon never renders under this Wayland setup (see Notes). With no reachable tray icon
there's no way to open, view, or create a note at all, independent of persistence.
Switched to Xpad because it doesn't use a tray for anything core — notes are just
windows.

## Change
```bash
sudo pacman -S xpad
```
Launch with both flags for a login/autostart context:
```bash
xpad --no-new
# ... later, before anything kills the process:
xpad --quit
```

## Notes
- **Why `sticky` (x-apps) doesn't work here, at all:** it uses `XApp.StatusIcon`, a
  Cinnamon-specific tray protocol (`org.x.StatusIcon`), not the standard
  freedesktop/KDE `StatusNotifierItem` that generic Wayland trays (waybar, noctalia,
  etc.) implement. To bridge into a normal tray it needs a helper, `xapp-sn-watcher`,
  which must itself claim the well-known bus name `org.kde.StatusNotifierWatcher` to act
  as that bridge — but that name is already owned by whatever *is* hosting your real
  tray (noctalia, in this case), and D-Bus only allows one owner per name. Confirmed
  live via `busctl --user list`: sticky's process appears on the bus (`org.x.sticky`)
  but registers no `StatusNotifierItem`, while other tray apps on the same system do;
  manually starting `xapp-sn-watcher` exits immediately since the name is taken. No fix
  short of dropping the working tray for every other app or patching the shell to speak
  Cinnamon's protocol directly — not worth chasing further.
- **Position is only saved on a *clean* quit, not on process kill.** Confirmed live,
  repeatedly: killing xpad with SIGTERM/`pkill` always leaves every pad's saved position
  at `x 0 y 0` in its `info-*` file, no matter what. Running `xpad --quit` (its own IPC
  shutdown command, sent to the already-running instance over its unix socket) reliably
  saves the real coordinates instead — verified by moving a pad, running `--quit`, and
  reading back the exact same coordinates from the info file. This means anything that
  stops xpad (a logout, a session manager killing app processes) needs to call
  `xpad --quit` *before* whatever normally kills processes gets to it, or position is
  silently lost every time regardless of any other fix.
- **Position can only be *queried* under XWayland, not native Wayland.** Wayland
  deliberately doesn't let a client know its own absolute screen position (only X11
  exposes that) — Xpad's own position-save code relies on being able to query it.
  Confirmed live: launching under native Wayland, every pad's info file shows `x 0 y 0`
  even right after a clean quit; launching the identical binary with `GDK_BACKEND=x11`
  (forcing XWayland) saves and restores real, correctly-scaled coordinates. So on a
  Wayland compositor, Xpad needs `GDK_BACKEND=x11` set for it specifically, or position
  persistence silently never works at all, independent of the clean-quit requirement
  above — both are needed together.
- **The occasional extra blank pad on login isn't fully explained.** `--no-new` reliably
  prevents it in an isolated manual launch (kill everything, launch once, check — no
  blank pad, every time tested this way). But at real login it intermittently still
  created one anyway, even with a single process confirmed launched with `--no-new`
  and no duplicate launcher present. Root cause not pinned down (suspected race with
  dbus/gsettings/session startup timing that doesn't reproduce in a manual mid-session
  test) — worked around rather than fixed, see the login-time safety net in
  [[xpad-workspace-and-monitor-persistence]].
