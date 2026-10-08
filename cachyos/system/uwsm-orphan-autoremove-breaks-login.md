# pacman autoremove took out uwsm, silently broke uwsm-managed Hyprland login

**Date:** 2026-09-14
**Category:** system
**Files touched:** none directly (package reinstall only) — relevant existing files:

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Noctalia]] · [[CachyOS]] · [[greetd]] · [[uwsm]]
<!-- graph:end -->

`/etc/greetd/config.toml`, `/usr/share/wayland-sessions/hyprland-uwsm.desktop`

## What
`uwsm` (and its deps `python-pyxdg`, `python-dbus`) got removed by a pacman orphan
cleanup (`pacman -Rns $(pacman -Qtdq)`-style) on 2026-09-13 22:51. Nothing in pacman's
dependency graph points at `uwsm` — it's only referenced by the **Exec=** line of the
"Hyprland (uwsm-managed)" wayland-session `.desktop` entry
(`Exec=uwsm start -e -D Hyprland hyprland.desktop`), which pacman's orphan detection has
no visibility into. Selecting that login entry at the greetd/noctalia-greeter screen
failed silently: the session opened and closed in the same second, greetd bounced back
to the login screen with no on-screen error, and login looked totally broken.

The plain, non-uwsm "Hyprland" entry (`Exec=/usr/bin/start-hyprland`) was unaffected —
it doesn't depend on `uwsm` at all — so it stayed available as a working fallback the
whole time. So did MangoWM's session.

## Why
Diagnosed via `journalctl -u greetd`, which showed `pam_unix(greetd:session): session
opened` immediately followed by `session closed` for the same login attempt (no delay) —
that pattern means the launched session command exited immediately rather than crashing
after actually starting a compositor. Cross-checked `grep -i removed /var/log/pacman.log`
against the two `wayland-sessions/*.desktop` Exec lines and found `uwsm` was the missing
piece; `which uwsm` confirmed it wasn't on disk.

## Change
```
sudo pacman -S uwsm
```
Reinstalls `uwsm` and its deps (`python-pyxdg`, `python-dbus`). No config file changes
needed — the `.desktop` entries and `binds.lua`'s `launchPrefix = "uwsm app -- "`
convention were already correct; only the package was missing.

## Notes
- **Treat `uwsm` as NOT safe to autoremove**, even though pacman's orphan detector will
  flag it as one (nothing `Depends On:` it). It's a *runtime* dependency of a login-screen
  entry, not of any installed package — orphan detection can't see that relationship.
  Before running any `pacman -Rns $(pacman -Qtdq)`-style cleanup, sanity-check the output
  against `grep -i '^Exec=' /usr/share/wayland-sessions/*.desktop` first.
- Same applies in principle to any other package only referenced from a `.desktop` Exec=
  line, a systemd unit `ExecStart=`, or a shell script — not just uwsm.
