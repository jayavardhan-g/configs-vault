# DankMaterialShell (DMS) trial: a Noctalia-identical setup, measured against Noctalia

**Date:** 2026-10-15 → 2026-10-16 (decided: keep DMS installed, stay on Noctalia)
**Category:** system
**Files touched:** see [Change](#change) — every file is copied under `cachyos/files/` (username redacted to `<user>`)

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Noctalia]] · [[Quickshell]] · [[DankMaterialShell]]
<!-- graph:end -->

## What
A side-by-side trial of **DankMaterialShell** (`dms-shell`, a Quickshell/QML desktop shell)
against **Noctalia 5.2.1** (native C++), the current daily shell. The goal is a fair
memory/CPU comparison, so DMS is first configured to do *everything* Noctalia does here
(same top bar, widgets, auto-hide, keybinds, theming), and then both are measured fresh.
Noctalia stays the default; one word in `~/.config/hypr/config/shell.lua` switches.

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

DMS (`dms-shell` 1.6.3, official repos) instead has: bar on any edge incl. top,
auto-hide, built-in polkit agent, greetd greeter (`dank-greeter`), clipboard history,
wallpaper cycling (incl. a **stripes** transition), idle lock/suspend, DND, idle
inhibitor, matugen theming (kitty, alacritty, GTK, Qt, KColorScheme), a plugin registry
(380 plugins), and Caelestia's visual tricks too: a **dynamic island** (`Modules/DIsland`:
media/notification/system faces, free drag) and a **connected screen frame**
(`Modules/Frame`, `frameEnabled`) that panels emerge from. Depends only on `quickshell`
(stable) + `accountsservice`.

Others considered and skipped: end-4's illogical-impulse (heavy, installer overwrites the
Hyprland config), HyprPanel (AGS, bar only), Noctalia v4 (the old QML Noctalia, would be
the perfect like-for-like test but is no longer packaged).

## Packages
Ledger of everything this trial installs, so it can be undone exactly.

**pacman** (installed 2026-10-15, all from the `cachyos` repo):

| Package | Version | Why | Status |
|---|---|---|---|
| `dms-shell` | 1.6.3-1 | The shell + `dms` CLI. The QML UI is embedded in the binary (`dist/`); ships a `dms.service` user unit, left **disabled** | installed, **kept (dormant)** |
| `matugen` | 4.2.0-1.1 | Wallpaper-based colour generation for DMS theming/templates | installed, **kept (dormant)** |
| `cava` | 1.0.0-1.1 | DMS audio visualizer (optional dep) | installed, **kept (dormant)** |
| `wtype` | 0.4-2.2 | Paste from DMS clipboard history / emoji picker (optional dep) | installed, **kept (dormant)** |
| `qt6-multimedia` | 6.12.0-1.1 | DMS sound effects. **Already installed before the trial**, don't remove | pre-existing |

Already present and used: `quickshell` 0.3.2 (stable, unchanged), `gpu-screen-recorder`,
`networkmanager`, `power-profiles-daemon`, `qt6ct`, `kwriteconfig6`.

**DMS plugins** (`dms plugins install <id>`, into `~/.config/DankMaterialShell/plugins/`;
code read before enabling — no network calls, commands properly quoted):

| Plugin | Version / author | Covers | Status |
|---|---|---|---|
| `screenRecorder` | 1.5.3 / arqueon | Noctalia's `noctalia/screen_recorder` (gpu-screen-recorder, focused monitor, 30 fps, `~/Videos/Recordings`) | installed, enabled, **locally patched** (see Notes) |
| `dankTodo` | 1.2.0 / Deepu K Sasidharan | Noctalia's `nightwatch75/todo` bar widget | **uninstalled 2026-10-15** (todo isn't used in Noctalia either) |
| `dankHyprlandWindows` | 1.0.0 / Avenge Media (DMS authors) | SUPER+Tab window switcher with live previews (launcher mode, trigger `!`) | installed, enabled |
| `emojiLauncher` | 1.7.2 / devnullvoid | SUPER+. emoji picker (launcher mode, trigger `:e`) | installed, enabled |
| `hotCorner` | local (written for this trial) | Bottom-left hot corner → window switcher | written, enabled |

