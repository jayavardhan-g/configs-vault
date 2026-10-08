# Qt apps (Dolphin) not picking up the dark theme

**Date:** 2026-09-14 (updated 2026-09-19)
**Category:** mango
**Files touched:** `~/.config/mango/cfg/env.conf`, `~/.config/qt6ct/qt6ct.conf`

<!-- graph:begin -->
**Graph:** [[Mango]] · [[Noctalia]]
<!-- graph:end -->

## What
Dolphin (and any other Qt6 app) now renders with the dark "noctalia" color scheme and
breeze icons instead of the default light/unthemed Fusion look.

## Why
`qt6ct` was already fully configured (`~/.config/qt6ct/qt6ct.conf` — `style=Fusion`,
`color_scheme_path=.../colors/noctalia.conf`, `icon_theme=breeze`) but never actually
activated: Qt only consults `qt6ct` when `QT_QPA_PLATFORMTHEME` tells it to, and that
line was present in `env.conf` but commented out. GTK apps were unaffected since they
theme separately via `~/.config/gtk-3.0/settings.ini` (`adw-gtk3-dark`, already working).
Confirmed Dolphin links Qt6 specifically (`ldd /usr/bin/dolphin`), so the `_QT6` variant
of the variable matters here, not `QT_QPA_PLATFORMTHEME_QT5`.

## Change

`~/.config/mango/cfg/env.conf`:
```
env = QT_QPA_PLATFORMTHEME,qt6ct
env = QT_QPA_PLATFORMTHEME_QT6,qt6ct
```
(previously present but commented out)

`~/.config/qt6ct/qt6ct.conf` (2026-09-19 follow-up):
```
[Appearance]
style=Breeze
```
(was `style=Fusion` — see Notes)

## Notes
- **`env =` directives only apply at Mango's actual startup, not on `reload_config`** —
  confirmed live: after uncommenting and reloading, a freshly-launched Dolphin still had
  no `QT_QPA_PLATFORMTHEME` in its `/proc/<pid>/environ`. Verified the fix itself was
  correct by launching Dolphin with the same variables set directly in the shell instead
  (visually confirmed working, dark theme applied) before concluding a full Mango
  restart is needed to pick this up for real — not yet done as of this entry, do on next
  convenient restart.
- If a Qt5 app ever shows the same problem, add `env = QT_QPA_PLATFORMTHEME_QT5,qt6ct`
  too — a `qt5ct` color config already exists at `~/.config/qt5ct/colors/noctalia.conf`
  but no `qt5ct.conf` itself, so that path isn't fully wired up yet.
- **2026-09-19 follow-up:** even with the env vars fixed, Dolphin still rendered half
  light / half dark — the base `QPalette` was dark, but KDE-specific custom-painted
  chrome (Places sidebar, breadcrumb bar) is written against the **Breeze** widget
  style specifically and falls back to unstyled (white) rendering under any other
  style, including `Fusion` + a custom palette. `qt6ct.conf` had `style=Fusion` even
  though the `breeze` Qt6 style plugin was already installed
  (`/usr/lib/qt6/plugins/styles/breeze6.so`) — switched to `style=Breeze`, fixed it.
  Requires killing and relaunching Dolphin (`killall dolphin`) to pick up; not a live
  reload like the colors file.
- This `style=` key is safe from Noctalia's own theme-switching: checked
  `/usr/share/noctalia/assets/templates/qt/undo.sh` and it only ever touches
  `~/.config/qt6ct/colors/noctalia.conf` (the palette file), never `qt6ct.conf`
  itself. Switching wallpapers/color schemes in Noctalia won't revert this.
- Oddly, `/etc/skel/.config/qt6ct/qt6ct.conf` (the `cachyos-mango-noctalia` package's
  own shipped default) already has `style=Breeze` — this machine's live config had
  drifted to `Fusion` before 2026-09-14 for an unknown reason, it wasn't something
  either recorded session here changed.
