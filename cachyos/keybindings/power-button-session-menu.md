# Power button opens the session menu instead of powering off

**Date:** 2026-10-16
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`, `/etc/systemd/logind.conf.d/power-key.conf` (new). Copies: [`../files/.config/hypr/config/binds.lua`](../files/.config/hypr/config/binds.lua), [`../files/etc/systemd/logind.conf.d/power-key.conf`](../files/etc/systemd/logind.conf.d/power-key.conf)

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Noctalia]]
<!-- graph:end -->

## What
A short press of the laptop's power button now opens Noctalia's session panel (the same
as SUPER+SHIFT+Q) instead of shutting down immediately. A long hold still forces the
machine off in hardware.

## Why
An accidental press powered the laptop off mid-session (2026-10-16 01:59): logind's
default for a short press is `HandlePowerKey=poweroff`, with no confirmation, and no
program on this machine held a power-key inhibitor (Noctalia only holds "lock before
sleep").

## Change
logind stops acting on the key (drop-in, so the package-owned `logind.conf` stays
untouched and updates never produce a `.pacnew` to merge):
```bash
sudo mkdir -p /etc/systemd/logind.conf.d
printf '[Login]\nHandlePowerKey=ignore\n' | sudo tee /etc/systemd/logind.conf.d/power-key.conf
sudo systemctl reload systemd-logind     # no session restart needed
```
Hyprland binds the key, in `binds.lua` next to SUPER+SHIFT+Q:
```lua
hl.bind("XF86PowerOff", hl.dsp.exec_cmd(shell_cmd("panel-toggle session")))
```
`shell_cmd()` comes from `config/shell.lua` ([[dms-trial]]), so under DMS the same key
opens DMS's power menu.

Verify: `busctl get-property org.freedesktop.login1 /org/freedesktop/login1
org.freedesktop.login1.Manager HandlePowerKey` → `s "ignore"`.

## Notes
- The bind alone isn't enough: until logind ignores the key it powers off first and the
  menu only flashes. logind reads the drop-in on `reload` or at boot.
- At the greeter (no Hyprland running) a short press now does nothing; use the greeter's
  own power buttons or a long hold.
- First attempt edited `/etc/systemd/logind.conf` in an editor without root, so it never
  saved (file still dated 2026-09-22, running value still `poweroff`); the drop-in was
  used instead.
