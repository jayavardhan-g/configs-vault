# Switched default session back to Hyprland — Mango has an unresolved NVIDIA GPU-selection bug

**Date:** 2026-09-21
**Category:** system
**Files touched:** None directly — session choice is remembered automatically by

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Mango]] · [[Noctalia]] · [[Monitors]] · [[greetd]] · [[NVIDIA]]
<!-- graph:end -->

noctalia-greeter (state under `/var/lib/noctalia-greeter`, root-owned, not hand-edited).
Just pick "Hyprland" at the login screen once and it persists as the default for
subsequent boots.

## What
Switched the default login session from Mango back to Hyprland, on this hybrid
Intel + NVIDIA (GTX 1660 Ti) laptop. Temporary, until Mango reaches a stable 1.0 release
— all the Mango-specific entries in this index (cursor theme, keybind ports, workspace
wrap, the `monitor_from_direction()` quirk, etc.) are left as-is and still apply whenever
switching back.

## Why
Mango was intermittently getting stuck with one compositor thread pegged at ~47-51% CPU
(sometimes spiking higher under load), driving CPU package temps up to 96°C and maxing
both fans (6600/5600 RPM), with no correlation to what was on screen. Diagnosed with
`perf record -p <mango-pid>`: ~30%+ of samples were in `clock_gettime`/
`__vdso_clock_gettime` called from inside `libnvidia-eglcore.so` — a known class of bug
where wlroots compositors on NVIDIA's proprietary/open-kernel driver busy-poll instead of
blocking properly on GPU fences (matches long-standing reports on NVIDIA's own developer
forums: "Nvidia X11 driver busy-polls kernel on clock_gettime in a tight loop", 20-50% CPU
on Wayland vs 1-2% on X11 for the same driver).

Separately, Mango was also unreliable at attaching *both* GPUs at boot — some boots only
the Intel-driven laptop panel (eDP-1) came up with the NVIDIA-driven external monitor
(HDMI-A-1, hardwired to the dGPU on this board) missing entirely from `mmsg get
all-monitors`; other boots the reverse (eDP-1 missing, HDMI-A-1 fine). Same software everySy
boot, different single-GPU-only outcome — a boot-order race in which GPU gets attached,
not a config issue.

Tested Hyprland (0.56.2, aquamarine 0.15.0 backend) side by side on the same hardware:
both monitors attached consistently, CPU stayed flat ~11% idle and ~11% under real load
(Zen + WhatsApp Web, other tab actively busy at 50%+), `perf` showed no hotspot at all —
NVIDIA's EGL libraries are loaded (needed for its hardwired HDMI output) but aquamarine
apparently renders each output on its own directly-attached GPU instead of routing
everything through whichever GPU wins a startup race, so it never hits the same busy-loop.

## Change
No config change — just select "Hyprland" instead of "Mango" at the noctalia-greeter
login screen. The choice is remembered automatically for future boots.

## Notes
- **Don't try `WLR_DRM_DEVICES` in Mango's own `~/.config/mango/cfg/env.conf`** — its
  `env = KEY,VALUE` directives only apply to processes *Mango spawns*, never to Mango's
  own process. Confirmed twice (checked `/proc/<mango-pid>/environ` after `reload_config`)
  that it never took effect. Same caveat likely applies to `syncobj_enable` and other
  settings that need a fresh GPU/DRM context, not just a config reload.
- **Don't put `WLR_DRM_DEVICES` (or any GPU-selection var) in `/etc/environment`
  system-wide either** — it's read by PAM for *every* login on the machine, including the
  `greeter` user's own session. Setting it there made noctalia-greeter-compositor exit
  immediately on every start ("greeter exited without creating a session"), which hit
  systemd's `start-limit-hit` and took down greetd entirely — no display on either
  monitor, no login screen, only recoverable from a TTY. If a GPU-selection env var is
  worth revisiting, it needs to be scoped to the actual session's own startup path, not a
  global PAM file.
- `/dev/dri/card0` / `card1` / `card2` numbering is **not stable across boots** — confirmed
  the Intel/NVIDIA card numbers swapped between two boots in the same session. Use
  `/dev/dri/by-path/pci-<bus>-card` instead if a GPU-selection var is ever retried.
- Mango issue tracker: [mangowm/mango#1343](https://github.com/mangowm/mango/issues/1343)
  confirms `WLR_DRM_DEVICES` does work on Mango's non-Vulkan (EGL) render backend — so the
  approach itself isn't wrong, just needs the right place to set it (likely a wrapper
  around Mango's own exec, not `/etc/environment` or its own config file).
- Revisit this switch when Mango ships a 1.0 release — check its changelog for anything
  addressing NVIDIA render-device selection or the busy-poll pattern before assuming it's
  fixed.
