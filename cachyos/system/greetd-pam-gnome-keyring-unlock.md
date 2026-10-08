# Keyring unlocked at login via greetd PAM

**Date:** 2026-10-01
**Category:** system
**Files touched:** `/etc/pam.d/greetd` (stored copy: [files/etc/pam.d/greetd](../files/etc/pam.d/greetd)), `~/.local/share/keyrings/` (keyring renamed, not stored — contains secrets)

<!-- graph:begin -->
**Graph:** [[greetd]] · [[GNOME Keyring]]
<!-- graph:end -->

## What
Added `pam_gnome_keyring.so` to greetd's PAM stack and renamed the gnome-keyring
collection from `Default_keyring` to `login`, so the login password unlocks it
automatically and the "unlock Default keyring" password prompt after every login is gone.

## Why
Every login showed a gnome-keyring password prompt. The requester is **Noctalia**, not
VSCode: it links `libsecret` and stores the key for its encrypted clipboard history in the
keyring, so it asks for it ~1s after starting. Its log confirms it:
```
[app] secret service default collection unlocked; reopening consumers
[clipboard] loaded encrypted clipboard history
```
The keyring was locked because nothing in the login path unlocked it — greetd's PAM file
(as rewritten by the noctalia-greeter installer) had no `pam_gnome_keyring.so` line, and
no full DE was around to do it either.

## Change
`/etc/pam.d/greetd` final state:
```
#%PAM-1.0

auth       required     pam_securetty.so
auth       requisite    pam_nologin.so
auth       include      system-local-login
auth       optional     pam_gnome_keyring.so
account    include      system-local-login
session    include      system-local-login
session    required     pam_systemd.so
session    optional     pam_gnome_keyring.so auto_start
```

Rename the existing keyring to `login` (only valid if its password == the login password;
otherwise change its password to the login password first, e.g. with `seahorse`):
```
systemctl --user stop gnome-keyring-daemon.service
mv ~/.local/share/keyrings/Default_keyring.keyring ~/.local/share/keyrings/login.keyring
printf login > ~/.local/share/keyrings/default
```
Then log out and back in.

## Notes
- PAM only auto-unlocks the keyring named **`login`** — adding the PAM lines alone would
  not have helped while the secrets lived in `Default_keyring`.
- Both lines are `optional`, so a keyring failure can't block login. Still keep a TTY
  login handy when touching this file — see
  [[mango-nvidia-cpu-spin-switched-to-hyprland]] for a PAM mistake that took greetd down.
- `/etc/pam.d/greetd` is owned by the `greetd` package (backup file), so upgrades should
  write a `.pacnew` rather than overwrite it. Re-check it if noctalia-greeter is
  reinstalled — its installer rewrote this file once already (left
  `greetd.bak.noctalia.20260828060929`).
- The Hyprland autostart `gnome-keyring-daemon --start` from [[vscode-official-build]]
  is kept; it just attaches to the already-unlocked daemon now.
