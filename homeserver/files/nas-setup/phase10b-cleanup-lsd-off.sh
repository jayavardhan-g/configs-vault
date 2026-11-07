#!/usr/bin/env bash
# Phase 10b - after Phase 10:
#   - remove wgcf + wireguard-tools (only used by the WireGuard test; not needed with the
#     WARP full tunnel)
#   - turn off qBittorrent's Local Peer Discovery (LAN-only, listens on all interfaces)
# Run as: sudo bash ~/nas-setup/phase10b-cleanup-lsd-off.sh
set -euo pipefail

USER_NAME="${SUDO_USER:?run with sudo}"
CONF="/home/$USER_NAME/.config/qBittorrent/qBittorrent.conf"
QBT="qbittorrent-nox@$USER_NAME"

echo "==> Removing wgcf and wireguard-tools..."
pacman -Rns --noconfirm wgcf wireguard-tools

echo "==> Local Peer Discovery off..."
systemctl stop "$QBT"
sed -i 's/^Session\\LSDEnabled=.*/Session\\LSDEnabled=false/' "$CONF"
grep -n 'LSDEnabled' "$CONF"
systemctl start "$QBT"
sleep 6

echo "==> qBittorrent sockets (no :6771 expected):"
ss -tulpn | grep qbittorrent-nox | awk '{print $1, $5}'
echo "Done."
