# Home server / NAS (the spare CSE-department desktop)

**Date:** 2026-10-04
**Category:** homeserver
**Machine:** a separate desktop, not the laptop — Gigabyte H97M-D3H, i7-4790K (iGPU only),
8 GB DDR3, one ~460 GB btrfs disk, wired ethernet `enp2s0`, CachyOS (Hyprland installed but
boots headless)
**Files touched** (all on the server; copies under [`files/`](files/)):
- `/usr/local/bin/net-watchdog` → [`files/usr/local/bin/net-watchdog`](files/usr/local/bin/net-watchdog)
- `/etc/systemd/system/net-watchdog.service` + `.timer` → [`files/etc/systemd/system/`](files/etc/systemd/system/)
- `/etc/systemd/logind.conf.d/nas.conf` → [`files/etc/systemd/logind.conf.d/nas.conf`](files/etc/systemd/logind.conf.d/nas.conf)
- `/etc/ssh/sshd_config.d/10-key-only.conf` → [`files/etc/ssh/sshd_config.d/10-key-only.conf`](files/etc/ssh/sshd_config.d/10-key-only.conf)
- `/etc/default/limine` → [`files/etc/default/limine`](files/etc/default/limine) (root UUID redacted)
- `/etc/NetworkManager/conf.d/dns.conf` → [`files/etc/NetworkManager/conf.d/dns.conf`](files/etc/NetworkManager/conf.d/dns.conf)
- `/etc/samba/smb.conf` → [`files/etc/samba/smb.conf`](files/etc/samba/smb.conf) (username redacted)
- `/etc/systemd/system/qbittorrent-nox@.service.d/warp-lockdown.conf` → [`files/etc/systemd/system/qbittorrent-nox@.service.d/warp-lockdown.conf`](files/etc/systemd/system/qbittorrent-nox@.service.d/warp-lockdown.conf)
- `~/.config/qBittorrent/qBittorrent.conf` — **not stored** (holds the WebUI password hash); relevant keys listed in Phase 7b

How to switch each feature off/on, and how to share/stop sharing a movie:
[[homeserver-toggles]] (`homeserver-toggles.md`).

## What
Turned the spare desktop into an always-on, headless home server: ethernet that
reconnects by itself, no sleep, key-only SSH, Tailscale for remote access (plus Funnel for
public sharing), a Samba share, Jellyfin, and qBittorrent-nox whose torrent traffic goes
only through Cloudflare WARP.

## Why
The desktop was otherwise unused (its DDR3 RAM can't go in the laptop). Wanted one box that
holds files and downloads, streams media to the laptop/phone, and keeps torrenting off the
laptop — reachable from anywhere, not just home.

## Change

Placeholders: `<user>` = login user, `<nas-lan-ip>` = the server's LAN IP,
`<nas>.<tailnet>.ts.net` = its Tailscale MagicDNS name, `<lan-subnet>` = `192.168.0.0/24`
on this router. Firewall is `ufw` (was already active); every rule below was added with a
`comment`, so `sudo ufw status verbose` shows what each is for.

### Ports
| Port | Service | Open to |
|---|---|---|
| 22/tcp | SSH | LAN |
| 41641/udp | Tailscale direct connections | anywhere |
| 445/tcp | Samba | LAN + Tailscale |
| 8096/tcp | Jellyfin | LAN + Tailscale (+ public on 443 while Funnel is on) |
| 8080/tcp | qBittorrent WebUI | LAN + Tailscale |
| 40000/tcp | WARP local SOCKS5 proxy | loopback only |

### Phase 1 — baseline
```bash
sudo pacman -Syu        # base-devel and git were already present
```

### Phase 2 — ethernet that always reconnects
```bash
sudo nmcli connection modify "Wired connection 1" connection.autoconnect yes
sudo nmcli connection modify "Wired connection 1" connection.autoconnect-retries 0   # retry forever
sudo nmcli connection modify "Wired connection 1" ipv4.dhcp-timeout infinity
sudo nmcli connection up "Wired connection 1"
```
Watchdog (copy the three files from `files/`, script mode 755):
```bash
sudo install -m755 files/usr/local/bin/net-watchdog /usr/local/bin/
sudo cp files/etc/systemd/system/net-watchdog.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now net-watchdog.timer
journalctl -t net-watchdog          # its log
```
The script pings the router every minute. Router unreachable → resets `enp2s0`. Router
reachable but both archlinux.org and cloudflare.com unreachable → only logs it, because
that means the router's upstream (the college network's captive-portal/LDAP login) expired,
which resetting the NIC can't fix.

