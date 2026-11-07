# eduroam at IIT Bombay (NetworkManager profile)

**Date:** 2026-11-07
**Category:** networkmanager
**Files touched:** `/etc/NetworkManager/system-connections/eduroam.nmconnection` (created by `nmcli`; root-only and holds the password, so no copy is stored here)

<!-- graph:begin -->
**Graph:** [[NetworkManager]]
<!-- graph:end -->

## What
An `eduroam` Wi-Fi profile made with `nmcli`: PEAP + MSCHAPv2, the identity in
`<ldap>@iitb.ac.in` form, no check against the system CA store, and the server
certificate pinned to the `iitb.ac.in` domain.

## Why
Connecting from the Noctalia Wi-Fi menu kept failing. It failed in two separate ways:
1. **Certificate:** IITB's RADIUS server chains to its own private CA ("IIT Bombay
   Computer Centre Certificate Authority"). That CA isn't in the system trust store, so
   `wpa_supplicant` failed with `self-signed certificate in certificate chain`
   whenever the profile used the system CAs.
2. **Login:** once the certificate was accepted, the inner login still failed
   (`EAP-TLV: TLV Result - Failure`) when the identity was the bare LDAP id. It needs
   the realm: `<ldap>@iitb.ac.in`.

## Change
```bash
nmcli connection add type wifi con-name eduroam ssid eduroam \
  wifi-sec.key-mgmt wpa-eap 802-1x.eap peap 802-1x.phase2-auth mschapv2 \
  802-1x.identity '<ldap>@iitb.ac.in' \
  802-1x.domain-suffix-match iitb.ac.in 802-1x.system-ca-certs no \
  802-1x.password-flags 0
nmcli --ask connection up eduroam   # prompts for the LDAP password once; NM stores it
```

## Notes
- **Noctalia deletes a Wi-Fi profile when a connection fails** (seen twice in the
  NetworkManager audit log). Do the first connect with `nmcli --ask`, not from the
  Noctalia menu, so a wrong password doesn't wipe the profile settings.
- The server first offers PEAP (EAP type 25). An older TTLS profile also got through
  the TLS step, but PEAP/MSCHAPv2 is the setup that worked.
- A stronger setup would point `802-1x.ca-cert` at IITB's CA file. No public download
  was found (guessed CC URLs returned 404, and IITB isn't in eduroam CAT). The CA's
  SHA-256 hash, as `wpa_supplicant` reports it:
  `e10803508e2c92f1ca1ac5e7c5fc7951cab14ecf731994df6e7555ffffbb71c9`.
- Debug with `journalctl -u wpa_supplicant -n 40`. `CTRL-EVENT-EAP-TLS-CERT-ERROR`
  means a certificate problem; `EAP-TLV: TLV Result - Failure` means the username or
  password was rejected.