## Parity checklist
Everything Noctalia does on this machine (from `noctalia config export`, Hyprland binds,
autostart and theme consumers) and how DMS covers it. Status: **done** = configured,
**diff** = works but not identical, **open** = not done yet. Nothing here is visually
verified yet — that's the live test.

| Noctalia feature in use | DMS | Status |
|---|---|---|
| Top bar, overlay layer, smart auto-hide (hidden with windows open, shown on empty workspace/hover), no reserved space, edge-attached, concave 12px corners, 90% opacity, 1.1 scale, no shadow | `barConfigs[0]`: `position 0`, `useOverlayLayer`, `autoHide` + `showOnWindowsOpen`, `attachToScreenEdge`, `gothCorners*` 12, `transparency 0.9`, font/icon scale 1.1 | done (thickness 35px has no direct key) |
| Bar start: RAM sysmon, active window | `memUsage`, `focusedWindow` | done |
| Bar center: clock (`%H:%M %A %d/%m/%y`), screen recorder (Noctalia's `todo` entry is dead: its plugin isn't in `plugins.enabled`) | `clock` (`24h` + `dddd dd/MM/yy`), `screenRecorder` | done |
| Bar end: workspaces (pills, no labels), media (album art only), tray, notifications, bluetooth, network, volume, battery, session | `workspaceSwitcher`, `music` (`mediaSize 0`), `spacer`, `systemTray`, `notificationButton`, `controlCenterButton` (network+bluetooth+audio icons in one), `battery`, `powerMenuButton` | diff: network/bluetooth/volume are one button |
| Launcher (SUPER+Space), calculator | built in | done |
| Emoji picker (SUPER+.) | `emojiLauncher` via `launcher openQuery ':e '` | done |
| Clipboard panel (SUPER+V) | built in | done |
| Clipboard image action → `satty -f -` | no equivalent | **open** |
| Screenshots (Print full, SUPER+Print/F6 region) piped to satty, no save/copy | `dms screenshot full\|region --stdout --no-file --no-clipboard --no-notify \| satty -f -` | done |
| Control centre (SUPER+X), notification centre (SUPER+A), DND | built in | done |
| Control-centre quick toggles: Wi-Fi, Bluetooth, **Caffeine**, Night light, **Notifications (DND)**, **Power profile** | DMS defaults have `wifi`, `bluetooth`, `nightMode` (+ audio in/out, dark mode) but not `idleInhibitor`, `doNotDisturb`; power profiles live in the `battery` tile/popout, no direct toggle | done 2026-10-16: `controlCenterWidgets` now volume, brightness, wifi, bluetooth, **idleInhibitor**, nightMode, **doNotDisturb**, **battery** (power profiles in its detail), audio out/in, dark mode (found by Jayavardhan). Set by editing settings.json; `dms ipc call settings set` rejects list values |
| Session menu (SUPER+SHIFT+Q): lock, logout, lock+suspend, reboot, shutdown, 3 s countdowns | `powerMenuActions` same order, `lockBeforeSuspend`; DMS confirms by hold (0.5 s), not countdown | diff |
| Window switcher (SUPER+Tab) | `dankHyprlandWindows` (tile launcher with previews; not a hold-Tab cycle overlay) | diff |
| Hot corner bottom-left → switcher | `hotCorner` plugin (2×2 px overlay, fires on entry) | done |
| Lock screen | built in | done |
| Lock/unlock stripes transition | none in DMS | **open** |
| Idle: screen off 5 min, lock 10 min | `ac/batteryMonitorTimeout 300`, `ac/batteryLockTimeout 600`, fades off | done |
| Polkit agent, notification daemon (limine-snapper prompt waits on its bus name) | built in | done |
| Volume/mic/brightness/media keys + OSD | `dms ipc call audio\|mpris\|brightness …` (step 5) | done |
| Wallpaper picker (SUPER+W), `~/Downloads/wallpapers`, stretch, random rotation every 1800 s, stripes transition | `dankdash wallpaper`; `session.json` cycling + `Stretch` + `stripes` | done |
| Settings (SUPER+Z) | `settings toggle` | done (window float rule unchecked) |
| Theme: dark, wallpaper source, fruit-salad scheme, animations off, no popup shadows | `currentThemeName dynamic`, `scheme-fruit-salad`, `animationSpeed 0`, shadows off | done |
| Templates: kitty, gtk3, gtk4, qt, kcolorscheme, alacritty | DMS built-ins; KDE colours merged into `kdeglobals` by `kde-colors-from-dms.path` | done |
| Template: btop | user matugen template (Noctalia's own btop template, same syntax) | done |
| Neovim `colors/kitty.lua` | follows kitty.conf's `include`, so follows the switch | done |
| Pomodoro `Theme.qml` colours | now follows whichever file `gtk-4.0/gtk.css` imports | done |
| Pomodoro DND + caffeine | `quickshell/shellctl.sh` (talks to whichever shell runs) | done |
| greetd greeter + greeter colour sync | Noctalia greeter keeps working; its colours won't follow DMS | **open** (last; touches login) |
| Apps launched as systemd units | `launchPrefix "uwsm app --"` | done |

## Measurements
Method: restart the shell fresh, then PSS (`/proc/<pid>/smaps_rollup`) + CPU at 1, 5 and
30 minutes, same widgets, same wallpaper, pomodoro `qs` running in both cases. For DMS,
sum every process it runs (`dms` backend + its quickshell UI).

**Baseline before the trial (2026-10-15, not fresh: ~1.5 days uptime):**

| Process | RSS | PSS | Threads | CPU |
|---|---|---|---|---|
| `noctalia` (whole shell, single process, no children) | 187 MB | 114 MB | 46 | 1.3% |
| `qs -d` (pomodoro only) | 152 MB | 87 MB | 13 | 0.0% |

(Noctalia's RSS was 138 MB on 2026-10-02 per [[quickshell-trial-plan]]; it grows with
uptime, hence fresh restarts for the real comparison.)

**DMS, frame off** (fresh start 2026-10-15 23:45 via `hyprctl dispatch 'hl.dsp.exec_cmd("dms run")'`;
bar/widgets as in the parity table, before the control-centre tiles were added):

| | 1 min | 5 min | 30 min |
|---|---|---|---|
| PSS total | 313 MB | 359 MB | 434 MB |
| └ UI (`qs -p …/danklinux-shell`) | 284 MB | 330 MB | 389 MB |
| └ backend (`dms run`) | 29 MB | 29 MB | 45 MB |
| CPU (15 s sample at that point) | 0.33% | 0.20% | 0.27% |

30-min average CPU 2.14% (peaks to 42% at start and while panels open), peak PSS 460 MB.
PSS every 5 min: 320 → 359 → 365 → 368 → 369 → 391 MB (still climbing at 30 min).
Correction: the first pass of the script also counted itself (its own command line
contained the UI pattern, ~7.6 MB); figures above exclude it, and the script now skips
its own process.

**Noctalia** (fresh start 2026-10-16 00:25 via `hyprctl dispatch 'hl.dsp.exec_cmd("noctalia")'`,
same method; single process):

| | 1 min | 5 min | 30 min |
|---|---|---|---|
| PSS | 196 MB | 123 MB | 116 MB |
| CPU (15 s sample at that point) | 10.3% | 1.33% | 1.13% |

30-min average CPU 1.56%, peak PSS 196 MB (start-up, then released).
PSS every 5 min: 110 → 121 → 122 → 127 → 114 → 115 MB (flat).

**Result (same feature set, fresh starts, 30 min each; the pomodoro `qs` excluded from both):**

| | Noctalia 5.2.1 | DMS 1.6.3 (frame off) |
|---|---|---|
| PSS at 30 min | **116 MB** | **434 MB** (3.7×) |
| Memory trend | flat ~115–127 MB after start-up | still climbing (320 → 391 MB UI+backend over the run) |
| Average CPU, 30 min | 1.56% | 2.14% |
| Idle CPU (30-min sample) | ~1.1% steady | ~0.3%, with spikes up to 42% on panels/start |
| Processes / threads | 1 / 46 | 2 / 61 |

DMS's cost is almost all its QML UI (`qs`, 389 MB); the Go backend is 45 MB. This settles
the original question: a full Quickshell/QML shell is several times heavier than native
Noctalia here, so switching would not save memory.

## Log
- **2026-10-15** — Measured baseline (above). Inventoried Noctalia's effective config,
  binds and theme consumers. Evaluated Caelestia from source → rejected (see Why).
  Evaluated DMS from source → chosen.
- **2026-10-15** — Installed the 4 pacman packages. Found leftovers from an earlier DMS
  run on **2026-09-21** (around the niri trial): `~/.local/state/DankMaterialShell/session.json`
  (backed up, then replaced), `~/.config/hypr/dms/*.lua` and `~/.local/share/color-schemes/DankMatugen*.colors`;
  also `~/.config/hypr/scheme/current.lua` from the same day. None of them are loaded by
  the Hyprland config; left in place.
- **2026-10-15** — Wrote DMS config, installed/reviewed 4 registry plugins, wrote the
  `hotCorner` plugin. Added the shell switch (`shell.lua`), routed all 22 `noctalia msg`
  binds through `shell_cmd()` (verified: Noctalia mode produces byte-identical commands,
  0 Hyprland config errors), theme switch script (round-trip tested on a copy of the
  real files: byte-identical after dms → noctalia), KDE colour watcher, pomodoro DND/
  caffeine helper. Live test and measurements still to do.
- **2026-10-15 23:27** — Switched to DMS by relogin (`SHELL_NAME = "dms"` + `uwsm stop`).
  DMS migrated `settings.json` to configVersion 18 (it now stores only non-default
  values). Two bugs of mine found in its log and fixed:
  - `hotCorner` didn't load: Quickshell's property is `exclusiveZone`, not `exclusionZone`.
  - **Theme generation failed** (matugen exit 1, every app kept the stale 2026-09-21
    palette): DMS finds the user `[templates]` section by plain text search, and my
    comment in `~/.config/matugen/config.toml` contained that text, so it cut the file
    mid-comment into invalid TOML. Comment reworded; generation now completes, btop
    theme included, and `kde-colors-from-dms.path` merged the new KDE colours.
  - While reproducing it, a bare `dms matugen generate` also wrote DMS's Neovim theme
    (`nvim/colors/dms.lua`, `nvim/lua/lualine/themes/dms.lua`) because the CLI doesn't
    read `matugenTemplateNeovim: false`; both deleted again. It also set the GNOME accent
    colour (normal DMS behaviour).
- **2026-10-15 23:31** — Jayavardhan turned on DMS's connected frame (`frameEnabled: true`)
  from its settings; DMS backed up the bar style and turned off edge-attach/concave
  corners to fit the frame. Not part of Noctalia parity.
- **2026-10-15** — Todo dropped: Jayavardhan doesn't use it in Noctalia either (its
  plugin is disabled there, only the layout entry remains). Removed `dankTodo` from the
  bar and `plugin_settings.json`, `dms plugins uninstall dankTodo`.
