# System locale named `en_IN.UTF-8`, not bare `en_IN`

**Date:** 2026-10-02
**Category:** locale
**Files touched:** `/etc/locale.conf` (stored at [`files/etc/locale.conf`](files/etc/locale.conf))

## What
Changed every `en_IN` in `/etc/locale.conf` to `en_IN.UTF-8`. Same locale data (Indian
date/currency/number formats), just the name now says UTF-8.

## Why
btop wouldn't open from the app launcher: the window flashed and closed. btop picks
UTF-8 mode by looking for "UTF-8" in the locale *name* (`LANG`/`LC_*`), not at the real
charset. With `LANG=en_IN` it quits immediately:

```
ERROR: No UTF-8 locale detected!
Use --force-utf argument to force start if you're sure your terminal can handle it.
```

It worked in a terminal only because of the fish alias `btop --force-utf`
([[btop-force-utf-alias]]). The launcher runs `kitty -e sh -lc btop`, which skips fish
aliases. Fixing the locale name fixes the cause for every launch path and every
program that checks the name the same way, so the alias was removed.

## Change
`/etc/locale.conf`, final state (edit with `sudoedit /etc/locale.conf`, then log out and back in):
```
LANG=en_IN.UTF-8
LC_ADDRESS=en_IN.UTF-8
LC_IDENTIFICATION=en_IN.UTF-8
LC_MEASUREMENT=en_IN.UTF-8
LC_MONETARY=en_IN.UTF-8
LC_NAME=en_IN.UTF-8
LC_NUMERIC=en_IN.UTF-8
LC_PAPER=en_IN.UTF-8
LC_TELEPHONE=en_IN.UTF-8
LC_TIME=en_IN.UTF-8
```

`/etc/locale.gen` needs **no** change. Its existing line `en_IN UTF-8` already builds
both names: glibc stores the locale as `en_IN` plus the alias `en_IN.utf8`, and
`localedef --list-archive` lists both. On a fresh machine, make sure that line is
uncommented and run `sudo locale-gen` before switching `locale.conf`.

Verify:
```bash
locale                    # every value shows en_IN.UTF-8
locale -a | grep en_IN    # en_IN.utf8 present
```

## Notes
- Bare `en_IN` was already UTF-8 (`locale charmap` → `UTF-8`). Renaming costs nothing:
  formats, sorting and character set stay the same.
- Diagnosis tip: the Noctalia launcher runs apps as systemd user units
  (`launch_apps_as_systemd_services = true`), so a terminal app that exits at once leaves
  only a `Started … kitty -e sh -lc btop` line and a sub-second runtime in
  `journalctl --user`. To see the app's own error, run the same command under
  `systemd-run --user` with the app's stderr sent to a file.
- If `en_IN.utf8` ever goes missing from `locale -a`, apps silently fall back to the `C`
  locale. Check that before blaming the app.
