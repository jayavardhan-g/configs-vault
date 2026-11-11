#!/usr/bin/env bash
# Phase 12 test - does the hardware watchdog (intel_oc_wdt, held by systemd) really reset
# this board when everything stops?
# Simulates a total hang: turns OFF the kernel's own panic-reboot for this boot only
# (kernel.panic=0), then crashes the kernel. Nothing in software can recover from that,
# so only the hardware watchdog can bring the NAS back.
# Expected: the NAS comes back by itself ~30 s after the crash (+ boot time, ~2 min total).
# If it is still unreachable after 5 min: the watchdog does not work; press the reset
# button and tell Claude.
# kernel.panic goes back to 10 on the next boot (/etc/sysctl.d/90-freeze-reboot.conf).
# Run as: sudo bash ~/nas-setup/phase12-test-hw-watchdog.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }

systemctl show -p WatchdogDevice -p RuntimeWatchdogUSec
[ "$(systemctl show -P RuntimeWatchdogUSec)" != "0" ] || { echo "!! systemd isn't using a watchdog - run phase12-freeze-reboot.sh first"; exit 1; }

echo "==> Crashing the kernel in 5 s with panic-reboot off (Ctrl+C to cancel)"
sleep 5
logger -t wdt-test "crashing kernel with kernel.panic=0; only the hardware watchdog can reset"
sync; sleep 1
sysctl -q -w kernel.panic=0 kernel.sysrq=1
echo c > /proc/sysrq-trigger
