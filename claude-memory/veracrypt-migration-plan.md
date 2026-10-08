---
name: veracrypt-migration-plan
description: User may migrate desktop-c (live Windows OS partition) from BitLocker to VeraCrypt in the future; nani was decrypted instead
metadata:
  node_type: memory
  type: project
  originSessionId: 714475f4-e8ea-4199-a155-7feb30cce91a
  modified: 2026-09-26T18:57:27.797Z
---

Jayavardhan is thinking about using VeraCrypt instead of BitLocker for encrypting drives
going forward, not yet decided/scheduled. The only drive still on BitLocker is `desktop-c`
(`/dev/nvme0n1p3`, the live Windows OS partition); the plan is to re-encrypt it with
VeraCrypt "in future if necessary", with no timeline.

The original 2026-09-20 plan also covered `nani` (`/dev/nvme0n1p6`). On 2026-09-27 he
decided `nani` holds nothing sensitive and permanently decrypted it instead (via
`manage-bde -off` in Windows). It's now plain NTFS labeled `Study`, auto-mounted from
`/etc/fstab` at `/mnt/study`, the same way `laptop` / `Data` is at `/mnt/data`. Both are
out of `bit-unlock`/`bit-lock`.

**Why:** two BitLocker limitations hit on 2026-09-20 (documented in the `configs` repo at
`bitlocker/bit-unlock-cryptsetup.md`, on branch `worktree-display-mode-menu-record`,
not yet merged to `main`): a resized volume's BitLocker header size mismatch that
`cryptsetup` can't repair, and Windows 10 Home being unable to re-enable BitLocker on a data
volume at all. VeraCrypt is cross-platform and edition-independent.

**How to apply:** if a future session touches drive encryption or `bit-unlock`/`bit-lock`,
treat VeraCrypt as the likely eventual replacement for `desktop-c` only. The scripts are
BitLocker-specific (`cryptsetup --type bitlk`) and would need real changes for VeraCrypt.
`desktop-c` is the live Windows OS partition, so decrypting/re-encrypting it needs more
care than a data drive.

<!-- graph:begin -->
**Graph:** [[Monitors]] · [[BitLocker]] · [[Windows]]
<!-- graph:end -->
