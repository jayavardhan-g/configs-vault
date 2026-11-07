#!/bin/bash
# Capture the IITB RADIUS CA certificate (depth=1) from wpa_supplicant's D-Bus
# "Certification" signal during a fresh 802.1X login, check it against the
# fingerprint seen in the logs, and save it for NetworkManager. Run as root.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }

WANT=e10803508e2c92f1ca1ac5e7c5fc7951cab14ecf731994df6e7555ffffbb71c9
OUT=/etc/NetworkManager/certs/iitb-ca.pem
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

busctl monitor --system fi.w1.wpa_supplicant1 --json=short > "$TMP/mon.json" 2>/dev/null &
MON=$!
sleep 1
# Switching SSIDs forces a full EAP handshake (no cached session).
nmcli -w 40 connection up eduroam >/dev/null
nmcli -w 40 connection up IITB-Wireless-Ex >/dev/null || true
sleep 2
kill "$MON" 2>/dev/null || true; wait "$MON" 2>/dev/null || true

python3 -I - "$TMP/mon.json" "$TMP/ca.der" <<'EOF'
import json, sys
def find(o):
    if isinstance(o, dict):
        if "cert" in o and "depth" in o:
            yield o
        for v in o.values(): yield from find(v)
    elif isinstance(o, list):
        for v in o: yield from find(v)
val = lambda x: x.get("data", x) if isinstance(x, dict) else x
for line in open(sys.argv[1]):
    try: msg = json.loads(line)
    except ValueError: continue
    if msg.get("member") != "Certification": continue
    for d in find(msg):
        if val(d["depth"]) == 1:
            c = val(d["cert"])
            c = bytes(c) if isinstance(c, list) else bytes.fromhex(c)
            open(sys.argv[2], "wb").write(c)
            sys.exit(0)
sys.exit("no depth=1 certificate captured")
EOF

GOT=$(sha256sum "$TMP/ca.der" | cut -d' ' -f1)
[ "$GOT" = "$WANT" ] || { echo "fingerprint mismatch: $GOT"; exit 1; }
mkdir -p "$(dirname "$OUT")"
openssl x509 -inform der -in "$TMP/ca.der" -out "$OUT"
chmod 644 "$OUT"
openssl x509 -in "$OUT" -noout -subject -enddate
echo "saved $OUT (fingerprint matches)"
