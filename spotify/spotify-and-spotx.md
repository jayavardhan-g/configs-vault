# Spotify (Flatpak, user-scope) + SpotX patch

**Date:** 2026-08-29
**Category:** system
**Files touched:** none under `~/.config/hypr` — Flatpak app data at

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[CachyOS]] · [[Spotify]]
<!-- graph:end -->

`~/.local/share/flatpak/app/com.spotify.Client/` and `~/.var/app/com.spotify.Client/`

## What
Spotify installed as a **user-scope** Flatpak (not system-scope, not AUR), then patched
with the official `SpotX-Bash` script (ad-block + assorted UI/feature unlocks for the
desktop client).

## Why
User wanted an ad-free/enhanced Spotify. User-scope Flatpak was chosen specifically so
`spotx.sh` never needs `sudo` to patch it — see history below for why that mattered.

## Change

**1. Install Spotify (user-scope Flatpak):**
```bash
# Flathub must be registered at USER scope too — a remote registered only at system
# scope (the default here) is invisible to a --user install and fails with
# "No remote refs found for flathub".
flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub com.spotify.Client
```
Launch it once (`flatpak run com.spotify.Client`) and quit normally, so its data dir
exists before patching.

**2. Install SpotX's runtime deps** (official repo, not AUR — no trust review needed):
```bash
sudo pacman -S zip unzip
```

**3. Run the official SpotX-Bash patcher** (reviewed in full before running — see Notes):
```bash
curl -sSL https://raw.githubusercontent.com/SpotX-Official/SpotX-Bash/main/spotx.sh | bash
```
No `sudo` prompt for a user-scope install — the script only elevates when the target
isn't already user-writable.

**4. Rerun after every Spotify update** (no auto-repatch hook is set up — deliberate,
see Notes):
```bash
flatpak update --user com.spotify.Client
curl -sSL https://raw.githubusercontent.com/SpotX-Official/SpotX-Bash/main/spotx.sh | bash
```

## Notes

- **Why user-scope Flatpak over AUR or system-scope Flatpak:** all three install Spotify
  fine, but only a *user*-scope install (`~/.local/share/flatpak/...`, user-owned) lets
  SpotX patch it without `sudo`. AUR installs to `/opt/spotify` (root-owned); a plain
  `flatpak install` (no `--user`) defaults to **system** scope here
  (`/var/lib/flatpak/...`, also root-owned) since the Flathub remote is registered at
  system scope by default — confirmed live both ways needed a password prompt for
  SpotX, only `--user` didn't.
- **Trust review done before running anything:**
  - AUR `spotify` package: well-vetted (273 votes, maintained by an actual Arch Trusted
    User, downloads Spotify's own official signed `.deb` with GPG verification against
    Spotify's real key — no arbitrary code). Confirmed by reading the full PKGBUILD.
  - AUR `spotx-linux` wrapper: **avoided** — only 2 votes, stale (mid-2024), and it
    silently re-executes a third-party fork's `install.sh` via a pacman hook on every
    future Spotify update with no review. Used the **official** `SpotX-Official/SpotX-Bash`
    script run manually instead, after reading all ~1600 lines — no exfiltration, no
    unscoped `rm -rf`, `sudo` requested transparently only when the target needs it.
  - Flathub's Spotify listing is **not** "verified" (`flathub::verification::verified` is
    `null`) despite showing "Spotify" as developer — it's a community repackaging, same
    trust category as the AUR package, not more official. Its edge is Flatpak's runtime
    sandboxing of the *running app*, unrelated to the patch step's trust (SpotX patches
    files on disk as your user either way, sandboxed install or not).
- **Downside of skipping the AUR SpotX wrapper:** no auto-repatch on update. Must rerun
  `spotx.sh` by hand after `flatpak update` bumps Spotify — see step 4 above.
- **Shelly (GTK4 pacman/AUR GUI) has a reproducible crash bug** in its own PGP-key-import
  dialog — confirmed via `coredumpctl` + journal logs: a null-pointer segfault
  (`Segmentation fault at address 0x0`) inside Shelly's own code, not gpg/pacman/network.
  Happened identically twice. Workaround used: import any needed signing key manually in
  a terminal *before* using Shelly's build flow, e.g. for Spotify's key:
  ```bash
  curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.gpg | gpg --import -
  ```
  Shelly then finds the key already present and skips its crashing import step.
- Spotify's optional local-file-playback deps (`ffmpeg4.4`, `zenity` — official repo, no
  AUR) were **not installed**: user doesn't play local files through Spotify, only
  streams. Both are official repo packages if this changes later — no build required.
