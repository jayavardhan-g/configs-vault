#!/usr/bin/env bash
# Phase 8 test - simulate "internet is gone, LAN is fine" by blocking all
# outbound traffic except loopback and the LAN. Reversible with
# phase8-restore-internet.sh.
# Run as: sudo bash ~/nas-setup/phase8-simulate-outage.sh
set -euo pipefail

echo "==> Current default outgoing policy:"
ufw status verbose | grep -i "default:"

echo "==> Inserting temporary deny-all-outbound rule (lowest priority, LAN/loopback allowed above it)..."
ufw insert 1 deny out to any comment 'TEST: simulate internet outage'
ufw insert 1 allow out to 192.168.0.0/24 comment 'TEST: LAN'
ufw insert 1 allow out on lo comment 'TEST: loopback'
ufw reload

echo
echo "==> Done. Internet (anything outside 192.168.0.0/24) is now blocked outbound."
echo "    LAN access (SSH, Samba, Jellyfin, qBittorrent WebUI) should still work fine."
echo "    Try reaching the NAS from your laptop now over LAN to confirm."
echo
ufw status numbered | grep TEST
