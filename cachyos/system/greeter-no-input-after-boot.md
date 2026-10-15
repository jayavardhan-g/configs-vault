# Greeter had no keyboard/mouse after boot (unresolved, one-off so far)

**Date:** 2026-10-16
**Category:** system
**Files touched:** none (diagnosis only)

<!-- graph:begin -->
**Graph:** [[Noctalia]] · [[greetd]]
<!-- graph:end -->

## What
After the accidental power-off ([[power-button-session-menu]]), three boots in a row
(01:59, 02:01, 02:04) came up at the Noctalia greeter with no working mouse and only a
partly working keyboard. Switching VT (Ctrl+Alt+F-key away and back) brought input back.
A later hard reset (long-press power off) cleared it: input worked from power-on.

## Why (what the logs showed)
- `noctalia-greeter-compositor` failed to open input devices at start:
  `[libseat] Could not take device: No such device` /
  `Failed to open device: '/dev/input/event13': No such device`. The greeter bound *a*
  keyboard but no pointer; on the VT switch (02:05:16) it re-took devices and bound the
  pointer and all keyboards instantly. On that retry it failed only on `event5–7`, device
  nodes that no longer existed.
- The built-in ASUS keyboard ("N-KEY Device") is **re-bound during every boot**:
  `hid-generic` takes it first (input5–7), then the `asus` HID driver re-creates it
  (input13–15). The stale nodes the greeter tripped over are the removed hid-generic ones.
- Not a race with the greeter start itself: re-binding finished at 02:04:02.9, the greeter
  started at 02:04:17. `greetd.service` is already ordered after `plymouth-quit-wait`.
- Not caused by the DMS trial or theme work: no kernel/greetd/greeter/systemd/libseat
  change; the only installs that day were `dms-shell`, `matugen`, `cava`, `wtype` (no udev
  rules or modules). The journal keeps only ~1 day (~46 MB), so whether earlier cold boots
  were affected can't be checked.
- The Hyprland segfault at 01:59:10 (in `libaquamarine`) happened *during* the power-off
  teardown — a side effect, not the cause.

## Change
None yet. If it happens again:
- **Workaround:** at the dead greeter press Ctrl+Alt+F2 then Ctrl+Alt+F1.
- **Next fix to try:** load `hid_asus` in the initramfs (add to `MODULES=()` in
  `/etc/mkinitcpio.conf`, rebuild via the Limine mkinitcpio hook) so the keyboard is bound
  once by the right driver and never re-created mid-boot.
- Alternative: a greetd drop-in with `ExecStartPre=/usr/bin/udevadm settle` (cheap, but
  devices looked settled 13 s before the greeter started, so it may not help).

## Notes
Useful checks: `journalctl -b <n> -t noctalia-greeter-compositor | grep -i "take device"`,
and `journalctl -b <n> -o short-precise | grep -E "asus 0003|hid-generic 0003:0B05"` for
the re-bind timing.
