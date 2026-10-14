# $BROWSER pointed at Zen (was CachyOS's stock firefox)

**Date:** 2026-10-07
**Category:** system
**Files touched:** `~/.config/uwsm/env` (copy: [`../files/.config/uwsm/env`](../files/.config/uwsm/env))

<!-- graph:begin -->
**Graph:** [[uwsm]] · [[Zen Browser]]
<!-- graph:end -->

## What
Changed `export BROWSER=firefox` to `export BROWSER=app.zen_browser.zen` in uwsm's
session environment file.

## Why
Claude Code (and other CLIs that honour `$BROWSER` before `xdg-open`) opened links in
Firefox even though Zen is the default browser everywhere else:
- `xdg-settings get default-web-browser`, and the `x-scheme-handler/http(s)` /
  `text/html` defaults in `~/.config/mimeapps.list`, were already
  `app.zen_browser.zen.desktop`.
- But `~/.config/uwsm/env` still had `BROWSER=firefox` from the CachyOS Hyprland starter
  config (unchanged since install, 2026-08-28). uwsm exports it to the whole session.

## Change
`~/.config/uwsm/env`, first line:
```sh
export BROWSER=app.zen_browser.zen
```
To apply without logging out (new launches only; already-open terminals keep the old
value until restarted):
```bash
systemctl --user set-environment BROWSER=app.zen_browser.zen
dbus-update-activation-environment BROWSER=app.zen_browser.zen
```
Check: `systemd-run --user --quiet --pipe --wait printenv BROWSER`.

## Notes
- Zen is a Flatpak, so there's no `zen` binary. `app.zen_browser.zen` is Flatpak's
  exported launcher (`/var/lib/flatpak/exports/bin/`, on the session PATH). It's the
  same command Hyprland's `variables.lua` uses for SUPER+B.
- `$BROWSER` needs a single command (no spaces), so `flatpak run app.zen_browser.zen`
  would break tools that don't shell-split it.
- `BROWSER=xdg-open` was not used: `xdg-open` itself falls back to `$BROWSER` when no
  handler is found, which could loop.
- If the default browser changes again, update both this file and `mimeapps.list`
  (`xdg-settings set default-web-browser <app>.desktop`).
