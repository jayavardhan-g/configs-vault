# Installing cachyos-mango-noctalia alongside an existing cachyos-hypr-noctalia setup

**Date:** 2026-09-13
**Category:** system
**Files touched:** none directly (package install/removal + a manual `cp`)

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Mango]] · [[Noctalia]] · [[CachyOS]]
<!-- graph:end -->

## What
Installed `mangowm` + `cachyos-mango-noctalia` to try Mango as a second
compositor alongside the existing Hyprland setup, without uninstalling
Hyprland. Two CachyOS-packaging-specific gotchas came up along the way.

## Why
User wanted to try MangoWM (see the earlier niri/Hyprland/MangoWM comparison)
without disturbing the working Hyprland+Noctalia setup.

## Change

**1. `cachyos-mango-noctalia` conflicts with the already-installed
`cachyos-hypr-noctalia`** (both `Provide`/`Conflict` on a virtual
`cachyos-desktop-settings` package name — CachyOS's way of marking these as
mutually-exclusive "settings flavors"). Removing the old one is the intended
path, not a workaround, and it's safe:
```sh
sudo pacman -R cachyos-hypr-noctalia
sudo pacman -S mangowm cachyos-mango-noctalia
```
Confirmed safe by checking exactly what `cachyos-hypr-noctalia` owned
(`pacman -Ql cachyos-hypr-noctalia`) before removing it: only
`/etc/skel/...` (irrelevant post-account-creation), a one-line Nvidia-only
`/etc/profile.d/Hyprland.sh` env-var script, and the generic (non-Hyprland-
specific) `/etc/greetd`-equivalent greeter config that the new package just
re-provides. **None of it touches the live `~/.config/hypr/` dotfiles** —
those aren't pacman-tracked at all. `hyprland` itself is marked "Explicitly
installed" in pacman, so it's never at risk of being swept away as an
unneeded dependency either.

**2. `cachyos-mango-noctalia` (like `cachyos-hypr-noctalia` before it) only
ships its files into `/etc/skel/...`**, which is the skeleton used when a
*new* user account is created — it does **not** get copied into an already-
existing account's home directory on install. Since this account predates
the package, `~/.config/mango/` didn't exist at all after installing, and
Mango silently fell back to the bare `/etc/mango/config.conf` package
default (no Noctalia autostart, no bar, no wallpaper - just a blank screen
with a cursor). Fix: manually copy the skeleton in:
```sh
cp -r /etc/skel/.config/mango ~/.config/mango
```
**Do not** also copy `/etc/skel/.config/noctalia/config.toml` over the
existing `~/.config/noctalia/config.toml` — that file is shared between
Hyprland and Mango (same app, same user), and already correctly tuned; the
skel version would reset it back to the package default.

## Notes
- **This same `/etc/skel`-only gotcha will bite again for any other
  `cachyos-*-noctalia` package** (e.g. a hypothetical `cachyos-niri-noctalia`)
  installed onto an existing account. Always check
  `pacman -Ql <package> | grep -v /etc/skel` after installing one of these to
  see what (if anything) actually lands outside the skeleton, and manually
  copy the compositor-specific skel subtree in if not.
- **A missing autostart has a second, less obvious symptom worth knowing
  about**: with no Noctalia (or any session shell) running, there's nothing
  to register a systemd-logind inhibitor on the power key, so pressing it
  triggers logind's raw default (`HandlePowerKey=poweroff`) — an **instant,
  unprompted shutdown** rather than a confirmation dialog. This resolves
  itself automatically once the correct autostart is wired up and Noctalia
  is actually running; no separate logind config change was needed or made.
- See [[keybinds]], [[appearance-and-input]], and [[version-bug-upgrade]]
  (all in the portable `mango/` folder, not here) for what came after
  Mango was actually running — none of that is CachyOS/Hyprland-specific,
  it's Mango's own config surface.
