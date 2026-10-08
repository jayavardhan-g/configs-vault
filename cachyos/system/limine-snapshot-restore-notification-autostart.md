# Limine snapshot-restore notification never appeared under Hyprland

**Date:** 2026-09-18
**Category:** system
**Files touched:** `~/.config/hypr/config/autostart.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Limine]]
<!-- graph:end -->

## What
Booting into a Limine "snapshot" boot entry (via `limine-snapper-sync`) never showed the
expected "Restore this snapshot now!" desktop notification, even though the same setup
works out of the box on GNOME. Added `hl.exec_cmd("limine-snapper-restore --notify")` to
Hyprland's autostart.

## Why
`limine-snapper-sync` ships the notification as an XDG autostart entry
(`/etc/xdg/autostart/limine-restore-notify.desktop`, `Exec=limine-snapper-restore
--notify`). GNOME's session manager activates `xdg-desktop-autostart.target` and runs
every `/etc/xdg/autostart/*.desktop` entry automatically; Hyprland does not — confirmed
`systemctl --user status xdg-desktop-autostart.target` was `inactive (dead)` even mid
graphical session. This is also documented directly in `limine-snapper-sync`'s own
README under "No restore notification appears after booting a snapshot": *"Some window
managers (e.g., Hyprland) do not use the standard XDG autostart mechanism by default."*
Its recommended fix is exactly this — add the command to the WM's own autostart.

(Not a notification-daemon problem on this machine: `noctalia` already owns
`org.freedesktop.Notifications` on the session bus, so `notify-send` works fine once the
command actually runs.)

## Change
In `~/.config/hypr/config/autostart.lua`, inside the `hl.on("hyprland.start", ...)` block,
right after the `noctalia` launch line:

```lua
hl.exec_cmd(
    "bash -c 'for i in $(seq 1 30); do busctl --user list 2>/dev/null | grep -q org.freedesktop.Notifications && break; sleep 0.5; done; exec limine-snapper-restore --notify'"
)
```

It's a safe no-op on a normal (non-snapshot) boot — `limine-snapper-restore --notify`
checks `/proc/cmdline` for a snapshot `rootflags=` pattern and exits immediately if the
current boot isn't a snapshot. The wait loop gives up and runs it anyway after ~15s even
if the notification service never appears.

## Notes
- **Superseded a simpler version** that called `hl.exec_cmd("limine-snapper-restore
  --notify")` directly, right after `noctalia`. Confirmed broken on a real snapshot boot
  (the notification silently never appeared) — `exec_cmd` doesn't wait for a launched
  process to be ready, so this raced `noctalia`'s own startup: `notify-send` ran before
  noctalia's `org.freedesktop.Notifications` D-Bus service had registered, and the
  notification was silently dropped. The wait loop above polls for that service instead of
  guessing a fixed delay.
- `limine-snapper-restore` (no `--notify`) can also be run manually any time from a
  terminal while booted into a snapshot — it detects the graphical session and opens a
  terminal running the elevated restore itself, without needing the autostart wiring.
- This machine's `/etc/limine-snapper-sync.conf` uses the default `RESTORE_METHOD=replace`
  (not `snapper`/`opensuse`), which is the method documented to work correctly from
  Hyprland's snapshot-boot mode (CachyOS boots snapshots through an ephemeral overlayfs via
  the `sd-btrfs-overlayfs` mkinitcpio hook — `RESTORE_METHOD=snapper` explicitly does not
  support that and would fail with "subvolume is not a btrfs subvolume").
