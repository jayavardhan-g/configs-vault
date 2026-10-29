#!/usr/bin/env bash
# Phase 10 - follow the rentry.org/torrentvpn guide on the server, like the laptop:
#   WARP as a full tunnel (tunnel_only = no WARP DNS, so MagicDNS is untouched),
#   qBittorrent bound to the CloudflareWARP interface, DHT/PeX/LPD back on (defaults),
#   UPnP off, excluded file types; our extra restrictions (proxy, lockdown) removed.
# Extra steps needed only because this server also runs Tailscale Funnel:
#   - Tailscale's relay (DERP) + control servers are excluded from WARP, refreshed daily
#   - funnel-watchdog now tests the real public link every 5 min and re-announces if broken
# Run as: sudo bash ~/nas-setup/phase10-warp-full-tunnel.sh
set -euo pipefail

USER_NAME="${SUDO_USER:?run with sudo}"
CONF="/home/$USER_NAME/.config/qBittorrent/qBittorrent.conf"
QBT="qbittorrent-nox@$USER_NAME"
W() { warp-cli --accept-tos "$@"; }

echo "==> 1/6 Tailscale exclusion refresher..."
cat > /usr/local/bin/warp-tailscale-exclude <<'EOF'
#!/usr/bin/env bash
# Keeps Tailscale's relay (DERP) and control servers out of the WARP tunnel, so
# Tailscale and Funnel keep working while WARP carries everything else.
# Only adds addresses; never removes. Safe to run any time.
set -u
log() { logger -t warp-tailscale-exclude "$*"; }
for _ in $(seq 1 60); do
    tailscale status --json 2>/dev/null | grep -q '"BackendState": "Running"' && break
    sleep 2
done
WANT=$( {
    tailscale debug derp-map 2>/dev/null | python3 -I -c '
import json, sys
d = json.load(sys.stdin)
for r in (d.get("Regions") or {}).values():
    for n in r.get("Nodes") or []:
        if n.get("IPv4"): print(n["IPv4"])'
    getent ahostsv4 controlplane.tailscale.com log.tailscale.com | awk '{print $1}'
} | sort -u )
if [ -z "$WANT" ]; then log "no Tailscale addresses found - skipping"; exit 0; fi
HAVE=$(warp-cli --accept-tos tunnel ip list 2>/dev/null)
added=0; total=0
for ip in $WANT; do
    total=$((total + 1))
    grep -qwF "$ip" <<<"$HAVE" && continue
    warp-cli --accept-tos tunnel ip add "$ip" >/dev/null && added=$((added + 1))
done
log "checked $total Tailscale addresses, added $added new"
EOF
chmod 755 /usr/local/bin/warp-tailscale-exclude

cat > /etc/systemd/system/warp-tailscale-exclude.service <<'EOF'
[Unit]
Description=Keep Tailscale relay/control servers out of the WARP tunnel
After=tailscaled.service warp-svc.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/warp-tailscale-exclude
EOF

cat > /etc/systemd/system/warp-tailscale-exclude.timer <<'EOF'
[Unit]
Description=Refresh Tailscale exclusions in WARP daily (and shortly after boot)

[Timer]
OnBootSec=3min
OnUnitActiveSec=1d

[Install]
WantedBy=timers.target
EOF

echo "==> 2/6 Upgrading funnel-watchdog (tests the real link, every 5 min)..."
cat > /usr/local/bin/funnel-watchdog <<'EOF'
#!/usr/bin/env bash
# Keeps Tailscale Funnel's public link alive. Only acts when Funnel is ON in the
# saved serve config (moviesshare start); never turns it on by itself.
#   --boot   always re-announce (after a reboot the setting survives but isn't announced)
#   (none)   timer mode: re-announce if the public name is missing OR the link
#            doesn't answer through Tailscale's public entry (checked twice).
set -u
PORT=8096
log() { logger -t funnel-watchdog "$*"; }

for _ in $(seq 1 60); do
    tailscale status --json 2>/dev/null | grep -q '"BackendState": "Running"' && break
    sleep 2
done

STATUS=$(tailscale funnel status 2>/dev/null)
grep -q 'Funnel on' <<<"$STATUS" || exit 0   # sharing is off - leave it off

reannounce() {
    tailscale funnel --https=443 off >/dev/null 2>&1
    if tailscale funnel --bg "$PORT" >/dev/null 2>&1; then
        log "$1 - re-announced Funnel"
    else
        log "$1 - re-announce FAILED"
    fi
}

if [ "${1:-}" = "--boot" ]; then reannounce "boot"; exit 0; fi

