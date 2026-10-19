#!/usr/bin/env bash
# Phase 9 - keep the public Jellyfin link (Tailscale Funnel) alive across reboots.
# If Funnel was on before a reboot, re-announce it at boot; if it was off, leave it off.
# Also re-checks every 15 min and re-announces if the public name has disappeared.
# Run as: sudo bash ~/nas-setup/phase9-funnel-watchdog.sh
set -euo pipefail

echo "==> Writing /usr/local/bin/funnel-watchdog..."
cat > /usr/local/bin/funnel-watchdog <<'EOF'
#!/usr/bin/env bash
# Keeps Tailscale Funnel's public link alive. Only acts when Funnel is ON in the
# saved serve config (moviesshare start); never turns it on by itself.
#   --boot   always re-announce: after a reboot the setting survives but isn't
#            re-announced to Tailscale, so the public DNS name disappears.
#   (none)   timer mode: re-announce only if public DNS says the name doesn't exist.
set -u
PORT=8096
log() { logger -t funnel-watchdog "$*"; }

# Wait up to 2 minutes for tailscaled to be connected.
for _ in $(seq 1 60); do
    tailscale status --json 2>/dev/null | grep -q '"BackendState": "Running"' && break
    sleep 2
done

STATUS=$(tailscale funnel status 2>/dev/null)
if ! grep -q 'Funnel on' <<<"$STATUS"; then
    exit 0    # sharing is off - leave it off
fi

reannounce() {
    tailscale funnel --https=443 off >/dev/null 2>&1
    if tailscale funnel --bg "$PORT" >/dev/null 2>&1; then
        log "$1 - re-announced Funnel"
    else
        log "$1 - re-announce FAILED"
    fi
}

if [ "${1:-}" = "--boot" ]; then
    reannounce "boot"
    exit 0
fi

NAME=$(grep -oP 'https://\K[^ /]+(?= \(Funnel on\))' <<<"$STATUS" | head -n1)
[ -n "$NAME" ] || exit 0
# Public DNS over HTTPS (this machine's MagicDNS would always answer).
# If the request itself fails (no internet), there's nothing to judge - do nothing.
ANSWER=$(curl -s -m10 -H 'accept: application/dns-json' \
    "https://cloudflare-dns.com/dns-query?name=$NAME&type=A") || exit 0
case "$ANSWER" in
    *'"Status":3'*) reannounce "public name missing" ;;
esac
EOF
chmod 755 /usr/local/bin/funnel-watchdog

echo "==> Writing systemd units..."
cat > /etc/systemd/system/funnel-watchdog-boot.service <<'EOF'
[Unit]
Description=Re-announce Tailscale Funnel after boot (only if it was on)
After=tailscaled.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/funnel-watchdog --boot

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/funnel-watchdog.service <<'EOF'
[Unit]
Description=Re-announce Tailscale Funnel if its public name disappeared
After=tailscaled.service network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/funnel-watchdog
EOF

cat > /etc/systemd/system/funnel-watchdog.timer <<'EOF'
[Unit]
Description=Check the public Funnel link every 15 minutes

[Timer]
OnBootSec=10min
OnUnitActiveSec=15min

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable funnel-watchdog-boot.service
systemctl enable --now funnel-watchdog.timer

echo
echo "==> Test run (timer mode - only acts if Funnel is on but its public name is missing):"
/usr/local/bin/funnel-watchdog
journalctl -t funnel-watchdog -n 3 --no-pager || true
echo
systemctl is-enabled funnel-watchdog-boot.service funnel-watchdog.timer
echo "Done. Logs: journalctl -t funnel-watchdog"
