---
type: entity
hub: "[[Network]]"
---
# NetworkManager

Wi-Fi/network connection profiles via `nmcli` (e.g. eduroam 802.1X at IITB).

**Hub:** [[Network]]
**Config:** `/etc/NetworkManager/system-connections/` (root-only, holds secrets; not copied)
**Related:** [[Noctalia]]

<!-- auto:begin -->
## Entries

- [[homeserver-setup|Home server / NAS (the spare CSE-department desktop)]]
- [[dns-via-systemd-resolved|NetworkManager hands DNS to systemd-resolved (fixes Tailscale's MagicDNS warning)]]
- [[eduroam-iitb|eduroam and IITB-Wireless-Ex at IIT Bombay (NetworkManager profiles)]]
<!-- auto:end -->
