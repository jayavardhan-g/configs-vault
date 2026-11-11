# Home server / NAS (the spare CSE-department desktop)

**Date:** 2026-10-04
**Category:** homeserver
**Machine:** a separate desktop, not the laptop — Gigabyte H97M-D3H, i7-4790K (iGPU only),

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Limine]] · [[Cloudflare WARP]] · [[Tailscale]] · [[Home server]] · [[SSH]] · [[NetworkManager]] · [[qBittorrent]]
<!-- graph:end -->

8 GB DDR3, one ~460 GB btrfs disk, wired ethernet `enp2s0`, CachyOS (Hyprland installed but
boots headless)
**Files touched** (all on the server; copies under [`files/`](files/)):
- `/usr/local/bin/net-watchdog` → [`files/usr/local/bin/net-watchdog`](files/usr/local/bin/net-watchdog)
- `/etc/systemd/system/net-watchdog.service` + `.timer` → [`files/etc/systemd/system/`](files/etc/systemd/system/)
- `/usr/local/bin/funnel-watchdog` → [`files/usr/local/bin/funnel-watchdog`](files/usr/local/bin/funnel-watchdog)
- `/etc/systemd/system/funnel-watchdog-boot.service`, `funnel-watchdog.service` + `.timer` → [`files/etc/systemd/system/`](files/etc/systemd/system/)
- `/etc/systemd/logind.conf.d/nas.conf` → [`files/etc/systemd/logind.conf.d/nas.conf`](files/etc/systemd/logind.conf.d/nas.conf)
- `/etc/ssh/sshd_config.d/10-key-only.conf` → [`files/etc/ssh/sshd_config.d/10-key-only.conf`](files/etc/ssh/sshd_config.d/10-key-only.conf)
- `/etc/default/limine` → [`files/etc/default/limine`](files/etc/default/limine) (root UUID redacted)
- `/etc/NetworkManager/conf.d/dns.conf` → [`files/etc/NetworkManager/conf.d/dns.conf`](files/etc/NetworkManager/conf.d/dns.conf)
- `/etc/samba/smb.conf` → [`files/etc/samba/smb.conf`](files/etc/samba/smb.conf) (username redacted)
- `/usr/local/bin/warp-tailscale-exclude` → [`files/usr/local/bin/warp-tailscale-exclude`](files/usr/local/bin/warp-tailscale-exclude)
- `/etc/systemd/system/warp-tailscale-exclude.service` + `.timer` → [`files/etc/systemd/system/`](files/etc/systemd/system/)
- `/etc/sysctl.d/90-freeze-reboot.conf` → [`files/etc/sysctl.d/90-freeze-reboot.conf`](files/etc/sysctl.d/90-freeze-reboot.conf) (Phase 12)
- `/etc/systemd/system.conf.d/watchdog.conf` → [`files/etc/systemd/system.conf.d/watchdog.conf`](files/etc/systemd/system.conf.d/watchdog.conf) (Phase 12)
- `/etc/udev/rules.d/60-watchdog-oc.rules` → [`files/etc/udev/rules.d/60-watchdog-oc.rules`](files/etc/udev/rules.d/60-watchdog-oc.rules) (Phase 12)
- `~/.config/qBittorrent/qBittorrent.conf` — **not stored** (holds the WebUI password hash); relevant keys listed in Phase 10
- `/etc/systemd/system/qbittorrent-nox@.service.d/warp-lockdown.conf` — **removed** 2026-10-29 (Phase 10); old copy in git history

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
| 23251 tcp+udp | qBittorrent peers | bound to `CloudflareWARP` only (no port forwarding) |

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
which resetting the NIC can't fix. **No default gateway at all** → if the cable has a link,
`nmcli device connect enp2s0` (since Phase 11, 2026-11-07; before that it only logged
"skipping check" — see Notes, router swap).

