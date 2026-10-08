# VSCode (official Microsoft build) + keyring for Settings Sync

**Date:** 2026-08-29
**Category:** system
**Files touched:** `~/.config/hypr/config/autostart.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[CachyOS]] · [[GNOME Keyring]] · [[VSCode]]
<!-- graph:end -->

## What
Installed the official Microsoft VSCode build (`visual-studio-code-bin` from the AUR)
instead of the Arch/CachyOS-repo OSS build (`code`), plus `gnome-keyring`/`gcr` so
Settings Sync and extension `SecretStorage` have a real OS keyring to write to, and a
Hyprland autostart entry + a VSCode startup flag to make that keyring actually get
detected under Hyprland.

## Why
User wants Settings Sync (extensions, keybindings, settings) to match their existing
Windows VSCode setup, and specifically needs the **Remote-SSH** extension, which is
Microsoft-licensed and not available on open-vsx.org (the marketplace the OSS `code`
build uses). The OSS build was tried first and both of these broke: MS-exclusive
extensions aren't on open-vsx at all, and even installable extensions don't cleanly sync.
The official build fixes both by using the real Microsoft Marketplace.

No AUR helper was installed on this machine yet, so `paru` was bootstrped first.

## Change

Bootstrap an AUR helper (one-time, if not already present):
```
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru
makepkg -si
```

Install VSCode (official build) and keyring support:
```
paru -S visual-studio-code-bin
sudo pacman -S gnome-keyring gcr
```

`~/.config/hypr/config/autostart.lua` — add the keyring daemon to the existing
`hyprland.start` hook (this project uses a Lua-based Hyprland config, see repo root
`hyprland.lua` / `config/*.lua`):
```lua
hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("gnome-keyring-daemon --start --components=pkcs11,secrets")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("xhost +SI:localuser:root")
end)
```
(`ssh` component deliberately left out — not replacing the system ssh-agent.)

## Notes
- **Why the keyring daemon needs an explicit `exec-once`-equivalent**: gnome-keyring ships
  a D-Bus service-activation file for `org.freedesktop.secrets`, so in theory nothing
  needs to start it manually — but that activation depends on a login keyring having been
  unlocked via a PAM session module, which greetd's PAM stack originally didn't set up
  (since fixed — see [[greetd-pam-gnome-keyring-unlock]]). Starting it explicitly at
  Hyprland startup sidesteps that, and is harmless now that PAM unlocks it.
- **Tried and reverted: `"password-store": "gnome-libsecret"` in `~/.config/Code/argv.json`.**
  Electron/Chromium's automatic keyring-backend detection
  (`base::nix::GetDesktopEnvironment`) only recognizes a hardcoded list of desktop
  environments (GNOME, KDE, XFCE, etc.) via `XDG_CURRENT_DESKTOP`, and Hyprland isn't on
  that list — this flag is VSCode's own documented fix for the resulting "An OS keyring
  couldn't be identified..." warning. It turned out not to be the actual fix here: the
  warning was really appearing because the Microsoft/GitHub sign-in flow was being
  dismissed without completing it, and once sign-in was done properly the warning stopped
  regardless of this flag — so it was removed again (file deleted, it didn't exist
  before). Worth trying again first if this warning resurfaces and a proper sign-in
  doesn't clear it.
- The same warning also appears when opening a **Remote-SSH** connection — that's a
  separate instance of the same check, running in the `vscode-server` process on the
  remote host, not local. A bare headless lab/GPU server has no desktop session, D-Bus, or
  keyring at all, so there's nothing to detect; this is expected and not worth installing
  a keyring stack on a shared machine to silence. Dismiss with the weaker-encryption/basic
  option — it only affects how the remote-side server caches its own local secrets, not
  SSH auth. (If it needs silencing, the equivalent fix is remote-side:
  `~/.vscode-server/data/argv.json` with `"password-store": "basic"` on the remote host —
  not attempted here since the local flag itself wasn't confirmed necessary.)
- `org.freedesktop.secrets` (Secret Service) is used by more than Settings Sync — any
  extension using the `SecretStorage` API (GitHub PRs, GitLens PATs, DB passwords,
  Remote-SSH saved passphrases, etc.) goes through the same backend.
- `libdbusmenu-glib` (an optional dep some AUR comments mention) is for a desktop
  "global menu" panel widget (KDE/GNOME shell feature) — not applicable to Hyprland,
  skipped.
- A stale flag (`encryption.migratedToGnomeLibsecret`) in VSCode's
  `~/.config/Code/User/globalStorage/state.vscdb` was cleared once during troubleshooting
  to force re-detection — this was a one-off diagnostic action, not something that needs
  reproducing on a fresh install.
