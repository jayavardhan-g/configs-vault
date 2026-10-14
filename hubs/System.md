---
type: hub
---
# System

The OS layer under the desktop: CachyOS packaging and kernels, boot (Limine, Windows dual-boot), disks and encryption, login (greetd, keyring, uwsm), locale, GPU.

Back to [[Home]].

<!-- auto:begin -->
## Entities

- [[CachyOS]] — The distro (Arch-based) (9 entries)
- [[Kernel]] — Kernel choice and pins: LTS kernel pinned while CachyOS dropped `intel-nvme-remap`; the home server pins LTS too (1 entries)
- [[Limine]] — Bootloader, including the Windows dual-boot entry and snapshot-restore notification (3 entries)
- [[BitLocker]] — Windows drive encryption (4 entries)
- [[Windows]] — The dual-booted Windows install, and things migrated from it (browser profiles, the notes vault) (4 entries)
- [[greetd]] — Login manager (Noctalia greeter) (4 entries)
- [[GNOME Keyring]] — Secret store used by VSCode Settings Sync and browsers; unlocked at login via greetd PAM (2 entries)
- [[uwsm]] — Session manager wrapping Hyprland's login; once removed by `pacman` autoremove, which silently broke login (2 entries)
- [[NVIDIA]] — Discrete GPU (3 entries)
- [[Locale]] — System locale named `en_IN.UTF-8` (bare `en_IN` broke btop from the launcher) (3 entries)
- [[Bitwarden]] — Password manager; its CLI (`bw`) feeds BitLocker unlock keys to cryptsetup (1 entries)
<!-- auto:end -->
