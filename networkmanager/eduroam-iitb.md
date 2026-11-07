# eduroam and IITB-Wireless-Ex at IIT Bombay (NetworkManager profiles)

**Date:** 2026-11-07
**Category:** networkmanager
**Files touched:** `/etc/NetworkManager/system-connections/{eduroam,IITB-Wireless-Ex}.nmconnection` (created by `nmcli`; root-only and hold the password, so not copied), `/etc/NetworkManager/certs/iitb-ca.pem` (copy in `networkmanager/files/etc/NetworkManager/certs/`), capture script [`grab-iitb-ca.sh`](grab-iitb-ca.sh)

<!-- graph:begin -->
**Graph:** [[NetworkManager]]
<!-- graph:end -->

## What
`eduroam` and `IITB-Wireless-Ex` Wi-Fi profiles made with `nmcli`: PEAP + MSCHAPv2,
the LDAP id as identity, and the server certificate checked against IITB's own CA
(`/etc/NetworkManager/certs/iitb-ca.pem`).
This gives the same protection as Android's "trust this certificate" prompt.

## Why
Connecting from the Noctalia Wi-Fi menu kept failing. IITB's RADIUS server chains to
its own private CA ("IIT Bombay Computer Centre Certificate Authority"). That CA isn't
in the system trust store, and a Noctalia profile with a blank CA path checks against
the system CAs, so `wpa_supplicant` failed with `self-signed certificate in certificate
chain`. Giving the profile IITB's CA file is the whole fix.

## Change
```bash
# 1. IITB CA (public cert; a copy is in this repo)
sudo install -Dm644 networkmanager/files/etc/NetworkManager/certs/iitb-ca.pem \
  /etc/NetworkManager/certs/iitb-ca.pem

# 2. One profile per SSID, same settings
for ssid in eduroam IITB-Wireless-Ex; do
  nmcli connection add type wifi con-name "$ssid" ssid "$ssid" \
    wifi-sec.key-mgmt wpa-eap 802-1x.eap peap 802-1x.phase2-auth mschapv2 \
    802-1x.identity '<ldap>' \
    802-1x.ca-cert /etc/NetworkManager/certs/iitb-ca.pem 802-1x.system-ca-certs no \
    802-1x.password-flags 0
  nmcli --ask connection up "$ssid"   # prompts for the LDAP password once
done
```
In Noctalia's sign-in dialog: PEAP, MSCHAPv2, identity = bare LDAP id, password, CA
certificate path `/etc/NetworkManager/certs/iitb-ca.pem`. The server domain suffix can
stay blank (verified working 2026-11-07).

## Notes
- **Noctalia deletes a Wi-Fi profile when a connection fails** (seen twice in the
  NetworkManager audit log). Do the first connect with `nmcli --ask`, not from the
  Noctalia menu, so a wrong password doesn't wipe the profile settings.
- The server first offers PEAP (EAP type 25). An older TTLS profile also got through
  the TLS step, but PEAP/MSCHAPv2 is the setup that worked.
- **Getting the CA:** no public download was found (guessed CC URLs returned 404, and
  IITB isn't in eduroam CAT). It was captured from a live login with
  [`grab-iitb-ca.sh`](grab-iitb-ca.sh) (run with sudo: it watches `wpa_supplicant`'s
  D-Bus `Certification` signal, which only root can see, while switching SSIDs to force
  a full login, then saves the depth-1 cert). The script refuses to save unless the
  SHA-256 of the DER cert is
  `e10803508e2c92f1ca1ac5e7c5fc7951cab14ecf731994df6e7555ffffbb71c9`. The cert
  expires 2029-12-06. When IITB rotates it, logins fail with
  `CTRL-EVENT-EAP-TLS-CERT-ERROR`; check the new hash in the journal and re-run the
  script with the new value.
- The CA is deliberately **not** added to the system trust store, so browsers don't
  trust it. Only these two profiles use it.
- Set up first (same day) without the CA, using only `domain-suffix-match`; the CA was
  added once captured.
- **Misdiagnosis, corrected:** one failed attempt showed `EAP-TLV: TLV Result - Failure`
  (the server rejected the login itself). It was blamed on the bare LDAP id missing
  `@iitb.ac.in`, but the bare id works fine with the CA set. That failure was most
  likely a mistyped password. Either identity form works.
- Debug with `journalctl -u wpa_supplicant -n 40`. `CTRL-EVENT-EAP-TLS-CERT-ERROR`
  means a certificate problem; `EAP-TLV: TLV Result - Failure` means the username or
  password was rejected.