- **2026-10-15** — Asked about auto-hiding the dynamic island: **DMS 1.6.3 has no island
  auto-hide**. The island is a per-bar mode (`"island": true` on a `barConfigs` entry);
  `Modules/DankIsland` has no autoHide/reveal code, and its `island` IPC only
  expands/collapses. Bar auto-hide (`autoHide` + `showOnWindowsOpen`) applies only to a
  normal bar. Would need building if wanted.
- **2026-10-15 23:40** — Screen recording failed: `gsr error: option -s is required when
  using '-w focused' option`. My mapping was wrong: Noctalia's `video_source = "focused"`
  means the **focused monitor** (its recorder passes `-w <focusedOutputName>`), while
  gpu-screen-recorder's own `-w focused` is the focused **window** and needs `-s WxH`.
  The DMS plugin only offers portal / all screens / focused window, so it got a
  6-line local patch: a `focused-monitor` source resolved via
  `Quickshell.Hyprland`'s `Hyprland.focusedMonitor.name` at record time. Verified with a
  real 4 s recording through `dms ipc call screenRecorder startRecording/stopRecording`
  (exit 0, file written, then deleted). Output folder set to Noctalia's
  `~/Videos/Recordings` (the plugin default `~/Videos/Screencasting` was removed, empty).
  Note: an IPC start fired seconds after a `dms restart` silently did nothing; wait for
  the plugin to finish loading.
