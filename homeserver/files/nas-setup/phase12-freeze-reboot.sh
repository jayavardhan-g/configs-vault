#!/usr/bin/env bash
# Phase 12 - reboot by itself after a freeze, instead of hanging until someone presses reset.
# Why: 2026-11-11 15:10 the NAS hung hard (log just stops, machine still powered on, fans
# running) and stayed dead until a manual reset at 21:46. Nothing could recover it:
#   - kernel.panic = 0            -> a kernel panic waits forever
#   - "nowatchdog" on the cmdline -> the kernel's soft/hard lockup detector was off
#                                    (CachyOS default, saves a little power)
#   - no hardware watchdog in use -> iamt_wdt and intel_oc_wdt were loaded but unused;
#                                    iTCO_wdt (blacklisted by CachyOS) is locked off by the
#                                    BIOS ("unable to reset NO_REBOOT flag")
# Three layers, from mildest to last resort:
#   1. sysctl: panic/oops/lockups -> reboot 10 s later
#   2. cmdline: drop "nowatchdog" so lockups are actually detected
#   3. intel_oc_wdt + systemd RuntimeWatchdogSec=30s: if the whole machine (or PID 1) hangs,
#      the chipset resets it in hardware
# First prove the watchdog resets the board: sudo bash ~/nas-setup/phase12-test-hw-watchdog.sh
# Run as: sudo bash ~/nas-setup/phase12-freeze-reboot.sh   (then reboot)
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }

echo "==> 1. Hardware watchdog: intel_oc_wdt (iTCO_wdt is locked off by the BIOS: NO_REBOOT)"
WD=""
for w in /sys/class/watchdog/watchdog*; do
    [ "$(cat "$w/identity" 2>/dev/null)" = "intel_oc_wdt" ] && WD="$w"
done
if [ -z "$WD" ]; then
    echo "!! no intel_oc_wdt watchdog device. Stopping here, nothing changed. Tell Claude."
    exit 1
fi
echo "    OK: $WD = intel_oc_wdt"
# watchdogN numbering depends on load order (iamt_wdt also registers), so give it a stable name.
cat > /etc/udev/rules.d/60-watchdog-oc.rules <<'EOF'
SUBSYSTEM=="watchdog", ATTR{identity}=="intel_oc_wdt", SYMLINK+="watchdog-oc"
EOF
udevadm control --reload
udevadm trigger --subsystem-match=watchdog
udevadm settle
ls -l /dev/watchdog-oc

mkdir -p /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/watchdog.conf <<'EOF'
[Manager]
WatchdogDevice=/dev/watchdog-oc
RuntimeWatchdogSec=30s
RebootWatchdogSec=10min
EOF

echo "==> 2. Kernel: panic, oops and lockups reboot after 10 s"
cat > /etc/sysctl.d/90-freeze-reboot.conf <<'EOF'
kernel.panic = 10
kernel.panic_on_oops = 1
kernel.softlockup_panic = 1
kernel.hardlockup_panic = 1
EOF
sysctl --system >/dev/null
sysctl kernel.panic kernel.panic_on_oops kernel.softlockup_panic kernel.hardlockup_panic

echo "==> 3. Boot cmdline: removing 'nowatchdog' (re-enables the lockup detector)"
CONF=/etc/default/limine
if grep -q 'nowatchdog' "$CONF"; then
    cp -p "$CONF" "$CONF.bak.$(date +%s)"
    sed -i 's/ *\bnowatchdog\b//' "$CONF"
    grep -n CMDLINE "$CONF"
    limine-update
    if grep -q nowatchdog /boot/limine.conf; then
        echo "!! /boot/limine.conf still has nowatchdog - tell Claude"
    else
        echo "    OK: no 'nowatchdog' left in /boot/limine.conf"
    fi
else
    echo "    already removed"
fi

echo "==> Applying the systemd watchdog now"
systemctl daemon-reexec
sleep 2
systemctl show -p WatchdogDevice -p RuntimeWatchdogUSec
journalctl -b -t systemd --since "-1min" --no-pager | grep -i watchdog || true

echo
echo "==> Done. Reboot now (sudo reboot) so the cmdline change takes effect, then ask Claude to verify."
