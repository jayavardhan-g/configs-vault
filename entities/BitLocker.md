---
type: entity
hub: "[[System]]"
---
# BitLocker

Windows drive encryption. Drives are unlocked from Linux with `cryptsetup` and Bitwarden (`bit-unlock`); `desktop-c` is the only drive still on BitLocker.

**Hub:** [[System]]
**Config:** `~/.local/bin/bit-unlock`, `bit-lock`, `/etc/fstab`
**Related:** [[Windows]] · [[Bitwarden]] · [[Limine]]

<!-- auto:begin -->
## Entries

- [[bit-unlock-cryptsetup|Unlock BitLocker drives via Bitwarden + cryptsetup, no retyped passwords]]
- [[windows-dual-boot-order-and-bitlocker|Windows dual-boot: boot order keeps resetting + BitLocker recovery prompt]]
- [[vault-setup-and-migration|Setting up Obsidian on CachyOS, migrating the existing vault]]
- [[windows-profile-migration|Migrating Zen Browser profiles from Windows to Linux]]
<!-- auto:end -->