NAME=$(grep -oP 'https://\K[^ /]+(?= \(Funnel on\))' <<<"$STATUS" | head -n1)
[ -n "$NAME" ] || exit 0
# Public DNS over HTTPS (MagicDNS would always answer). No answer at all = no internet,
# nothing to judge.
ANSWER=$(curl -s -m10 -H 'accept: application/dns-json' \
    "https://cloudflare-dns.com/dns-query?name=$NAME&type=A") || exit 0
case "$ANSWER" in
    *'"Status":3'*) reannounce "public name missing"; exit 0 ;;
esac
IP=$(grep -oE '"data":"[0-9.]+"' <<<"$ANSWER" | head -n1 | cut -d'"' -f4)
[ -n "$IP" ] || exit 0
link_ok() {
    code=$(curl -s -m15 -o /dev/null -w '%{http_code}' --resolve "$NAME:443:$IP" "https://$NAME/")
    [[ "$code" =~ ^[23] ]]
}
link_ok && exit 0
sleep 20
link_ok && exit 0
reannounce "public link not answering"
EOF
chmod 755 /usr/local/bin/funnel-watchdog
sed -i 's/^OnUnitActiveSec=.*/OnUnitActiveSec=5min/' /etc/systemd/system/funnel-watchdog.timer

systemctl daemon-reload
systemctl enable warp-tailscale-exclude.timer funnel-watchdog.timer >/dev/null
/usr/local/bin/warp-tailscale-exclude
journalctl -t warp-tailscale-exclude -n1 --no-pager -o cat

echo "==> 3/6 WARP -> full tunnel (tunnel_only)..."
W mode tunnel_only >/dev/null
W connect >/dev/null 2>&1 || true
for _ in $(seq 1 30); do ip link show CloudflareWARP >/dev/null 2>&1 && break; sleep 1; done
ip -br addr show CloudflareWARP

echo "==> 4/6 qBittorrent -> guide settings (backup kept)..."
systemctl stop "$QBT"
cp -p "$CONF" "$CONF.bak.$(date +%s)"
sudo -u "$USER_NAME" python3 -I - "$CONF" <<'EOF'
import sys, re
path = sys.argv[1]
lines = open(path).read().splitlines()
SET = {
    "BitTorrent": {
        r"Session\Interface": "CloudflareWARP",
        r"Session\InterfaceName": "CloudflareWARP",
        r"Session\DHTEnabled": "true",
        r"Session\PeXEnabled": "true",
        r"Session\LSDEnabled": "true",
        "ExcludedFileNamesEnabled": "true",
        r"Session\ExcludedFileNames": "*.lnk, *.scr, *.arj",
    },
    "Network": {"PortForwardingEnabled": "false"},
}
DROP = re.compile(r"^(Proxy\\.*|Session\\ProxyPeerConnections)=")
out, section, done = [], None, set()
def flush(sec):
    for k, v in SET.get(sec, {}).items():
        if (sec, k) not in done:
            out.append(f"{k}={v}"); done.add((sec, k))
for line in lines:
    m = re.match(r"^\[(.+)\]$", line)
    if m:
        if section:
            while out and out[-1] == "": out.pop()
            flush(section); out.append("")
        section = m.group(1); out.append(line); continue
    if DROP.match(line): continue
    key = line.split("=", 1)[0]
    if section in SET and key in SET[section]:
        out.append(f"{key}={SET[section][key]}"); done.add((section, key)); continue
    out.append(line)
if section: flush(section)
for sec in SET:
    if any((sec, k) not in done for k in SET[sec]):
        out += ["", f"[{sec}]"]; flush(sec)
open(path, "w").write("\n".join(out) + "\n")
EOF
grep -nE '^\[|Interface|DHT|PeX|LSD|ExcludedFileNames|Proxy|PortForwarding' "$CONF"

echo "==> 5/6 Removing the kernel lockdown (binding replaces it)..."
rm -f "/etc/systemd/system/qbittorrent-nox@.service.d/warp-lockdown.conf"
rmdir "/etc/systemd/system/qbittorrent-nox@.service.d" 2>/dev/null || true
systemctl daemon-reload
systemctl start "$QBT"
sleep 8

echo "==> 6/6 Checks"
echo "--- qBittorrent sockets (should be on CloudflareWARP / 172.16.0.2 only):"
ss -tulpn | grep qbittorrent-nox | awk '{print $1, $5}'
echo "--- WARP egress:"; curl -s -m10 https://www.cloudflare.com/cdn-cgi/trace | grep -E '^warp='
echo "--- Tailscale:"; tailscale netcheck 2>&1 | grep -E 'UDP:|Nearest DERP'
echo "--- public link (funnel-watchdog run):"
/usr/local/bin/funnel-watchdog; journalctl -t funnel-watchdog --since -2min --no-pager -o cat || true
echo
echo "Done. Next: the guide's ipleak.net test from the qBittorrent web UI."