- **2026-10-16 00:15** — Frame-off run done (see Measurements). Added the missing
  control-centre tiles, then turned the frame on (`dms ipc call settings set frameEnabled
  true`) and started the frame-on run.
- **2026-10-16** — Frame-on run **cancelled**: Jayavardhan won't use the connected frame
  (it takes screen space that windows could use, and its controls were glitchy). Frame
  turned off again via IPC; DMS restored the edge-attached bar. Only frame-off is measured.
- **2026-10-16 00:22** — Back to Noctalia by relogin (`SHELL_NAME = "noctalia"`);
  `shell-theme.sh noctalia` restored all 7 colour sources. Noctalia restarted fresh at 00:25
  and measured 30 min (see Measurements). Measurement task done; decision pending.
- **2026-10-16 — Decision:** keep DMS **installed but unused**; Noctalia stays the shell
  (`SHELL_NAME = "noctalia"`) until DMS is as stable as Noctalia. Reasons: Noctalia is ~4×
  lighter (116 vs 434 MB PSS), and DMS showed rough edges (frame controls glitchy, plugin
  needed a local patch, island has no auto-hide). While dormant DMS costs nothing:
  `dms.service` disabled, no processes; `kde-colors-from-dms.path` stays enabled but only
  fires when DMS regenerates its scheme. To try it again later: set `SHELL_NAME = "dms"`
  and log out/in (everything below is still configured). After a `dms plugins update`,
  re-apply `focused-monitor.patch` to `screenRecorder`.

