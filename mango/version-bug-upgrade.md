# Upgraded to mangowm 0.17.0 via AUR (0.16.1 had real bugs)

**Date:** 2026-09-13
**Category:** mango
**Files touched:** none directly — package swap only (`pacman`)

<!-- graph:begin -->
**Graph:** [[Mango]] · [[CachyOS]]
<!-- graph:end -->

## What
Replaced the CachyOS-repo `mangowm` package (`0.16.1-1`) with the AUR package
`mangowm` (`0.17.0-1`), built manually via `makepkg` (installed by the user via
"Shelly", a GUI AUR-build front-end — same effect as `makepkg -si`).

```sh
sudo pacman -S --needed base-devel git   # only if not already present
git clone https://aur.archlinux.org/mangowm.git
cd mangowm
makepkg -si
```

Since the AUR package has the identical name `mangowm`, this is a plain
in-place upgrade — no `--overwrite`, no provides/conflicts dance. `pacman -Qi
mangowm` afterward shows `Installed From: None` (pacman's way of marking a
foreign/AUR package). When CachyOS's own repo eventually ships 0.17.0+, a
plain `pacman -Syu` will pick that back up automatically.

## Why
Two real bugs were hit and confirmed directly against the actual installed
binary/source (not docs, which turned out unreliable — see Notes):

1. **`toggle_special_tag`/`tag_special_tag` (the "Special Floating Workspace"
   feature) don't exist in 0.16.1 at all.** `strings /usr/bin/mango` on the
   0.16.1 binary had no such symbols; the 0.17.0 release notes list "Special
   Floating Workspace (Special Tag)" as a brand-new feature in that release.
2. **`restore_minimized` never un-floats the window in 0.16.1** — confirmed by
   diffing the actual tagged source: the 0.16.1 version of the function never
   calls `client_set_floating(c, 0)` at all, so a window restored from the
   minimize-pile stays floating instead of returning to the tiled layout. The
   0.17.0 source has that call. Manual workaround before upgrading was
   `SUPER+SHIFT+I` then `SUPER+SHIFT+F` (float-toggle) as two separate
   keypresses.

## Change
No config files changed by this entry itself — see [[keybinds]] for the
`toggle_special_tag`/`tag_special_tag` binds that only work because of this
upgrade, and [[appearance-and-input]] for the `special_gappih`/etc. options
that only exist in 0.17.0+.

## Notes
- **Don't trust wiki-summary tools for exact dispatcher/config names on this
  project** — a wiki-page fetch confidently reported `toggle_special_tag`/
  `tag_special_tag` as available when only 0.16.1 was installed, which turned
  out to be true upstream but false for the then-installed version. The
  reliable way to check: `strings /usr/bin/mango | grep -i <name>` against the
  actual installed binary, or pull the exact tagged source
  (`raw.githubusercontent.com/mangowm/mango/<tag>/...`) — never assume `main`
  branch content matches an installed release tag.
- Mango ships fast: 0.16.0 → 0.17.0 happened over about 4 weeks
  (2026-08-12 to 2026-09-12), each with real bugfixes. Worth re-checking
  `pacman -Ss mangowm` vs the AUR `mangowm` version periodically, since this
  project is still pre-1.0 and evolving quickly.
- `mango -p` (or `mango -c <file> -p`) validates a config file for syntax
  errors and exits 0 with no output if clean — useful before every reload
  when hand-editing, given how much this project's config surface has been
  changing release to release.
- After any AUR/package upgrade of a *running* compositor, `reload_config`
  (or `SUPER+F5`) is **not enough** — the already-running process is still the
  old binary in memory until a full logout/login. Confirmed via `mmsg get
  version` showing `0.16.1` live while `mango -v` (the new on-disk binary)
  already reported `0.17.0`; every reload in between fed 0.17.0-only config
  syntax to the old 0.16.1 process, which corrupted its entire keybind table
  (every bind stopped working, not just the new ones) until the actual
  relogin happened.