Stable address: DHCP reservation on the router (TP-Link: Advanced → Network → DHCP Server →
Address Reservation) for the server's MAC.

### Phase 3 — always on, headless
```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
sudo mkdir -p /etc/systemd/logind.conf.d
sudo cp files/etc/systemd/logind.conf.d/nas.conf /etc/systemd/logind.conf.d/
sudo systemctl restart systemd-logind
sudo systemctl set-default multi-user.target     # boot to text console, no GUI
```
SSH, key-only:
```bash
sudo systemctl enable --now sshd
sudo ufw allow from <lan-subnet> to any port 22 proto tcp comment 'SSH LAN'
# on the laptop:
ssh-keygen -t ed25519 -C "laptop-to-nas"
ssh-copy-id <user>@<nas-lan-ip>
# back on the server, only after key login works:
sudo cp files/etc/ssh/sshd_config.d/10-key-only.conf /etc/ssh/sshd_config.d/
sudo chmod 700 ~/.ssh
sudo sshd -t && sudo systemctl restart sshd
```
LTS kernel, intended as the default boot entry (CachyOS uses `limine-entry-tool`, driven
by `/etc/default/limine`) — **see Notes, the saved file doesn't currently say this**:
```
BOOT_ORDER="*lts, *, *fallback, Snapshots"
```
```bash
sudo limine-entry-tool
```
BIOS (Power menu, done by hand): **AC BACK → Always On** (Gigabyte's name for "restore on
AC power loss"). ErP Disabled; Power On by Keyboard/Mouse/Password Disabled. No "Halt On"
option on this board — tested that it boots fine with no keyboard attached.

### Phase 4 — Tailscale
```bash
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
sudo ufw allow 41641/udp comment 'Tailscale'
sudo tailscale up                       # open the printed URL, approve the device
sudo tailscale set --operator=<user>    # manage serve/funnel without sudo
```
MagicDNS was broken by NetworkManager and systemd-resolved being wired together wrong
(Tailscale health warning). Fix:
```bash
sudo cp files/etc/NetworkManager/conf.d/dns.conf /etc/NetworkManager/conf.d/
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sudo systemctl restart systemd-resolved NetworkManager tailscaled
```
Laptop: same three install lines. Phone: Tailscale app from the Play Store, same account.

### Phase 5 — Samba
```bash
sudo pacman -S samba
sudo mkdir -p /srv/nas && sudo chown <user>:<user> /srv/nas && sudo chmod 750 /srv/nas
sudo cp files/etc/samba/smb.conf /etc/samba/smb.conf     # set valid users = <user>
sudo systemctl enable --now smb
sudo ufw allow from <lan-subnet> to any port 445 proto tcp comment 'SMB LAN'
sudo ufw allow in on tailscale0 to any port 445 proto tcp comment 'SMB Tailscale'
sudo smbpasswd -a <user>        # Samba password typed interactively, not stored
```
Laptop file manager: `smb://<nas>.<tailnet>.ts.net/nas` (works anywhere) or
`smb://<nas-lan-ip>/nas`. Permanent mount — laptop `/etc/fstab`:
```
//<nas>.<tailnet>.ts.net/nas /mnt/nas cifs credentials=/home/<you>/.smbcredentials,uid=1000,gid=1000,iocharset=utf8,_netdev,nofail 0 0
```
with `~/.smbcredentials` (chmod 600) holding `username=<user>` and `password=<password>`.
`_netdev,nofail` keeps the laptop's boot from hanging when the server is unreachable.
Android: any SMB file manager (Solid Explorer, Cx File Explorer), share `nas`.

### Phase 6 — Syncthing (set up, then removed)
Removed: Samba already covered the real need (browse files and downloads from the laptop).
To bring it back: `pacman -S syncthing`, `loginctl enable-linger <user>`,
`systemctl --user enable --now syncthing`; GUI on `127.0.0.1:8384`, reached with
`ssh -L 8384:127.0.0.1:8384 <user>@<nas>` (write `127.0.0.1`, not `localhost` — localhost
also resolves to IPv6 and the GUI only listens on IPv4).

### Phase 7a — Jellyfin
```bash
sudo pacman -S jellyfin-server jellyfin-web
sudo mkdir -p /srv/nas/media && sudo chown <user>:<user> /srv/nas/media && sudo chmod 750 /srv/nas/media
sudo usermod -aG <user> jellyfin        # lets the jellyfin service read the 750 folders
sudo ufw allow from <lan-subnet> to any port 8096 proto tcp comment 'Jellyfin LAN'
sudo ufw allow in on tailscale0 to any port 8096 proto tcp comment 'Jellyfin TS'
sudo systemctl enable --now jellyfin
```
First-run wizard at `http://<nas-lan-ip>:8096`: admin account, libraries `/srv/nas/media`
and `/srv/nas/downloads` (so finished torrents show up without moving them).

### Phase 7b — qBittorrent-nox through Cloudflare WARP
The college network blocks/throttles BitTorrent with DPI; WARP's encrypted tunnel gets
around it. WARP runs as a **local SOCKS5 proxy**, not a system-wide tunnel, so only
qBittorrent uses it and Tailscale's routing is left alone.
```bash
sudo pacman -S cloudflare-warp-bin      # cachyos repo
sudo systemctl enable --now warp-svc
warp-cli --accept-tos registration new
warp-cli --accept-tos mode proxy
warp-cli --accept-tos proxy port 40000
warp-cli --accept-tos connect           # "Always On" — reconnects by itself after reboot

sudo pacman -S qbittorrent-nox
sudo mkdir -p /srv/nas/downloads && sudo chown <user>:<user> /srv/nas/downloads
sudo ufw allow from <lan-subnet> to any port 8080 proto tcp comment 'qBittorrent WebUI LAN'
sudo ufw allow in on tailscale0 to any port 8080 proto tcp comment 'qBittorrent WebUI TS'
sudo systemctl enable --now qbittorrent-nox@<user>
```
WebUI `http://<nas-lan-ip>:8080`. First login uses `admin` + a temporary password printed
once in `journalctl -u qbittorrent-nox@<user>`; changed immediately. Settings:
- Connection → Proxy: SOCKS5, `127.0.0.1`, port `40000`, "Use proxy for peer connections" on.
- Connection → UPnP/NAT-PMP off (WARP has no port forwarding).
- Downloads → default save path `/srv/nas/downloads`.
- BitTorrent → DHT, PeX and Local Peer Discovery off (DHT/uTP are UDP and skip SOCKS5).

Resulting `qBittorrent.conf` keys:
```ini
[BitTorrent]
Session\DHTEnabled=false
Session\PeXEnabled=false
Session\LSDEnabled=false
Session\DefaultSavePath=/srv/nas/downloads
Session\ProxyPeerConnections=true
[Network]
PortForwardingEnabled=false
Proxy\Type=SOCKS5
Proxy\IP=127.0.0.1
Proxy\Profiles\BitTorrent=true
```
Kernel-level lockdown so nothing can leak even if a setting is wrong (this qBittorrent build
has no "disable connections not supported by proxies" option):
```bash
sudo mkdir -p "/etc/systemd/system/qbittorrent-nox@.service.d"
sudo cp "files/etc/systemd/system/qbittorrent-nox@.service.d/warp-lockdown.conf" "/etc/systemd/system/qbittorrent-nox@.service.d/"
sudo systemctl daemon-reload && sudo systemctl restart qbittorrent-nox@<user>
```
It denies everything except loopback (the WARP proxy), the LAN and the Tailscale range.

Verified 2026-10-04: ipleak.net torrent test showed only Cloudflare IPs; after
`warp-cli disconnect` no new IP appeared at all (connections just fail), so it fails closed.

### Phase 8 — handover check
After a reboot: `systemctl --failed` empty, `systemctl is-active net-watchdog.timer` →
`active`, `warp-cli status` → Connected.

**Internet-outage test** — scripts in `~/nas-setup/` on the server (copies:
[`files/nas-setup/`](files/nas-setup/)):
```bash
sudo bash ~/nas-setup/phase8-simulate-outage.sh     # block everything outside the LAN
journalctl -t net-watchdog -f                       # expect "reachable but internet is NOT", no reset
sudo bash ~/nas-setup/phase8-restore-internet.sh    # undo + network up + health check
```
The simulate script adds three `TEST:` ufw rules (deny out; allow out to the LAN; allow out
on lo), checks the router is still reachable and the internet isn't, and arms
`phase8-auto-restore` (`systemd-run --on-active=10min`) so it undoes itself even if you
lose access. The restore script cancels that timer, deletes every `TEST:` rule, brings
`Wired connection 1` up, restarts tailscaled and prints Router / Internet / Tailscale /
WARP / leftover-rules status. Safe to rerun.

### Quick reference
| What | LAN | Tailscale (anywhere) |
|---|---|---|
| SSH | `ssh <user>@<nas-lan-ip>` | `ssh <user>@<nas>.<tailnet>.ts.net` |
| Samba | `smb://<nas-lan-ip>/nas` | `smb://<nas>.<tailnet>.ts.net/nas` |
| Jellyfin | `http://<nas-lan-ip>:8096` | `http://<nas>.<tailnet>.ts.net:8096` |
| qBittorrent | `http://<nas-lan-ip>:8080` | `http://<nas>.<tailnet>.ts.net:8080` |

## Notes
- **LTS pin not saved (found 2026-10-04):** the server's `/etc/default/limine` still reads
  `BOOT_ORDER="*, *lts, *fallback, Snapshots"`, which lists the normal `linux-cachyos`
  kernel first. It was running `6.18.x-cachyos-lts` at the time, so either it was picked
  by hand at the boot menu or `limine.conf` was edited some other way. Make the edit in
  Phase 3, run `sudo limine-entry-tool`, and check `uname -r` after a reboot. The stored
  copy is the file as found, not the intended version.
- **CMOS battery is dying:** after a power cut the BIOS stops at "load optimized defaults"
  and waits for a keypress, and it can also reset AC BACK. Until the CR2032 is replaced,
  the server won't reliably come back on its own. After replacing it, redo the BIOS
  settings in Phase 3.
- **Single disk, no redundancy** — never the only copy of anything important.
- **First outage test cut the server off its own router (2026-10-04).** Two bugs in the
  original scripts: `ufw insert 1` puts each rule at the top, so adding allow-lo, allow-LAN,
  then deny left the **deny first**, blocking the router too (the watchdog then reset
  `enp2s0` every minute — correctly, since the router really was unreachable). And the
  restore script's `grep -oP '^\[\K[0-9]+'` never matched, because `ufw status numbered`
  pads numbers (`[ 1]`), so it deleted nothing. Fixed versions add the deny first and parse
  `^\[ *([0-9]+)\]`; quickest manual cleanup is deleting by rule text
  (`sudo ufw delete deny out to any`, etc.), which also removes the IPv6 copies.
- **Why WARP proxy mode here, but interface binding on the laptop**
  ([[qbittorrent-bound-to-warp]]): on the server WARP must not become the default route,
  or it can break Tailscale's control connection. Pausing WARP (`warp-cli disconnect`)
  during the *first* `tailscale up` on a machine that has both avoids a bootstrap clash.
- WARP has no port forwarding: weaker seeding. Cloudflare still sees the real IP; WARP
  only hides it from swarm peers.
- **Redacted / not stored:** usernames, LAN IP, router MAC, Tailscale IPs and tailnet name
  are placeholders. `qBittorrent.conf` isn't copied because it contains the WebUI password
  hash. Jellyfin's settings live in its own database, not a config file, so they're
  described rather than copied.
- `/boot/limine.conf` is root-only and generated by `limine-entry-tool`, so it isn't
  stored; `/etc/default/limine` is the input that matters.
