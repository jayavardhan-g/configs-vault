#!/usr/bin/env bash
# Phase 8 test - undo phase8-simulate-outage.sh, restoring normal internet access
# Run as: sudo bash ~/nas-setup/phase8-restore-internet.sh
set -euo pipefail

echo "==> Current rules containing 'TEST:' (for visibility/debugging):"
ufw status numbered | grep 'TEST:' || echo "    (none found)"

echo "==> Removing TEST firewall rules (highest-numbered first)..."
numbers=$(ufw status numbered | grep 'TEST:' | grep -oP '^\[\s*\K[0-9]+' | sort -rn)
if [ -z "$numbers" ]; then
    echo "    No TEST rules found - already clean."
else
    echo "    Deleting rule numbers: $numbers"
    for n in $numbers; do
        ufw --force delete "$n"
    done
fi
ufw reload

echo
echo "==> Done. Remaining firewall rules:"
ufw status numbered
