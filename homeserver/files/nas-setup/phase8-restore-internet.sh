#!/usr/bin/env bash
# Phase 8 test - undo phase8-simulate-outage.sh and bring the network back.
# Safe to run any number of times.
# Run as: sudo bash ~/nas-setup/phase8-restore-internet.sh
set -uo pipefail

echo "==> Cancelling the automatic restore timer (if the simulate script set one)..."
systemctl stop phase8-auto-restore.timer phase8-auto-restore.service 2>/dev/null || true

echo "==> Removing every TEST firewall rule..."
# ufw pads numbers ("[ 1]"), and numbers shift after each delete,
# so re-list and delete the first TEST rule until none are left.
removed=0
while :; do
    n=$(ufw status numbered | grep 'TEST:' | head -n1 | sed -E 's/^\[ *([0-9]+)\].*/\1/')
    [ -z "$n" ] && break
    ufw --force delete "$n" >/dev/null
    removed=$((removed + 1))
done
echo "    Removed $removed rule(s)."
ufw reload >/dev/null

echo "==> Bringing ethernet back up..."
nmcli connection up "Wired connection 1" >/dev/null 2>&1 || true
sleep 5

echo "==> Restarting Tailscale..."
systemctl restart tailscaled
sleep 5

echo
echo "==> Health check"
GATEWAY=$(ip route show default | awk '/default/ {print $3; exit}')
ok() { printf '    %-22s %s\n' "$1" "$2"; }
ping -c2 -W2 "$GATEWAY" >/dev/null 2>&1 && ok "Router ($GATEWAY)" "OK" || ok "Router ($GATEWAY)" "FAIL"
curl -fsS -m8 -o /dev/null https://archlinux.org && ok "Internet" "OK" || ok "Internet" "FAIL (college portal login needed?)"
tailscale status >/dev/null 2>&1 && ok "Tailscale" "OK" || ok "Tailscale" "FAIL - give it a minute, then: tailscale status"
ok "WARP" "$(warp-cli --accept-tos status 2>/dev/null | head -n1)"
if ufw status | grep -q 'TEST:'; then ok "TEST rules left" "YES - run this script again"; else ok "TEST rules left" "none"; fi