## Change

**Switch shells:** edit `SHELL_NAME` in `~/.config/hypr/config/shell.lua` (`"noctalia"` or
`"dms"`), save, log out and back in. At login `autostart.lua` runs
`shell-theme.sh <SHELL_NAME>` and then starts the shell.

Files (copies under `cachyos/files/`, same relative paths):

| File | What |
|---|---|
| `~/.config/hypr/config/shell.lua` | **New.** `SHELL_NAME`, `shell_cmd()` (Noctalia `msg` vocabulary → DMS IPC table), `SHELL_START` |
| `~/.config/hypr/hyprland.lua` | `require("config.shell")` first |
| `~/.config/hypr/config/binds.lua` | `local noctCall` removed; 22 binds now `shell_cmd("…")` |
| `~/.config/hypr/config/autostart.lua` | `shell-theme.sh SHELL_NAME`, then `SHELL_START` (was `noctalia`) |
| `~/.config/hypr/scripts/shell-theme.sh` | **New.** Flips kitty/GTK3/GTK4/qt6ct/kdeglobals/btop/alacritty includes between the shells' generated files; SIGUSR1 to kitty |
| `~/.config/hypr/scripts/kde-colors-from-dms.py` + `~/.config/systemd/user/kde-colors-from-dms.{path,service}` | **New.** Merges `DankMatugenDark.colors` into `kdeglobals` on every regeneration, only while kdeglobals is on that scheme. Enabled (symlink in `default.target.wants`) |
| `~/.config/quickshell/shellctl.sh` | **New.** `dnd-status/dnd-on/dnd-off/caffeine-on/caffeine-off` against Noctalia or DMS (by `pgrep -x noctalia`) |
| `~/.config/quickshell/Pomo.qml`, `PomoPanel.qml` | DND/caffeine via `shellctl.sh`; hint text says "the shell's" |
| `~/.config/quickshell/Theme.qml` | Reads the colour file `gtk-4.0/gtk.css` imports (`noctalia.css` or `dank-colors.css`) |
| `~/.config/DankMaterialShell/settings.json` | DMS config mirroring Noctalia (see parity table) |
| `~/.config/DankMaterialShell/plugin_settings.json` | Plugins enabled; recorder `captureSource focused-monitor`, `fps 30`, `outputDir ~/Videos/Recordings` |
| `~/.config/DankMaterialShell/plugins/screenRecorder/` | Local patch adding a `focused-monitor` capture source: `focused-monitor.patch` |
| `~/.config/DankMaterialShell/plugins/hotCorner/` | **New** local plugin |
| `~/.local/state/DankMaterialShell/session.json` | Dark, wallpaper, cycling, stretch, stripes |
| `~/.config/matugen/config.toml`, `templates/btop.theme` | **New.** btop user template for DMS → `btop/themes/dank.theme` |

