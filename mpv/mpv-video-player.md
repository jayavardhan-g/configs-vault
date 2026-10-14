# mpv video player

**Date:** 2026-09-14 (updated 2026-10-15)
**Category:** mpv
**Files touched:** `~/.config/mpv/mpv.conf`, `~/.config/mpv/input.conf` (copies: `mpv/files/.config/mpv/`), `~/.config/mpv/scripts/uosc/`, `~/.config/mpv/scripts/thumbfast.lua`, `~/.config/mpv/scripts/autoload.lua`, `~/.config/mpv/scripts/memo.lua`, `~/.config/mpv/scripts/hide-idle-text.lua`, `~/.config/mpv/script-opts/uosc.conf`, `~/.config/mpv/script-opts/autoload.conf` (copies in `files/`), `~/.config/mpv/fonts/`

<!-- graph:begin -->
**Graph:** [[mpv]]
<!-- graph:end -->

## What
Installed `mpv` as the local video player — no player was installed by default. Since 2026-10-15 it is customised with the uosc skin, vim-style keybinds and a few scripts (sections below).

## Why
Needed something to play video files; picked mpv over VLC/Celluloid for being minimal
and keyboard-driven, matching the rest of this setup (tiling WM, vim-style binds).

## Change
```bash
sudo pacman -S mpv
```
Installs clean from the official CachyOS repos (`cachyos-extra-v3`) — no AUR needed.

## Skin: uosc + thumbfast (2026-10-15)
Replaced the stock OSC with **uosc** 5.13.0 (modern controls, track/playlist menus) plus
**thumbfast** (seekbar thumbnail previews). Neither is in the Arch/CachyOS repos and no AUR
helper is installed, so they are unpacked by hand. mpv.conf disables the stock OSC:
```
osc=no
osd-bar=no
border=no
```
Install:
```bash
cd $(mktemp -d)
curl -sLO https://github.com/tomasklaen/uosc/releases/download/5.13.0/uosc.zip
unzip -o uosc.zip -d ~/.config/mpv          # scripts/uosc, fonts/
chmod +x ~/.config/mpv/scripts/uosc/bin/ziggy-linux
curl -sL -o ~/.config/mpv/scripts/thumbfast.lua \
  https://raw.githubusercontent.com/po5/thumbfast/0f711de3138c9bd6718209d819ac54022c23ded2/thumbfast.lua
```
Update by re-running with a newer release tag. uosc settings live in `script-opts/uosc.conf` (see below); the vendored
uosc tree is not copied into `files/` (8 MB release, reproducible from the URL above).

Also removed the unused VLC plugin tree (`vlc-plugins-all` and its dependencies; the `vlc`
player itself was never installed): `sudo pacman -Rns vlc-plugins-all`.

## Defaults and extra scripts (2026-10-15)
Final `mpv.conf` is stored in `mpv/files/.config/mpv/mpv.conf`:
```
osc=no
osd-bar=no
border=no
save-position-on-quit=yes   # resume where you left off; quit with Q to save
keep-open=yes
volume-max=150
vo=gpu-next
hwdec=auto-safe
screenshot-directory=~/Pictures      # same folder satty saves to
screenshot-template=mpv-%F-%P
```
Scripts (plain files in `~/.config/mpv/scripts/`):
```bash
curl -sL -o ~/.config/mpv/scripts/autoload.lua \
  https://raw.githubusercontent.com/mpv-player/mpv/v0.41.0/TOOLS/lua/autoload.lua   # folder -> playlist
curl -sL -o ~/.config/mpv/scripts/memo.lua \
  https://raw.githubusercontent.com/po5/memo/e0624611438b2e19ef4b7e24f53461c9d0304b07/memo.lua  # watch history
sudo pacman -S mpv-mpris   # MPRIS: media keys / Noctalia widget
```
memo records history but has no keybind yet (menu command: `script-binding memo-history`).

Idle screen: uosc shows "Drop files or URLs to play here" when nothing is loaded and has no
option to hide it. `scripts/hide-idle-text.lua` (stored in `files/`) tells uosc to hide it
(`disable-elements idle_indicator`) and, if mpv started idle, opens uosc's file browser.
`script-opts/uosc.conf` makes that browser (and "Open file") start in the NAS media folder:
```
default_directory=/mnt/nas/media
```
(`/mnt/nas` is the CIFS automount from fstab.) If `/mnt/nas/media` isn't reachable within 5s the
script overrides it to `~/Videos` at runtime.

`script-opts/autoload.conf` limits autoload to video files only:
```
images=no
audio=no
videos=yes
```

YouTube/URL playback needs `yt-dlp`; deliberately NOT installed (2026-10-15), so links fail to load. `mpv-mpris` (media keys/Noctalia widget) was installed with
`sudo pacman -S mpv-mpris`.

## Keybinds (2026-10-15)
vim-style, rewritten from scratch the same day; final file in `mpv/files/.config/mpv/input.conf`:
```
h/l seek -5/+5          H/L seek -30/+30        Ctrl+h/l exact seek -1/+1
k/j volume +5/-5        g/G playlist prev/next
, . frame back/step     [ ] speed x0.9/x1.1     { } speed x0.5/x2     BS reset speed
0..9 jump to 0..90%     SPACE pause  f fullscreen  m mute  q quit  Q quit-watch-later
: open console          MBTN_RIGHT / TAB uosc menu
```
Overrides mpv defaults: `j`/`l`/`L` (subtitle cycle, A-B loop, file loop), `H`, `g`/`G`, `0`-`9` (volume `9`/`0` and picture contrast/brightness/gamma/saturation `1`-`8`, now unbound). Arrow keys keep their defaults. Subtitle cycling remains in the uosc menu. Earlier version had `H`/`L` as playlist prev/next; moved to `g`/`G` to free `H`/`L` for 30s seeks.

## Notes
- Further mpv config/script changes go in this entry rather than a new one.
