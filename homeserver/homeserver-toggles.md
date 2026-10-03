# Home server — switching features off/on, and sharing

**Date:** 2026-10-04
**Category:** homeserver
**Files touched:** none (operating guide for [[homeserver-setup]], `homeserver-setup.md`)

## What
How to turn each part of the home server off and back on, how to share a movie with
someone outside the tailnet, and how to stop sharing.

## Why
Most features are only needed some of the time (public sharing especially). This keeps the
off-switch next to the on-switch so nothing is left running by accident.

## Change

Run these on the server: `ssh <user>@<nas>.<tailnet>.ts.net` first.
`disable --now` = stop now **and** don't start at boot. `stop` alone comes back after the
next reboot.

### Share a movie with a friend (Jellyfin + Tailscale Funnel)
Jellyfin has no "public link to one movie". The friend gets their own login and sees only
the libraries you allow.

1. (Optional) make a separate library for shared stuff, e.g. folder `/srv/nas/media/shared`
   → Dashboard → Libraries → Add Media Library. Copy the movie in there.
2. Create a user for them: Dashboard → Users → **+** → name + password. On their profile:
   - **Library access** → untick "Enable access to all libraries", tick only the shared one.
   - Leave "Allow this user to manage the server" **off**.
   - Optional: Playback → turn off "Allow media downloading".
3. Turn on Funnel (public HTTPS on port 443 → Jellyfin):
   ```bash
   tailscale funnel --bg 8096
   tailscale funnel status          # shows the public URL
   ```
4. Send them `https://<nas>.<tailnet>.ts.net` plus their username/password. They open it
   in a browser or the Jellyfin app (server address = that URL).

**Stop sharing:**
```bash
tailscale funnel --https=443 off      # public URL stops working immediately
tailscale funnel status               # should say no serve config
```
Then Dashboard → Users → their user → tick **Disable this user** (or delete it). Disabling
matters if you also share via Tailscale (below), since Funnel being off doesn't log them out
there.

**Private alternative (no public URL):** share just this machine to their Tailscale
account — Tailscale admin console → Machines → the server → **Share…**. They install
Tailscale, accept, and open `http://<nas>.<tailnet>.ts.net:8096`. Stop: admin console →
Machines → the server → Share… → revoke. Nothing is exposed to the internet this way.

### Tailscale (remote access)
| | Command |
|---|---|
| Off for now | `sudo tailscale down` |
| Back on | `sudo tailscale up` |
| Off permanently | `sudo systemctl disable --now tailscaled` |
| On permanently | `sudo systemctl enable --now tailscaled` |

`tailscale down` also cuts Funnel, Samba/Jellyfin/qBittorrent over Tailscale, and SSH via
the tailnet name. Do it from the LAN (`ssh <user>@<nas-lan-ip>`) or you lock yourself out.

### Samba (file share)
```bash
sudo systemctl disable --now smb        # off
sudo systemctl enable --now smb         # on
```
Laptop side, if `/mnt/nas` is in fstab: `nofail` means it just won't mount; no boot hang.

### Jellyfin
```bash
sudo systemctl disable --now jellyfin   # off (also kills anything shared via Funnel)
sudo systemctl enable --now jellyfin    # on
```

### qBittorrent + WARP
| Want | Do |
|---|---|
| Pause all torrents | WebUI → select all → Pause |
| Stop qBittorrent | `sudo systemctl disable --now qbittorrent-nox@<user>` |
| Start it | `sudo systemctl enable --now qbittorrent-nox@<user>` |
| Disconnect WARP | `warp-cli disconnect` — torrents stall, they don't leak |
| Reconnect WARP | `warp-cli connect` |
| Turn WARP off for good | `warp-cli disconnect && sudo systemctl disable --now warp-svc` |

**Don't remove** `/etc/systemd/system/qbittorrent-nox@.service.d/warp-lockdown.conf` unless
you've also taken qBittorrent off WARP on purpose. Without it, DHT/uTP can reach peers
directly with the real IP. To remove it anyway: delete the file, then
`sudo systemctl daemon-reload && sudo systemctl restart qbittorrent-nox@<user>`.

### Network watchdog
```bash
sudo systemctl disable --now net-watchdog.timer    # off
sudo systemctl enable --now net-watchdog.timer     # on
journalctl -t net-watchdog --since today           # what it did
```
If the log says "Gateway reachable but internet is NOT", the college portal login expired:
log in again from a browser on any device behind the same router.

### Desktop (GUI)
```bash
sudo systemctl isolate graphical.target      # GUI now (monitor attached)
sudo systemctl isolate multi-user.target     # back to headless
sudo systemctl set-default graphical.target  # boot to GUI every time
sudo systemctl set-default multi-user.target # boot headless again (current)
```

### Sleep / suspend
Currently impossible by design. To allow it again:
```bash
sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
sudo rm /etc/systemd/logind.conf.d/nas.conf && sudo systemctl restart systemd-logind
```

### SSH
- Password login back on (e.g. new laptop without the key): needs a monitor + keyboard on
  the server. `sudo rm /etc/ssh/sshd_config.d/10-key-only.conf && sudo systemctl restart sshd`,
  add the new key with `ssh-copy-id`, then put the file back.
- SSH off entirely: `sudo systemctl disable --now sshd` (only with local access available).

### Firewall rules
```bash
sudo ufw status numbered      # every rule, with its comment
sudo ufw delete <number>      # remove one (numbers shift after each delete — re-list)
```
Disabling a service doesn't need its rule removed; the port just has nothing listening.

### Kernel
Pick `linux-cachyos` or `linux-cachyos-lts` from the boot menu for one boot. Change the
default via `BOOT_ORDER` in `/etc/default/limine`, then `sudo limine-entry-tool`.

### Whole machine
```bash
sudo systemctl reboot
sudo systemctl poweroff       # it won't come back until the power button (or a power cut, with AC BACK = Always On)
```

## Notes
- Funnel was **on** when this was written (2026-10-04). Check with `tailscale funnel status`
  and turn it off when not actively sharing.
- Funnel only publishes HTTPS 443 → 8096. Port 8096 itself stays LAN + Tailscale only;
  Samba, SSH and qBittorrent are never public.
- A Jellyfin user sees every item in the libraries they're given. A separate "shared"
  library is the only way to limit them to specific movies.