Stable address: DHCP reservation on the router (TP-Link: Advanced → Network → DHCP Server →
Address Reservation) for the server's MAC. **Not set up yet** (as of 2026-11-07): the
address has moved `.102` → `.103` (2026-11-05 boot) → `.104` (2026-11-07, new router).
Nothing depends on it (`moviesshare`, the laptop's NAS mount and SSH all use the
Tailscale name); the firewall rules use the whole `<lan-subnet>`.

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
LTS kernel as the default boot entry (CachyOS uses `limine-entry-tool`, driven by
`/etc/default/limine`). Done by `~/nas-setup/phase3c-pin-kernel.sh`, which backs the file
up, sets this line and regenerates the entries:
```
BOOT_ORDER="*lts, *, *fallback, Snapshots"
```
```bash
sudo limine-entry-tool
uname -r          # after a reboot: ...-cachyos-lts
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
around it. **WARP mode and qBittorrent's network settings are in Phase 10** (since
2026-10-29: full tunnel + interface binding, as on the laptop). The original proxy-mode
setup is described in Notes.
```bash
sudo pacman -S cloudflare-warp-bin      # cachyos repo
sudo systemctl enable --now warp-svc
warp-cli --accept-tos registration new
warp-cli --accept-tos connect           # "Always On" — reconnects by itself after reboot

sudo pacman -S qbittorrent-nox
sudo mkdir -p /srv/nas/downloads && sudo chown <user>:<user> /srv/nas/downloads
sudo ufw allow from <lan-subnet> to any port 8080 proto tcp comment 'qBittorrent WebUI LAN'
sudo ufw allow in on tailscale0 to any port 8080 proto tcp comment 'qBittorrent WebUI TS'
sudo systemctl enable --now qbittorrent-nox@<user>
```
WebUI `http://<nas-lan-ip>:8080`. First login uses `admin` + a temporary password printed
once in `journalctl -u qbittorrent-nox@<user>`; changed immediately. Downloads → default
save path `/srv/nas/downloads`. Everything network-related: Phase 10.

### Phase 8 — handover check
**Reboot test (passed 2026-10-04):** after `sudo reboot`, with no manual steps: headless
`multi-user.target`, `systemctl --failed` empty, and `net-watchdog.timer`, `sshd`,
`tailscaled`, `smb`, `jellyfin`, `qbittorrent-nox@<user>`, `warp-svc` all active. Funnel and
WARP resumed on their own.

**Internet-outage test (passed 2026-10-04)** — scripts in `~/nas-setup/` on the server
(copies: [`files/nas-setup/`](files/nas-setup/)):
```bash
sudo bash ~/nas-setup/phase8-simulate-outage.sh     # block everything outside the LAN
journalctl -t net-watchdog -f                       # expect "reachable but internet is NOT", no reset
sudo bash ~/nas-setup/phase8-restore-internet.sh    # delete the TEST rules
```
Simulate adds three `TEST:` ufw rules — deny out first, then allow out to `<lan-subnet>` and
allow out on `lo` above it. Restore lists and deletes every `TEST:` rule (highest number
first) and reloads ufw. While blocked, SSH/Samba/Jellyfin kept working from the LAN; after
restoring, Tailscale and WARP reconnected within seconds by themselves. Not meant to stay
applied — rerun only when testing.

### Phase 9 — public link survives reboots (2026-10-19)
After a reboot the Funnel setting survives but isn't re-announced to Tailscale, so the
public name disappears (see Notes in [[homeserver-toggles]]). Fix installed by
`~/nas-setup/phase9-funnel-watchdog.sh` (copy:
[`files/nas-setup/phase9-funnel-watchdog.sh`](files/nas-setup/phase9-funnel-watchdog.sh)),
which writes the script and units, enables them, and does one test run:
```bash
sudo bash ~/nas-setup/phase9-funnel-watchdog.sh
journalctl -t funnel-watchdog        # what it has done
```
- `/usr/local/bin/funnel-watchdog` does nothing unless the saved serve config says
  "Funnel on" (`moviesshare start` sets it, `stop` clears it, it survives reboots). It
  never turns Funnel on by itself.
- `funnel-watchdog-boot.service` (enabled, after `tailscaled` + `network-online`): runs it
  with `--boot`, which waits up to 2 min for Tailscale to connect, then always re-toggles
  (`funnel --https=443 off`, `funnel --bg 8096`) if Funnel was on.
