# Windows dual-boot: boot order keeps resetting + BitLocker recovery prompt

**Date:** 2026-09-04
**Category:** limine
**Files touched:** `/boot/limine.conf` (ESP config), Windows BCD (via `bcdedit`, no local file)

<!-- graph:begin -->
**Graph:** [[Limine]] · [[BitLocker]] · [[Windows]]
<!-- graph:end -->

## What
Two related fixes for a Limine + Windows dual-boot setup:

1. Windows was silently overwriting the UEFI firmware boot order (`BootOrder` in NVRAM)
   to put itself first every time it booted normally, undoing a Limine-first order set via
   `efibootmgr`. Fixed by editing Windows' own `{fwbootmgr}` record via `bcdedit`, since
   that's the source of truth Windows re-syncs the NVRAM order from.
2. The existing Limine menu entry for Windows chainloaded `bootmgfw.efi` directly, which
   broke BitLocker's boot integrity check and forced a recovery-key prompt on every
   Windows boot through Limine. Fixed by switching that entry to Limine's
   `efi_boot_entry` protocol.

## Why
Wanted Limine to be the actual default at power-on (not Windows silently reclaiming
first place), with Windows still selectable from the Limine menu and booting cleanly
without hitting the ~48-character BitLocker recovery key every time.

## Change

### 1. Stop Windows from resetting the NVRAM boot order

Confirmed via `efibootmgr -v` that despite having set Limine first, the live `BootOrder`
had Windows Boot Manager back at the front — Windows had silently rewritten it. Plain
`efibootmgr -o <limine-id>,...` from Linux would just get reverted again the next time
Windows booted, because Windows re-syncs NVRAM order from its own BCD store, not the
other way around.

Fix: in Windows, open an elevated Command Prompt and run:

```
bcdedit /set {fwbootmgr} displayorder {<limine-firmware-entry-guid>} /addfirst
```

This edits `{fwbootmgr}\displayorder` in Windows' BCD store — the record Windows treats
as authoritative for firmware boot order — so future Windows-triggered NVRAM syncs keep
Limine first instead of re-asserting Windows. The GUID is Windows' own internal BCD
identifier for the Limine firmware entry (not the same as its `efibootmgr` Boot####
number) — find it via `bcdedit /enum firmware` in Windows.

### 2. Stop the BitLocker recovery prompt when booting Windows via Limine

In `/boot/limine.conf`, the Windows entry was:

```
//Windows Boot Manager
    protocol: efi_chainload
    image_path: guid(453FE620-A87D-458E-89B0-0B08BAA8E773):/efi/Microsoft/Boot/bootmgfw.efi
```

Changed to:

```
//Windows Boot Manager
    protocol: efi_boot_entry
    entry: Windows Boot Manager
```

`entry:` must exactly match the description string of the real NVRAM boot entry (check
with `efibootmgr -v` — typically literally `Windows Boot Manager`). No `limine-install`
or reinstall needed — Limine re-reads `limine.conf` straight from the ESP on every boot.

## Notes
- **[`files/boot/limine.conf`](files/boot/limine.conf)** is a real copy (copied manually
  via `sudo cp`, since this session can't read root-owned `/boot` itself). No secrets in
  it — the `machine-id=`/`module_path`/`path` values are just systemd's install ID and
  content-integrity hashes, and `root=UUID=...` is a partition identifier, not a
  credential. Only the first ~14 lines (`timeout`/`default_entry`/`remember_last_entry`
  plus the CachyOS theme block) are hand-relevant; the rest is `limine-entry-tool`'s
  auto-generated kernel-entry boilerplate that changes on every kernel update — expect
  this stored copy to drift there and not worry about re-syncing it for that part.
- Root cause of the BitLocker prompt: chainloading `bootmgfw.efi` through any
  third-party bootloader (Limine, GRUB, etc.) changes the measured TCG/PCR7 boot event
  log, which BitLocker/TPM treats as tampering and forces recovery-key entry.
  `efi_boot_entry` avoids this because it asks firmware to reboot straight into the
  existing NVRAM entry (similar to setting `BootNext`), producing the same clean boot
  chain as picking Windows from the firmware's own one-time boot menu.
- Fallback that always works regardless of Limine config: at power-on, use the
  firmware's own one-time boot menu (F8/F11/F12/Del, varies by motherboard) to pick
  "Windows Boot Manager" directly — untouched by anything above.
- Unverified: whether `limine-entry-tool` (which auto-generates the "EFI fallback"
  block immediately below this entry in `limine.conf`) ever regenerates or overwrites
  this manually-added Windows entry too. If a kernel update wipes this edit, that tool
  owns more of the file than expected — worth re-checking if it happens.
- Confirmed working 2026-09-04: Windows boots via the Limine menu with no BitLocker
  prompt.
