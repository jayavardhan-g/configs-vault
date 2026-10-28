# qBittorrent bound to the Cloudflare WARP interface

**Date:** 2026-09-25
**Category:** qbittorrent
**Files touched:** `~/.config/qBittorrent/qBittorrent.conf` (copy: [`files/.config/qBittorrent/qBittorrent.conf`](files/.config/qBittorrent/qBittorrent.conf))

<!-- graph:begin -->
**Graph:** [[Cloudflare WARP]] · [[qBittorrent]]
<!-- graph:end -->

## What
qBittorrent (repo package `qbittorrent`) is bound to the `CloudflareWARP` network
interface so all torrent traffic goes through WARP, and Local Peer Discovery is off.
Followed the guide at https://rentry.org/torrentvpn, using WARP instead of Proton VPN.

## Why
Hide the home IP from torrent swarms. Binding to the interface is the guide's critical
step: if WARP drops, qBittorrent just stalls instead of falling back to the real
connection. A kill switch only reacts after a drop, so it can leak briefly.

## Change
Prereq: WARP installed, connected and in `warp` mode. See
[[cloudflare-warp-client]] (`../cloudflare-warp/cloudflare-warp-client.md`).

```bash
sudo pacman -S qbittorrent
```

In qBittorrent, **Tools → Options**:
- **Advanced → Network interface** → `CloudflareWARP`. The interface only appears
  while WARP is connected. Find it with `ip -br addr show`, connected vs. disconnected.
- **BitTorrent** → uncheck **Enable Local Peer Discovery**.
- **Connection** → uncheck **Use UPnP / NAT-PMP port forwarding from my router**. This was
  still on at the time of writing (see Notes).

The resulting keys in `qBittorrent.conf`:
```ini
[BitTorrent]
Session\Interface=CloudflareWARP
Session\InterfaceName=CloudflareWARP
Session\LSDEnabled=false
```

## Verify
- `ss -tulpn | grep qbittorrent` shows the peer port listening only on
  `…%CloudflareWARP`, never on the Ethernet/Wi-Fi interface.
- ipleak.net → **Torrent Address detection** → add its magnet link. It should show only
  Cloudflare IPs (`104.28.x.x` / `2a09:bac5:…`), not the home IP.
- Then run `warp-cli disconnect` and refresh ipleak.net. **No new entries** should appear.
  Both checks passed on 2026-09-25, and again on 2026-10-28.
- 2026-10-28 socket check with WARP disconnected: qBittorrent had **no sockets at all**
  (none on the home addresses), and re-bound to `CloudflareWARP` on its own within ~10 s
  of `warp-cli connect`, without a restart.
- With WARP on, Tailscale still reaches LAN peers directly over the LAN
  (`tailscale ping` → `via <lan-ip>:41641`, 1 ms), because WARP's exclude list covers
  `192.168.0.0/16`. Off-LAN, Tailscale's direct UDP fails through WARP and it falls back
  to a DERP relay (slower, still works).

## Notes
- **WARP can't do port forwarding.** Other peers can't connect in to you, so you only
  reach peers who accept incoming connections. Expect slower downloads and weak seeding.
  UPnP is useless under the binding: it would only open a port on the home router,
  where qBittorrent isn't listening.
- **WARP isn't a privacy VPN.** It hides your IP from swarm peers, which is where copyright
  notices come from, but Cloudflare still sees the real IP. For heavy use, the guide's
  choice is Proton VPN (paid, with port forwarding).
- **Local Peer Discovery** (UDP 6771) announces the info hashes you're downloading to
  everyone on the home network. It isn't an internet leak, but there's no reason to
  keep it on.
- **No app-based split tunneling is needed.** WARP on Linux doesn't offer it, and the
  interface binding already keeps qBittorrent inside the tunnel.
- The stored `.conf` also holds GUI layout state. It contains no secrets, so it's
  copied as-is.