- `funnel-watchdog.timer` (10 min after boot, then every **5 min** since Phase 10):
  re-toggles if public DNS (Cloudflare DNS-over-HTTPS, since the server's MagicDNS always
  answers) returns NXDOMAIN for the name, **or** (since Phase 10) the link itself doesn't
  answer through Tailscale's public entry, checked twice 20 s apart. If the DNS request
  itself fails (no internet, e.g. the college login expired), it does nothing.
- The port (8096) is hard-coded in the script, matching `moviesshare`.

Verified 2026-10-19: both units enabled, timer active, first timer run exited 0 with no
log line (Funnel on and the name resolving, so nothing to do). **Boot path verified
2026-11-07:** after a hard reboot at 22:25 the boot unit logged
`boot - re-announced Funnel` (22:25:41) and the public link answered 3/3 by 22:26. Also
2026-11-01: a network reconnect left Funnel stale; the timer caught it ("public link not
answering - re-announced Funnel", 19:19:00) and the link was back 30 s later.

### Phase 10 — qBittorrent follows the torrentvpn guide, like the laptop (2026-10-29)
The guide ([[qbittorrent-bound-to-warp]], rentry.org/torrentvpn) binds qBittorrent to the
VPN interface. That needs WARP as a full tunnel, which the server avoided at first (see
Notes). Installed by `~/nas-setup/phase10-warp-full-tunnel.sh` (copy:
[`files/nas-setup/phase10-warp-full-tunnel.sh`](files/nas-setup/phase10-warp-full-tunnel.sh)):
```bash
sudo bash ~/nas-setup/phase10-warp-full-tunnel.sh
sudo systemctl start warp-tailscale-exclude.timer   # the script only enabled it; fixed by hand
```
1. **Extra step, needed only because of Tailscale Funnel:** `warp-tailscale-exclude` adds
   every Tailscale relay (DERP) IPv4 from `tailscale debug derp-map`, plus whatever
   `controlplane.tailscale.com` and `log.tailscale.com` resolve to, to WARP's exclude list
   (`warp-cli tunnel ip add <ip>`, plain IPs, no `/32`). It only adds, never removes. Runs
   at setup, 3 min after boot, and daily (`warp-tailscale-exclude.timer`). The control
   servers answer from rotating addresses, so the list keeps growing a little.
2. `warp-cli --accept-tos mode tunnel_only` — WARP carries all traffic except its exclude
   list (LAN, `100.64.0.0/10`, the Tailscale addresses). `tunnel_only` = no WARP DNS, so
   MagicDNS and the router's DNS are untouched.
3. qBittorrent (stopped, config backed up to `qBittorrent.conf.bak.<epoch>`, edited, started):
   ```ini
   [BitTorrent]
   Session\Interface=CloudflareWARP
   Session\InterfaceName=CloudflareWARP
   Session\DHTEnabled=true
   Session\PeXEnabled=true
   Session\LSDEnabled=false          # true from Phase 10, set false in Phase 10b
   ExcludedFileNamesEnabled=true
   Session\ExcludedFileNames=*.lnk, *.scr, *.arj
   [Network]
   PortForwardingEnabled=false
   ```
   All `Proxy\*` keys and `Session\ProxyPeerConnections` deleted (= no proxy, the default).
4. Kernel lockdown drop-in removed — with the binding it would block every peer.
5. `funnel-watchdog` upgraded to test the real link (Phase 9).

Verified 2026-10-29: peer port `23251` (TCP+UDP, v4+v6) bound to `%CloudflareWARP` only;
WebUI on `*:8080`; `warp=on`; Tailscale netcheck UDP true, relay Bengaluru; public link
3/3 HTTP 302. **ipleak.net test passed** (2026-10-29, run by hand from the WebUI: only
Cloudflare IPs; after `warp-cli --accept-tos disconnect` on the server, no new IPs).

### Phase 10b — cleanup after Phase 10, LPD off (2026-10-29 → applied 2026-11-07)
`~/nas-setup/phase10b-cleanup-lsd-off.sh` (copy:
[`files/nas-setup/phase10b-cleanup-lsd-off.sh`](files/nas-setup/phase10b-cleanup-lsd-off.sh)):
removes `wgcf` + `wireguard-tools` (`pacman -Rns`; installed only for a WireGuard test, see
Notes), and sets `Session\LSDEnabled=false` with qBittorrent stopped. Done without sudo
beforehand: deleted the test scripts and the spare `wgcf` WARP identity
(`~/nas-setup/wgcf/`, held a private key), and `warp-cli tunnel protocol reset` (back to
MASQUE from network policy instead of a manual override).

Verified 2026-11-07: both packages gone (snapper pre/post snapshots 33/34); qBittorrent
sockets only on `%CloudflareWARP` plus WebUI `*:8080`, no `:6771`.

### Phase 11 — watchdog reconnects when there's no gateway (2026-11-07)
`~/nas-setup/phase11-watchdog-no-gateway.sh` (copy:
[`files/nas-setup/phase11-watchdog-no-gateway.sh`](files/nas-setup/phase11-watchdog-no-gateway.sh))
rewrites `/usr/local/bin/net-watchdog` (copy in `files/`, old one kept as
`net-watchdog.bak.<epoch>` on the server). New branch: no default gateway + cable link
(`/sys/class/net/enp2s0/carrier` = 1) → `nmcli device connect enp2s0`; no link → logs
"no cable link". Everything else unchanged. Why: router swap in Notes.

### Phase 12 — reboots by itself after a freeze (2026-11-11)
`~/nas-setup/phase12-freeze-reboot.sh` (copy:
[`files/nas-setup/phase12-freeze-reboot.sh`](files/nas-setup/phase12-freeze-reboot.sh)),
then reboot. Why: the 2026-11-11 freeze in Notes. Three layers:
1. **Kernel** (`/etc/sysctl.d/90-freeze-reboot.conf`): `kernel.panic = 10`,
   `panic_on_oops`, `softlockup_panic`, `hardlockup_panic` = 1. Was `panic = 0` (hang forever).
2. **Cmdline**: dropped CachyOS's default `nowatchdog` from `KERNEL_CMDLINE` in
   `/etc/default/limine` (backup `.bak.<epoch>`), then `limine-update`, so the soft-lockup
   detector runs (`kernel.watchdog = 1`). Old snapshot entries in `/boot/limine.conf` still
   carry `nowatchdog`; harmless. `kernel.nmi_watchdog` stays 0 (CachyOS sysctl), so
   hard lockups are left to layer 3.
3. **Hardware watchdog**: systemd pings `intel_oc_wdt` (`RuntimeWatchdogSec=30s`,
   `RebootWatchdogSec=10min`, `WatchdogDevice=/dev/watchdog-oc`; the udev rule gives it a
   stable name because `watchdogN` depends on load order, `iamt_wdt` is the other one).
   **`iTCO_wdt` can't be used:** CachyOS blacklists it, and loading it by name fails with
   "unable to reset NO_REBOOT flag, device disabled by hardware/BIOS". `iamt_wdt` (AMT) isn't
   used either.

Tested 2026-11-11 with
[`files/nas-setup/phase12-test-hw-watchdog.sh`](files/nas-setup/phase12-test-hw-watchdog.sh)
(sets `kernel.panic=0` for that boot, then `echo c > /proc/sysrq-trigger`): crash at
22:01:21, next boot 22:02:13, no button pressed, so the hardware watchdog does reset this
board (~30 s + ~20 s POST). Check: `journalctl -b -t systemd | grep -i "hardware watchdog"`
→ "Using hardware watchdog /dev/watchdog-oc: 'intel_oc_wdt'" + "hardware timeout of 30s".

### Quick reference
| What | LAN | Tailscale (anywhere) |
|---|---|---|
| SSH | `ssh <user>@<nas-lan-ip>` | `ssh <user>@<nas>.<tailnet>.ts.net` |
| Samba | `smb://<nas-lan-ip>/nas` | `smb://<nas>.<tailnet>.ts.net/nas` |
| Jellyfin | `http://<nas-lan-ip>:8096` | `http://<nas>.<tailnet>.ts.net:8096` |
| qBittorrent | `http://<nas-lan-ip>:8080` | `http://<nas>.<tailnet>.ts.net:8080` |

## Notes
- **LTS pin was written but not applied until 2026-10-04.** `phase3c-pin-kernel.sh` existed
  from setup but was never run: `/etc/default/limine` still had
  `BOOT_ORDER="*, *lts, *fallback, Snapshots"` (normal kernel first), though the server
  happened to be booted into LTS and the server-side README claimed it was pinned. Ran it
  on 2026-10-04 03:51; after the 03:52 reboot `uname -r` → `6.18.52-1-cachyos-lts`. Backup:
  `/etc/default/limine.bak.<epoch>`.
- **CMOS battery is dying:** after a power cut the BIOS stops at "load optimized defaults"
  and waits for a keypress, and it can also reset AC BACK. Until the CR2032 is replaced,
  the server won't reliably come back on its own. After replacing it, redo the BIOS
  settings in Phase 3. **Still not replaced as of 2026-11-07, and won't be for a while.**
  (Both boots so far, 2026-11-05 and 2026-11-07, came up on their own.)
- **Hard freeze, 2026-11-11 15:10 → manual reset 21:46.** Offline on Tailscale and
  missing from the router's list, but still powered (fans on). The previous boot's log just
  stops at 15:10:51: all normal until then (net-watchdog passing every minute, no errors,
  no kernel warnings, no shutdown lines); the router stayed up (the laptop kept getting its
  multicast queries). Not a network problem, so net-watchdog couldn't help; nothing could
  reboot it (`kernel.panic = 0`, `nowatchdog`, no hardware watchdog in use). Cause unknown;
  Phase 12 makes the next one reboot by itself. If it recurs, compare
  `journalctl -b -1 -n 50` across freezes; the RTC kept the right time, so the CMOS battery
  didn't reset settings this time.
- **Single disk, no redundancy** — never the only copy of anything important.
- **First outage test cut the server off its own router (2026-10-04).** Two bugs in the
  original scripts: `ufw insert 1` puts each rule at the top, so adding allow-lo, allow-LAN,
  then deny left the **deny first**, blocking the router too (the watchdog then reset
  `enp2s0` every minute — correctly, since the router really was unreachable). And the
  restore script's `grep -oP '^\[\K[0-9]+'` never matched, because `ufw status numbered`
  pads numbers (`[ 1]`), so it deleted nothing. The stored versions add the deny first and
  parse `^\[\s*\K[0-9]+`; quickest manual cleanup is deleting by rule text
  (`sudo ufw delete deny out to any`, etc.), which also removes the IPv6 copies.
  Known quirk left in: with `set -euo pipefail`, restore exits silently (no "already clean"
  message) when there are no TEST rules, because the failing `grep` aborts the script.
  Harmless. A longer variant with a 10-minute auto-restore and a health check was written
  from the laptop session and replaced by these; it lives in git history.
- **2026-10-04 → 2026-10-29: WARP was a SOCKS5 proxy, not a tunnel** (superseded by
  Phase 10). Setup was `warp-cli mode proxy` + `proxy port 40000`; qBittorrent Connection →
  Proxy SOCKS5 `127.0.0.1:40000` with "Use proxy for peer connections"; DHT, PeX and LPD off;
  plus a `qbittorrent-nox@.service.d/warp-lockdown.conf` drop-in (`IPAddressDeny=any`,
  allowing only loopback, the LAN and `100.64.0.0/10`). Chosen so WARP wouldn't become the
  default route and disturb Tailscale. **Dropped because it starved torrents of peers:**
  WARP's proxy answers SOCKS5 `UDP ASSOCIATE` with code `07` (command not supported), so UDP
  trackers, DHT and uTP could never work; qBittorrent logged "SOCKS5 proxy error … End of
  file" about every 2 min; and DHT/PeX had to stay off because their UDP would bypass the
  proxy with the real IP.
- **WARP full tunnel without the Tailscale exclusions breaks the public link**
  (2026-10-28 test): Tailscale lost its UDP and relay probes, the public link answered
  once, then failed TLS (`curl` exit 35) from every network. It also stayed broken after
  switching back to proxy mode, until Funnel was re-announced. With the exclusions in place
  first (2026-10-29 test), the link survived the switch to full tunnel, a WARP
  reconnect, and the switch back — no re-announce needed. So always run
  `warp-tailscale-exclude` **before** `warp-cli mode tunnel_only`.
- WARP's proxy mode only supports MASQUE: `warp-cli tunnel protocol set WireGuard` in
  proxy mode leaves it disconnected (`Proxy mode only supports MASQUE`). Reset with
  `tunnel protocol set MASQUE` + `connect`.
- **LPD listens on all interfaces** (`*:6771`), not just `CloudflareWARP`: it's a
  LAN-multicast feature, so it can't reach the internet, but it announces your torrents to
  other devices on the home network. Left at the guide's default (on) in Phase 10, then
  **turned off** (Phase 10b) to match the laptop.
- **WireGuard test (2026-10-28):** before settling on the full tunnel, `wgcf` + a throwaway
  network namespace showed WARP's plain WireGuard *does* get through the campus network,
  on port **500** (2408 didn't answer). Not used; packages removed in Phase 10b. Useful if
  qBittorrent ever needs its own isolated tunnel again.
- **`warp-tailscale-exclude` adding an address makes WARP reconnect** ("Reconnecting on
  settings change"). Harmless normally (seconds), but during a campus-portal logout it
  drops WARP's still-working tunnel for good (2026-11-06, 11:44).
- **Campus portal logout, 2026-11-06 — the NAS was not idle.** The home router sits on
  the campus network, whose portal logs out after an hour with no internet use. The NAS
  was suspected of going quiet, but its logs show otherwise: WARP reported tunnel health
  every 15 s all night (traffic flowing, 3 ms, no loss). At **01:14** new name lookups and
  connections suddenly failed (net-watchdog: "Gateway … reachable but internet is NOT"
  every minute) while the already-open WARP tunnel kept working until 11:44. That pattern
  fits the portal ending the session (session limit or a nightly cut-off) and blocking only
  new traffic, not inactivity. **Auto-login isn't possible:** the portal signs in through
  `sso.iitb.ac.in` (username, password and a 2FA code), then "login as \<user\>" on
  `internet.iitb.ac.in` reuses that SSO session. **After signing in again, the NAS recovers
  by itself** (checked 2026-11-06 ~12:10): WARP and Tailscale reconnect, and the
  funnel-watchdog re-announces the public link within 5 min if needed.
- **Router swap, 2026-11-07 — NAS stuck offline until a hard reboot.** The home router
  was replaced (new one: WAN `10.12.20.x` on campus, LAN still `192.168.0.0/24`, so the
  firewall rules still fit and no new portal sign-in was needed). The NAS lost its address
  (watchdog: "No default gateway found, skipping check" from 22:14). At 22:20:35 the new
  router's link came up ("carrier: link connected"), but NetworkManager stayed
  `disconnected` and never asked for an address, even though `autoconnect=yes`,
  `autoconnect-retries=0` and `dhcp-timeout=infinity` were all still set; the router's
  DHCP client list didn't show it. The old watchdog just skipped "no gateway", so only the
  hard reboot at 22:25 fixed it (new address `.104`). Phase 11 makes the watchdog handle
  that case. Why NetworkManager got stuck is unknown: its log for that boot only starts
  at 22:20 (earlier lines weren't kept). Wiring: campus wall cable → router **WAN**, NAS →
  **LAN1** (LAN2 for the laptop or free).
- Pausing WARP (`warp-cli disconnect`) during the *first* `tailscale up` on a machine that
  has both avoids a bootstrap clash.
- WARP has no port forwarding: weaker seeding. Cloudflare still sees the real IP; WARP
  only hides it from swarm peers.
- **Redacted / not stored:** usernames, LAN IP, router MAC, Tailscale IPs and tailnet name
  are placeholders. `qBittorrent.conf` isn't copied because it contains the WebUI password
  hash. Jellyfin's settings live in its own database, not a config file, so they're
  described rather than copied.
- `/boot/limine.conf` is root-only and generated by `limine-entry-tool`, so it isn't
  stored; `/etc/default/limine` is the input that matters.
