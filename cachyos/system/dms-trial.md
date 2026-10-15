# DankMaterialShell (DMS) trial: a Noctalia-identical setup, measured against Noctalia

**Date:** 2026-10-15 (started; in progress)
**Category:** system
**Files touched:** none yet. Planned: DMS's own settings files, a separate Hyprland

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Noctalia]] · [[Quickshell]] · [[DankMaterialShell]]
<!-- graph:end -->

bind/autostart file for the DMS session, and repointed colour sources (listed under
[Change](#change) as they happen).

## What
A side-by-side trial of **DankMaterialShell** (`dms-shell`, a Quickshell/QML desktop shell)
against **Noctalia 5.2.1** (native C++), the current daily shell. The goal is a fair
memory/CPU comparison, so DMS is first configured to do *everything* Noctalia does here
(same top bar, widgets, auto-hide, keybinds, theming), and then both are measured fresh.
Noctalia stays the default until a decision is made.

## Why
- Question that started it: would a full Quickshell-based shell be lighter than Noctalia +
  the separate Quickshell pomodoro? An estimate (200–300 MB for a full QML shell) wasn't
  good enough; Jayavardhan wanted it measured.
- "Identical first" so no feature silently goes missing and the numbers compare the same
  feature set.

### Why DMS and not Caelestia
Caelestia (`caelestia-dots/shell` 2.5.0) was the first candidate and was checked against
its source before installing anything. Rejected for this trial:
- **Bar is vertical-only** (`modules/bar/Bar.qml` is a `ColumnLayout` on the left edge),
  no horizontal mode, no overlay layer, no smart auto-hide. An identical top bar meant
  rewriting it. `shell.json` only toggles/reorders/restyles what exists.
- Needs **`quickshell-git`** ("has to be the git version, not the latest tagged
  version", per its README), which would replace the stable `quickshell` the pomodoro
  runs on.
- 7 AUR-only packages and no AUR helper installed (`libcava`, `qt6-m3shapes-git`,
  `python-materialyoucolor`, `ttf-rubik-vf`, `caelestia-cli`, `quickshell-git`,
  `caelestia-shell`).
- No polkit agent, greeter, window switcher, hot corners, todo widget, wallpaper rotation;
  clipboard/emoji only via `caelestia-cli` + fuzzel.

DMS (`dms-shell` 1.6.3, official `extra` repo) instead has: bar on any edge incl. top,
auto-hide, built-in polkit agent, greetd greeter (`dank-greeter`), clipboard history,
wallpaper cycling, idle lock/suspend, DND, idle inhibitor, matugen theming (kitty,
alacritty, GTK, Qt, KColorScheme), a plugin registry, and Caelestia's visual tricks too: a
**dynamic island** (`Modules/DIsland`: media/notification/system faces, free drag) and a
**connected screen frame** (`Modules/Frame`, `frameEnabled`) that panels emerge from.
Depends only on `quickshell` (stable) + `accountsservice`.

Others considered and skipped: end-4's illogical-impulse (heavy, installer overwrites the
Hyprland config), HyprPanel (AGS, bar only), Noctalia v4 (the old QML Noctalia, would be
the perfect like-for-like test but is no longer packaged).

## Packages
Ledger of everything this trial installs, so it can be undone exactly. Status: planned →
installed → kept/removed.

| Package | Repo | Why | Status |
|---|---|---|---|
| `dms-shell` | extra | The shell itself (+ `dms` CLI) | planned |
| `matugen` | extra | Wallpaper-based colour generation for DMS theming/templates | planned |
| `cava` | extra | DMS audio visualizer (optional dep) | planned |
| `wtype` | extra | Paste from DMS clipboard history (optional dep) | planned |
| `qt6-multimedia` | — | DMS sound effects; **already installed before the trial**, don't remove | pre-existing |

Already present and used by DMS: `quickshell` 0.3.2, `networkmanager`,
`power-profiles-daemon`, `qt6ct`.

## Parity checklist
Everything Noctalia does on this machine (from `noctalia config export`, Hyprland binds,
autostart and theme consumers) and how DMS covers it. ✓ = native, ⚙ = needs config or a
small addition, ✗ = gap to build.

| Noctalia feature in use | DMS | Status |
|---|---|---|
| Top bar, overlay layer, smart auto-hide, no reserved space, 35px, bottom corners 12 | ✓ bar position/auto-hide | todo |
| Bar start: group(RAM sysmon), active window | ⚙ | todo |
| Bar center: clock (`%H:%M %A %d/%m/%y`), todo plugin, screen-recorder plugin | ⚙ clock; ✗ todo, recorder | todo |
| Bar end: workspaces (pills), media (album art only), tray, notifications, bluetooth, network, volume, battery, session | ⚙ | todo |
| Launcher (SUPER+Space), calculator | ✓ | todo |
| Emoji picker (SUPER+.) | ✗ unconfirmed | todo |
| Clipboard panel (SUPER+V), image action → `satty -f -` | ✓ history; ⚙ satty | todo |
| Screenshots (Print full, SUPER+Print/F6 region) piped to `satty -f -` | ⚙ | todo |
| Control centre (SUPER+X), notification centre (SUPER+A), DND | ✓ | todo |
| Session menu (SUPER+SHIFT+Q): lock, logout, lock+suspend 3s, reboot 3s, shutdown 3s | ✓ power menu; ⚙ countdowns | todo |
| Window switcher (SUPER+Tab), bottom-left hot corner → switcher | ✗ (niri-only in DMS) | todo |
| Lock screen, stripes lock/unlock transition | ✓ lock; ✗ stripes | todo |
| Idle: screen off 5 min, lock 10 min | ✓ | todo |
| Polkit agent | ✓ | todo |
| Notification daemon (limine-snapper restore prompt waits on it) | ✓ | todo |
| Volume/mic/brightness/media keys + OSD (13 binds) | ✓ via `dms ipc` | todo |
| Wallpaper picker (SUPER+W), `~/Downloads/wallpapers`, stretch, auto-rotation, stripes transition | ✓ picker/cycling; ✗ stripes | todo |
| Settings app (SUPER+Z) | ✓ | todo |
| Theme: dark, wallpaper source, `m3-fruit-salad` scheme | ⚙ matugen scheme | todo |
| Templates: kitty, btop, gtk3, gtk4, qt, kcolorscheme, alacritty | ✓ most; ⚙ btop | todo |
| Neovim `colors/kitty.lua`, pomodoro `Theme.qml` read Noctalia's palette | ⚙ repoint | todo |
| Pomodoro DND + caffeine via `noctalia msg` | ⚙ repoint to `dms ipc` | todo |
| greetd greeter + greeter sync (+ `rotation-pauses-greeter-sync` units) | ✓ dank-greeter | todo (last; touches login) |
| Launch apps as systemd services, ui scale 1.0 / bar scale 1.1 | ⚙ | todo |

## Measurements
Method: restart the shell fresh, then PSS (`/proc/<pid>/smaps_rollup`) + CPU at 1, 5 and
30 minutes, same widgets, same wallpaper, pomodoro `qs` running in both cases.

**Baseline before the trial (2026-10-15, not fresh: ~1.5 days uptime):**

| Process | RSS | PSS | Threads | CPU |
|---|---|---|---|---|
| `noctalia` (whole shell, single process, no children) | 187 MB | 114 MB | 46 | 1.3% |
| `qs -d` (pomodoro only) | 152 MB | 87 MB | 13 | 0.0% |

(Noctalia's RSS was 138 MB on 2026-10-02 per [[quickshell-trial-plan]]; it grows with
uptime, hence fresh restarts for the real comparison.)

## Log
- **2026-10-15** — Measured baseline (above). Inventoried Noctalia's effective config,
  binds and theme consumers. Evaluated Caelestia from source → rejected (see Why).
  Evaluated DMS from source → chosen. Nothing installed yet.

## Change
Nothing changed yet.

## Undo
```bash
sudo pacman -Rns dms-shell matugen cava wtype   # not qt6-multimedia: pre-existing
```
Plus any files listed under Change.

## Notes
- Don't run `dms setup`: it rewrites compositor configs. DMS is configured only through
  its own settings; the Hyprland Lua config stays hand-written.
- Caelestia/DMS source was read from shallow clones in a throwaway scratch folder.