## Undo
```bash
# 1. back to Noctalia only
sed -i 's/^SHELL_NAME = .*/SHELL_NAME = "noctalia"/' ~/.config/hypr/config/shell.lua
~/.config/hypr/scripts/shell-theme.sh noctalia
# 2. remove DMS
systemctl --user disable --now kde-colors-from-dms.path
rm ~/.config/systemd/user/kde-colors-from-dms.{path,service} ~/.config/hypr/scripts/kde-colors-from-dms.py
rm -r ~/.config/DankMaterialShell ~/.local/state/DankMaterialShell ~/.config/matugen
sudo pacman -Rns dms-shell matugen cava wtype   # not qt6-multimedia: pre-existing
```
`shell.lua`, `shell-theme.sh`, `shellctl.sh` and the pomodoro/Theme changes are harmless
under Noctalia and can stay (or restore the pre-trial copies from git history).

## Notes
- **`screenRecorder` is locally patched** (`cachyos/files/.config/DankMaterialShell/plugins/screenRecorder/focused-monitor.patch`).
  `dms plugins update` would overwrite it; re-apply with `patch -p1` inside the plugin
  folder, or upstream it.
- Don't run `dms setup`: it rewrites compositor configs. DMS is configured only through
  its own settings; the Hyprland Lua config stays hand-written.
- DMS's matugen templates only write **side files** (`kitty/dank-theme.conf`,
  `gtk-*/dank-colors.css`, `qt6ct/colors/matugen.conf`, `alacritty/dank-theme.toml`,
  `color-schemes/DankMatugen*.colors`, `hypr/dms/colors.lua`…); nothing of Noctalia's is
  overwritten. Which set is live is decided only by the include lines `shell-theme.sh` flips.
- After switching back to Noctalia, `kdeglobals`' colour values stay DMS's until Noctalia
  re-applies its KDE scheme (to verify in the live test).
- DMS user matugen config: DMS appends everything from a literal `[templates]` line of
  `~/.config/matugen/config.toml`, so that header must be present.
- Hyprland Lua binds show only as `__lua` in `hyprctl binds`, so mappings were verified by
  running `shell.lua` through a standalone `lua` for both modes.
- Caelestia/DMS source was read from shallow clones in a throwaway scratch folder (DMS at
  tag `v1.6.3`, matching the installed binary).
- DMS config is portable (works on other compositors). It lives here with the trial for
  now; if DMS is kept, split it into its own `dms/` tool folder per the vault rules.
