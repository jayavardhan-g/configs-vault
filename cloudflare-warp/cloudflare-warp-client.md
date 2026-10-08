# Cloudflare WARP client (1.1.1.1)

**Date:** 2026-09-14
**Category:** cloudflare-warp
**Files touched:** none (no local dotfile — state lives in the package + systemd + WARP's own registration)

<!-- graph:begin -->
**Graph:** [[Cloudflare WARP]]
<!-- graph:end -->

## What
Installed the Cloudflare WARP client (`warp-cli`/`warp-svc`, the Linux equivalent of the
"1.1.1.1" app) and connected it.

## Why
User wanted Cloudflare WARP as a VPN/DNS client.

## Change
Now in the `cachyos` repo, so a plain pacman install works (Shelly installs the same
package):

```bash
sudo pacman -S cloudflare-warp-bin

sudo systemctl enable --now warp-svc

warp-cli registration new
warp-cli mode warp          # or "warp+doh" to also use 1.1.1.1 for DNS
warp-cli connect
warp-cli status              # should show "Connected"
```

pacman may prompt for optional deps of `webkit2gtk-4.1` (a hard dependency of this
package, used only by its GUI tray app — see Notes): `geoclue`, `gst-libav`,
`gst-plugins-bad`, `gst-plugins-good`. Skip all of them — none are needed for
`warp-cli`/`warp-svc` to work.

## Notes
- **Originally (2026-09-14) built from the AUR by hand**, because it wasn't in any repo
  then and no AUR helper or Shelly was installed: `git clone
  https://aur.archlinux.org/cloudflare-warp-bin.git` then `makepkg -si`. On 2026-10-02 a
  system update replaced it with the signed `cachyos` repo build of the same package
  (`pacman -Qi` now shows `Installed From: cachyos`), so the manual build is no longer
  needed.
- The home server runs WARP differently — `warp-cli mode proxy` (local SOCKS5 on port
  40000) so only qBittorrent uses it and Tailscale's routing isn't touched. See
  [[homeserver-setup]] (`../homeserver/homeserver-setup.md`).
- The package also ships a tray GUI, `warp-taskbar` (Flutter-based, not a plain script —
  that's why the package pulls in `libayatana-appindicator`/`webkit2gtk-4.1`). It's a
  separate **user** systemd service, not enabled by default install:
  `systemctl --user enable --now warp-taskbar`. Left disabled for now — CLI (`warp-cli`)
  is enough day to day.
- If the taskbar app is enabled later: Hyprland has no built-in tray, and Noctalia's own
  `tray` widget (already in the bar's `end` row per `~/.config/noctalia/config.toml`)
  only exposes styling options (`capsule`, `capsule_fill`) — no overflow/grouping, icons
  just show flat. No extra wiring needed beyond enabling the service; the icon will just
  appear alongside whatever else is in the tray.
