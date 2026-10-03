# Config & decisions log

Personal runbook of system/config decisions, split by scope:

- **[`cachyos/`](cachyos/README.md)** — anything specific to *this* CachyOS + Hyprland
  setup: window manager binds, workspace/layout behavior, input device quirks, and any
  fix that only exists because of Hyprland or this distro's packaging. Wouldn't apply if
  the window manager or distro changed.
- Everything else is a **portable, tool-specific config** — a real dotfile or setup
  decision that would work identically on any Linux box (or macOS, for some), regardless
  of window manager or distro. Each such tool gets its own top-level folder:

| Folder | What's in it |
|---|---|
| [`vim/`](vim/vimrc-minimal-visual-config.md) | `~/.vimrc` — minimal chrome, terminal-native colors |
| [`neovim/`](neovim/lazyvim-migration.md) | `~/.config/nvim/` — migrated to LazyVim 2026-09-15. Start at `lazyvim-migration.md`: it has the migration, fresh-machine steps, and an index of the topic files (keybindings, appearance, languages/LSP, plugin review, cheatsheet, GhostText, LeetCode). Older entries cover the pre-migration setup and Vim-side parity decisions still current |
| [`ssh/`](ssh/ssh-term-mismatch-fix.md) | `~/.ssh/config` fixes |
| [`vpn/`](vpn/fortinet-vpn-client.md) | Fortinet SSL-VPN client (`openfortivpn` + a fish function) |
| [`cloudflare-warp/`](cloudflare-warp/cloudflare-warp-client.md) | Cloudflare WARP (1.1.1.1) client — `cloudflare-warp-bin` from the cachyos repo (was a manual AUR build until 2026-10-02), `warp-svc` + `warp-cli` |
| [`qbittorrent/`](qbittorrent/qbittorrent-bound-to-warp.md) | qBittorrent bound to the `CloudflareWARP` interface (rentry torrentvpn guide), LPD off, leak-tested on ipleak.net |
| [`homeserver/`](homeserver/homeserver-setup.md) | **Separate machine, not the laptop**: the spare CSE-department desktop as a headless NAS — ethernet watchdog, key-only SSH, Tailscale + Funnel, Samba, Jellyfin, qBittorrent-nox via WARP proxy with a kernel-level leak lockdown. [`homeserver-toggles.md`](homeserver/homeserver-toggles.md) has every off/on switch and how to share/stop sharing a movie, plus the laptop's `moviesshare` fish function that toggles sharing |
| [`spotify/`](spotify/spotify-and-spotx.md) | Spotify (Flatpak) + SpotX ad-block patch |
| [`limine/`](limine/windows-dual-boot-order-and-bitlocker.md) | Limine bootloader — Windows dual-boot NVRAM order + BitLocker chainload fix |
| [`xpad/`](xpad/xpad-sticky-notes.md) | Xpad desktop sticky notes — install, `--no-new`/`--quit` flags, why `sticky` (x-apps) doesn't work here |
| [`mpv/`](mpv/mpv-video-player.md) | mpv video player — plain repo install, no player was present by default |
| [`noctalia/`](noctalia/palette-source-not-persisting.md) | Noctalia shell — wallpaper-based palette source not persisting to settings.toml |
| [`zen-browser/`](zen-browser/windows-profile-migration.md) | Zen Browser (Flatpak) — migrating profiles from a Windows install: `profiles.ini`, the in-app profile-switcher DB, and per-profile app launchers |

**Every folder above also has a `files/` subtree** holding actual copies of the real
config files each entry touches, mirroring their real path under `$HOME` (e.g.
`~/.vimrc` → `vim/files/.vimrc`, `~/.config/hypr/config/binds.lua` →
`cachyos/files/.config/hypr/config/binds.lua`) — not just described in prose, so a fresh
machine can literally overlay-copy them into place. A file containing a real secret
(a password, a private IP tied to this setup) is stored redacted with a placeholder
rather than skipped — check an entry's `Notes` if a stored file looks incomplete.

See `CLAUDE.md` for the full rules on how entries are written and — critically — how a
change gets classified into `cachyos/` vs. a tool folder, including how to split a change
that has both a portable part and a Hyprland-specific part (e.g. installing a
cross-platform tool but also wiring it into Hyprland's autostart or keybinds).

Never commit `.claude/` (session-local Claude Code settings) — see `.gitignore`.
