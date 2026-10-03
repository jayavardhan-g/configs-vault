#!/usr/bin/env bash
# Phase 8 test - simulate "internet is gone, LAN is fine": block outbound traffic
# to anything outside the LAN, keep loopback and the LAN working.
# Undo with phase8-restore-internet.sh. As a safety net it also undoes itself
# automatically after 10 minutes.
# Run as: sudo bash ~/nas-setup/phase8-simulate-outage.sh
set -euo pipefail

LAN="192.168.0.0/24"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
RESTORE="$SCRIPT_DIR/phase8-restore-internet.sh"

if ufw status | grep -q 'TEST:'; then
    echo "TEST rules already present - run $RESTORE first."
    exit 1
fi

echo "==> Adding test rules..."
# "insert 1" puts each rule at the TOP, so add them in reverse:
# the deny goes in first so it ends up LAST, below the two allows.
ufw insert 1 deny out to any comment 'TEST: simulate internet outage'
ufw insert 1 allow out to "$LAN" comment 'TEST: LAN'
ufw insert 1 allow out on lo comment 'TEST: loopback'
ufw reload >/dev/null

echo "==> Safety net: automatic restore in 10 minutes..."
systemd-run --unit=phase8-auto-restore --on-active=10min /bin/bash "$RESTORE" >/dev/null

echo
echo "==> Rule order (allows must be above the deny):"
ufw status numbered | grep TEST

echo
echo "==> Quick check"
GATEWAY=$(ip route show default | awk '/default/ {print $3; exit}')
ping -c2 -W2 "$GATEWAY" >/dev/null 2>&1 && echo "    Router ($GATEWAY): reachable (expected)" || echo "    Router ($GATEWAY): UNREACHABLE - not expected, run the restore script"
curl -fsS -m5 -o /dev/null https://archlinux.org 2>/dev/null && echo "    Internet: still reachable - not expected" || echo "    Internet: blocked (expected)"

echo
echo "Within a minute the watchdog should log 'Gateway ... reachable but internet is NOT'"
echo "and should NOT reset enp2s0. Watch it with:"
echo "    journalctl -t net-watchdog -f"
echo "Undo now with:  sudo bash $RESTORE   (otherwise it undoes itself in 10 minutes)"
