---
type: entity
hub: "[[System]]"
---
# CachyOS

The distro (Arch-based). Packages via pacman + AUR; some configs are package-owned and must not be edited in place.

**Hub:** [[System]]
**Config:** `/etc/pacman.conf` (copy in `cachyos/files/etc/`)
**Related:** [[Kernel]] · [[fish]] · [[uwsm]]

<!-- auto:begin -->
## Entries

- [[cachyos-mango-noctalia-setup|Installing cachyos-mango-noctalia alongside an existing cachyos-hypr-noctalia setup]]
- [[cachyos-shell-configs-are-package-owned|CachyOS's shell configs are package-owned — never edit them directly]]
- [[kernel-pinned-intel-nvme-remap|LTS kernel pinned at 6.18.50-3: CachyOS dropped `intel-nvme-remap` (main kernel fixed in 7.2.9)]]
- [[uwsm-orphan-autoremove-breaks-login|pacman autoremove took out uwsm, silently broke uwsm-managed Hyprland login]]
- [[vscode-official-build|VSCode (official Microsoft build) + keyring for Settings Sync]]
- [[keybinds|Keybinds reworked to match the Hyprland setup]]
- [[version-bug-upgrade|Upgraded to mangowm 0.17.0 via AUR (0.16.1 had real bugs)]]
- [[spotify-and-spotx|Spotify (Flatpak, user-scope) + SpotX patch]]
- [[xpad-sticky-notes|Xpad — desktop sticky notes]]
<!-- auto:end -->
