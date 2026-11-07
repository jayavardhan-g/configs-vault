#!/usr/bin/env bash
# Phase 11 - net-watchdog: if there's no default gateway but the cable is connected,
# ask NetworkManager to connect instead of skipping.
# Why: 2026-11-07, after swapping the router, enp2s0 had carrier again but NetworkManager
# sat in "disconnected" and never asked the new router for an address; the old watchdog
# only logged "No default gateway found, skipping check" every minute, so the NAS stayed
# offline until a hard reboot.
# Run as: sudo bash ~/nas-setup/phase11-watchdog-no-gateway.sh
set -euo pipefail

cp -p /usr/local/bin/net-watchdog "/usr/local/bin/net-watchdog.bak.$(date +%s)"
cat > /usr/local/bin/net-watchdog <<'EOF'
#!/usr/bin/env bash
# Pings the default gateway (the user's own router, not the wider internet).
# If the gateway itself is unreachable, this is a real local link/DHCP
# problem -> reset the ethernet interface.
#
# If there is NO default gateway at all but the cable is connected,
# NetworkManager is stuck "disconnected" (seen 2026-11-07 after a router swap)
# -> ask it to connect, which also requests a new DHCP lease.
#
# If the gateway IS reachable but a real internet site is NOT, that means
# the LAN link is fine but the router's own upstream connection is down
# (e.g. the college network's LDAP captive-portal session expired).
# Resetting the local interface would NOT fix that, so we only log it
# distinctly - someone needs to log back into the portal from a browser.

IFACE="enp2s0"
GATEWAY=$(ip route show default | awk '/default/ {print $3; exit}')

if [ -z "$GATEWAY" ]; then
    if [ "$(cat "/sys/class/net/$IFACE/carrier" 2>/dev/null)" = "1" ]; then
        logger -t net-watchdog "No default gateway but $IFACE has a cable link - asking NetworkManager to connect"
        nmcli device connect "$IFACE" >/dev/null 2>&1 \
            || logger -t net-watchdog "nmcli device connect $IFACE failed"
    else
        logger -t net-watchdog "No default gateway and no cable link on $IFACE - nothing to do"
    fi
    exit 0
fi

if ping -c 3 -W 2 "$GATEWAY" > /dev/null 2>&1; then
    # Local link to the router is fine. Check real internet separately,
    # using two independent domains (not a bare IP - some networks
    # specifically filter well-known resolver IPs like 1.1.1.1/8.8.8.8,
    # which caused false positives here). Require BOTH to fail before
    # concluding the internet is actually down.
    if ! curl -fsS -m 5 -o /dev/null https://archlinux.org && ! curl -fsS -m 5 -o /dev/null https://cloudflare.com; then
        logger -t net-watchdog "Gateway $GATEWAY is reachable but internet is NOT - upstream/college login likely needed (LDAP captive portal?). Not resetting the interface since the local link is fine."
    fi
else
    logger -t net-watchdog "Gateway $GATEWAY unreachable - resetting $IFACE"
    nmcli device disconnect "$IFACE" || true
    sleep 2
    nmcli device connect "$IFACE" || true
fi
EOF
chmod 755 /usr/local/bin/net-watchdog
bash -n /usr/local/bin/net-watchdog && echo "net-watchdog updated (old copy kept as .bak)"
/usr/local/bin/net-watchdog && echo "test run OK (gateway present, so nothing to do)"
