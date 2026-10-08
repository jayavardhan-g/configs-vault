# Noctalia greeter-sync password prompt

**Date:** 2026-08-29 (resolved 2026-09-13, reworked 2026-10-01)
**Category:** system
**Files touched:** `~/.config/hypr/scripts/rotation-pauses-greeter-sync.sh` (stored: [files/.config/hypr/scripts/rotation-pauses-greeter-sync.sh](../files/.config/hypr/scripts/rotation-pauses-greeter-sync.sh)), `~/.config/systemd/user/rotation-pauses-greeter-sync.{path,service}` (stored: [files/.config/systemd/user/](../files/.config/systemd/user/)), `~/.config/noctalia/config.toml` (stored: [files/.config/noctalia/config.toml](../files/.config/noctalia/config.toml)), `~/.config/noctalia/rotation-pauses-greeter-sync.toml` (generated, not stored)

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Noctalia]] · [[greetd]]
<!-- graph:end -->

## What
Greeter auto-sync (copying wallpaper/colors/theme/font to the login/lock-screen greeter,
one admin-password prompt per sync) is **on**, except while Noctalia's automatic
wallpaper rotation is on — then it's paused, so rotation never prompts. A systemd user
path unit flips `[shell.greeter_sync] auto_sync` to the opposite of
`[wallpaper.automation] enabled` whenever Noctalia's settings change.

## Why
Jayavardhan wants the original behaviour — a password prompt on every
wallpaper/theme/settings change made by hand — but not a prompt every 30 min from
rotation. Noctalia has no "skip while rotating" option.

## How the sync elevates (as of noctalia 5.2.0 / noctalia-greeter 1.5.0)
`pkexec /usr/bin/noctalia-greeter-apply-appearance --sync /run/user/1000/noctalia-greeter-sync`
under its own polkit action `org.noctalia.greeter.sync-appearance`
(`/usr/share/polkit-1/actions/org.noctalia.greeter.apply-appearance.policy`, default
`auth_admin`). Auto-sync fires on wallpaper, colors, theme-mode or shell-font changes.

## Change
`config.toml` must **not** set `[shell.greeter_sync] auto_sync` (and don't toggle
"Auto-Sync Greeter" in the Settings UI — that writes `settings.toml`, which overrides
every file in the config dir and would defeat the watcher).

Script `~/.config/hypr/scripts/rotation-pauses-greeter-sync.sh` (executable; full
commented version in the stored copy): reads `wallpaper.automation.enabled` from
`noctalia config export` and writes, only if different from what's there (checks once
immediately, then again 1 s later — see Notes):
```toml
# ~/.config/noctalia/rotation-pauses-greeter-sync.toml
[shell.greeter_sync]
auto_sync = true   # false while rotation is on
```
Noctalia loads every `*.toml` in `~/.config/noctalia/` and reloads on change, so no
restart is needed.

`~/.config/systemd/user/rotation-pauses-greeter-sync.service`:
```ini
[Unit]
Description=Pause Noctalia greeter auto-sync while wallpaper rotation is on
StartLimitIntervalSec=0

[Service]
Type=oneshot
ExecStart=%h/.config/hypr/scripts/rotation-pauses-greeter-sync.sh
TimeoutStartSec=30s
```
`~/.config/systemd/user/rotation-pauses-greeter-sync.path`:
```ini
[Unit]
Description=Watch Noctalia settings for the wallpaper rotation toggle

[Path]
PathChanged=%h/.local/state/noctalia/settings.toml
PathChanged=%h/.config/noctalia/config.toml

[Install]
WantedBy=default.target
```
```
systemctl --user daemon-reload
systemctl --user enable --now rotation-pauses-greeter-sync.path
systemctl --user start rotation-pauses-greeter-sync.service   # create the file once
```

## Notes
- **Verified 2026-10-01:** turning rotation on flipped `auto_sync` to false within ~1s;
  wallpaper changes while paused produced no prompt; turning rotation off flipped it
  back to true. `settings.toml` writes (Settings UI / `noctalia msg wallpaper-set`) do
  trigger the path unit.
- **Bug found and fixed the same day — watcher died on a burst of saves.** Noctalia saved
  `settings.toml` 6 times in ~5 s while rotation was being turned on in Settings; the
  service hit systemd's default start limit (5 starts / 10 s, `start-limit-hit`), the
  path unit went `failed`, and the save with `enabled = true` was never seen — so
  `auto_sync` stayed true and every manual wallpaper change with rotation on still
  prompted. Fix: `StartLimitIntervalSec=0` on the service (each run is ~40 ms and
  idempotent), and the script applies twice (immediately + after 1 s) because systemd
  drops path events that arrive while the service is still running. Re-tested with 8
  saves in ~2 s: 2 runs, no failure, correct value. If it ever looks stuck:
  `systemctl --user status rotation-pauses-greeter-sync.path`, then
  `systemctl --user reset-failed rotation-pauses-greeter-sync.{path,service}` and
  `systemctl --user start rotation-pauses-greeter-sync.path`.
- **Resource safety (audited 2026-10-01):** nothing runs between changes — the `.path`
  unit is an inotify watch held by the already-running systemd user manager. The
  service is oneshot, so at most one instance ever runs (triggers during a run are
  dropped, not queued), each run is ~1 s wall / ~40 ms CPU and leaves no process
  behind. `TimeoutStartSec=30s` (oneshot default is infinite) so a hung
  `noctalia config export` can't stall the watcher forever. No feedback loop: the
  generated file isn't watched, and rewriting it doesn't make Noctalia re-save
  `settings.toml` (tested: 1 write → 1 run). Worst case if something rewrote
  `settings.toml` nonstop: ~1 run/s (bounded by the run's own `sleep 1`), and past 200
  triggers in 2 s systemd's own path `TriggerLimit` stops the unit.
- **Possible single prompt when switching rotation on:** enabling rotation makes
  Noctalia jump to a new wallpaper immediately, racing the watcher (in the test the
  watcher won by ~1s and nothing prompted). If a prompt ever appears right at that
  moment, cancel it.
- While rotation is on, manual theme/font changes don't sync either — rotation's
  wallpaper changes also change the wallpaper-derived palette, so they can't be told
  apart. Run `noctalia msg greeter-sync` by hand if needed.
- In noctalia 5.2.0 the built-in default is `auto_sync = false` (older notes assumed
  true), so "on" has to be set explicitly — that's what the generated file does.
- **Tried and replaced the same day:** a `[hooks] wallpaper_changed` script that synced
  only on manual wallpaper changes (hooks fire once per monitor; same-wallpaper
  `wallpaper-set` doesn't fire). Replaced because the wanted behaviour is sync on *every*
  appearance change, not just wallpaper.
- **Password-free alternative (not chosen):** a polkit rule granting
  `org.noctalia.greeter.sync-appearance` to this user (`subject.local && subject.active`)
  in `/etc/polkit-1/rules.d/` would make every sync silent. Not chosen because any process
  running as the user could then trigger the root helper, and a future helper version
  would inherit the grant.
- **History (2026-08-29, noctalia 5.0 beta / greeter 1.2.1):** auto_sync then went
  through `run0` — the generic `org.freedesktop.systemd1.manage-units` action on a
  randomly-named transient unit — so no scoped polkit rule was possible and
  `auth_admin_keep` never cached. The fix then was `auto_sync = false` plus manual
  `noctalia msg greeter-sync`; re-triggered by turning on 30-min rotation.
- Unrelated to [[greetd-pam-gnome-keyring-unlock]]: that prompt was gnome-keyring
  (decrypting secrets), this one is polkit (authorizing root).
