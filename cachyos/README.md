# CachyOS + Hyprland config index

Reference/runbook of decisions that are specific to *this CachyOS + Hyprland setup* —
things that wouldn't apply if you swapped window managers or distros. Portable,
tool-specific configs (Vim, Neovim, SSH, VPN client, Spotify) live in their own top-level
folders instead — see `../README.md` for the full repo map. See `../CLAUDE.md` for how
this index is maintained. Each row links to an entry with the full rationale and a
copy-pasteable snippet — pick and choose which ones to reapply on a fresh setup.

Actual copies of the real files these entries touch live under
[`files/`](files/.config/hypr/), mirroring their real path under `$HOME` (e.g.
`~/.config/hypr/config/binds.lua` → `files/.config/hypr/config/binds.lua`) — not just the
inline snippets in each entry, so a fresh machine can overlay-copy them directly.

| Title | Category | Summary | File |
|---|---|---|---|
| Tighter gaps + orange-only active border | appearance | `gaps_in`/`gaps_out` reduced; only the focused window shows a border (orange-to-transparent gradient), unfocused windows borderless | [appearance/window-decorations.md](appearance/window-decorations.md) |
| Mango cursor theme matched to Hyprland's | appearance | Mango shipped with the stock `capitaine-cursors` default; switched to `Bibata-Modern-Ice` size 24 to match Hyprland's real cursor (`~/.config/uwsm/env`) | [appearance/mango-cursor-theme.md](appearance/mango-cursor-theme.md) |
| Scroll direction: Windows-style per device type | input | Mouse wheel traditional, touchpad natural — matches Windows defaults for each device | [input/scroll-direction.md](input/scroll-direction.md) |
| Right Alt acts as Super | input | Swaps Right Alt ↔ Right Win via XKB so Right Alt sends Super | [input/right-alt-as-super.md](input/right-alt-as-super.md) |
| Vim-style hjkl window navigation | keybindings | SUPER+hjkl focus, SUPER+SHIFT+hjkl move window | [keybindings/vim-navigation.md](keybindings/vim-navigation.md) |
| hjkl workspace switching | keybindings | SUPER+CTRL+h/l for previous/next workspace | [keybindings/workspace-switching.md](keybindings/workspace-switching.md) |
| Workspace switching wraps at the ends | keybindings | `tag_carousel = 1` in Mango's `layout.conf` so SUPER+CTRL+h/l cycles 5→1 and 1→5 instead of clamping | [keybindings/mango-workspace-cycle-wrap.md](keybindings/mango-workspace-cycle-wrap.md) |
| Known quirk: SUPER+hjkl focus wraps to the other monitor from any edge | keybindings | Mango's `monitor_from_direction()` falls back to the farthest monitor in the opposite direction when none exists in the requested one — with 2 monitors this means any edge (not just the geometrically correct one) crosses monitors; no config fix exists, would need a source patch + rebuild — declined for now | [keybindings/mango-focusdir-monitor-wrap-quirk.md](keybindings/mango-focusdir-monitor-wrap-quirk.md) |
| Window resizing: submap and reset | keybindings | SUPER+R sticky resize submap (hjkl, Esc to exit), SUPER+SHIFT+R reset; SUPER+CTRL+SHIFT+hjkl direct resize removed | [keybindings/resize.md](keybindings/resize.md) |
| Floating-window nudge on SUPER+ALT (and the end of the session-lock bind) | keybindings | SUPER+ALT+hjkl/arrows nudge a floating window 50px; the dedicated lock bind was moved off SUPER+ALT+L and then dropped for good (use the SUPER+SHIFT+Q session panel); why lock can't live on Windows-style SUPER+L | [keybindings/floating-window-nudge.md](keybindings/floating-window-nudge.md) |
| Kill mode can't be bound to Escape: SUPER+Escape → SUPER+ALT+Q | keybindings | The force-kill picker cancelled itself — Escape is kill mode's own cancel key and the check runs on key release, so the crosshair appeared and vanished on one press; no Escape chord can ever hold it | [keybindings/kill-mode-cannot-use-escape.md](keybindings/kill-mode-cannot-use-escape.md) |
| Wallpaper picker rebind: SUPER+SHIFT+W → SUPER+W | keybindings | SUPER+W and SUPER+B both launched the browser; freed W for the wallpaper picker, dropping it from a two-modifier chord to one | [keybindings/wallpaper-picker-on-super-w.md](keybindings/wallpaper-picker-on-super-w.md) |
| Dead-bind cleanup: hyprpicker, SUPER+T, SUPER+SHIFT+7, xhost | keybindings | Audit of every live bind and autostart line vs. what it invokes: dropped a bind for an uninstalled colour picker, fixed SUPER+T to open nvim inside a terminal, added the missing send-window-to-workspace-7 bind, removed the dead `xhost` autostart line (with what xhost does and why removal is safe) | [keybindings/dead-bind-cleanup.md](keybindings/dead-bind-cleanup.md) |
| Smart special-workspace (scratchpad) toggle | keybindings | SUPER+SHIFT+S sends to special or pulls back out, context-aware | [keybindings/special-workspace-toggle.md](keybindings/special-workspace-toggle.md) |
| Finger mapping for modifier-heavy keybinds | keybindings | Which hand/finger presses what, so the vim-style binds habituate as one consistent pattern | [keybindings/finger-ergonomics.md](keybindings/finger-ergonomics.md) |
| Float toggle rebind: SUPER+ALT+Space → SUPER+SHIFT+F | keybindings | Original combo needed two thumb-modifiers plus a thumb-region key (Space); moved to a clean 3-finger chord | [keybindings/float-toggle.md](keybindings/float-toggle.md) |
| Scroller width-preset cycle: ALT+X → SUPER+U | keybindings | Right Alt sends Super (see right-alt-as-super), so ALT+X only works with left Alt, and X is also a left-hand letter — awkward same-hand chord; moved to a free right-hand letter with single thumb modifier | [keybindings/scroller-proportion-preset-remap.md](keybindings/scroller-proportion-preset-remap.md) |
| Freed bare middle-click from Mango's fullscreen toggle | keybindings | Removed Mango's unmodified `btn_middle` → `togglemaximizescreen` bind, which stole middle-click from apps (e.g. browser); `SUPER+D` still does the same toggle | [keybindings/mango-middle-click-freed.md](keybindings/mango-middle-click-freed.md) |
| Ported emoji picker bind (SUPER+.) from Hyprland to Mango | keybindings | `SUPER+period` never got carried over to Mango's `keybinds.conf`; added `noctalia msg panel-toggle launcher /emo` bind | [keybindings/mango-emoji-picker.md](keybindings/mango-emoji-picker.md) |
| Switched default session back to Hyprland (temporary) | system | Mango intermittently stuck one thread at ~47-51% CPU — `perf` showed a `clock_gettime` busy-loop inside `libnvidia-eglcore.so`, plus unreliable dual-GPU monitor attachment; Hyprland doesn't reproduce either on the same hardware. Revisit when Mango hits 1.0 | [system/mango-nvidia-cpu-spin-switched-to-hyprland.md](system/mango-nvidia-cpu-spin-switched-to-hyprland.md) |
| Limine snapshot-restore notification never appeared under Hyprland | system | Hyprland doesn't run XDG autostart, so `limine-snapper-sync`'s own restore-prompt notification never fired; added `limine-snapper-restore --notify` to Hyprland's own autostart | [system/limine-snapshot-restore-notification-autostart.md](system/limine-snapshot-restore-notification-autostart.md) |
| Noctalia greeter-sync password prompt | system | Disabled `greeter_sync.auto_sync` to stop the password popup on every wallpaper/settings change (a scoped polkit rule isn't feasible — run0 uses random transient unit names) | [system/noctalia-greeter-sync-password-prompt.md](system/noctalia-greeter-sync-password-prompt.md) |
| Noctalia shell chrome shifting to light mode | system | Pinned `theme.shell_mode` (separate from `theme.mode`, wasn't in config.toml at all and had drifted to "follow") to `"dark"` — the bar/panels flipping light while apps stayed dark | [system/noctalia-shell-mode-vs-theme-mode.md](system/noctalia-shell-mode-vs-theme-mode.md) |
| Quickshell: tried alongside Noctalia, side island shelved | system | First Quickshell trial: a bottom bar plus a left-edge hover island with media + xpad notes. The island is shelved, with its QML saved in the repo; Quickshell itself is back in use for the pomodoro widget. Gotchas: Noctalia 5 isn't Quickshell-based, and Hyprland's Lua config needs Lua dispatch strings | [system/quickshell-trial-shelved.md](system/quickshell-trial-shelved.md) |
| Pomodoro widget on SUPER+C (Quickshell) | system | SUPER+C (was the calculator, which keeps XF86Calculator) opens a Timer / Stats / Settings panel with categories. While a cycle runs, a translucent, fully click-through "fused notch" timer sits in the top-right corner of every monitor. Built in Quickshell because Noctalia desktop widgets sit below windows; an earlier cursor-dodging design was dropped because it broke the auto-hide bar | [system/quickshell-pomodoro-widget.md](system/quickshell-pomodoro-widget.md) |
| VSCode (official Microsoft build) + keyring | system | `visual-studio-code-bin` via AUR (needed for Remote-SSH/Marketplace) + gnome-keyring so Settings Sync works under Hyprland — kept here (not in a global vscode/ folder) since the actual problem and fix only exist because Hyprland isn't a Chromium-recognized desktop environment | [system/vscode-official-build.md](system/vscode-official-build.md) |
| Master layout | window-management | One window takes half the screen, rest share the remainder; SUPER+M to swap master | [window-management/master-layout.md](window-management/master-layout.md) |
| Auto-relaunch apps into the special workspace on every start | window-management | Spotify + 3 kitty terminals (claude, labvpn, home) autostart and route straight into the hidden scratchpad workspace | [window-management/persistent-special-workspace-apps.md](window-management/persistent-special-workspace-apps.md) |
| Directional focus across the monitor gap | window-management | SUPER+H/L cross to the nearest on-screen window of the neighbouring monitor at the edge, via a Lua `focus_across` helper. It became possible once `window_direction_monitor_fallback = false` stopped both the fallback's jumps into off-screen scrolling columns and the edge wrap that sank the 2026-09-21 attempt | [window-management/monitor-gap-blocks-directional-focus.md](window-management/monitor-gap-blocks-directional-focus.md) |
| Xpad notes pinned to a monitor-aware workspace 7 | window-management | Workspace 7 follows the external monitor when connected, falls back to the laptop otherwise; notes float unpinned-to-center, survive reboot, and stay put through monitor reconnects | [window-management/xpad-workspace-and-monitor-persistence.md](window-management/xpad-workspace-and-monitor-persistence.md) |
| SUPER+U / SUPER+SHIFT+E un-maximize before resizing the column | window-management | A plain colresize on a maximized (SUPER+D) window left it flagged fullscreen, so it snapped back to full width or went off-screen after a focus change; the binds now toggle fullscreen off first | [window-management/colresize-unmaximize-first.md](window-management/colresize-unmaximize-first.md) |
| SUPER+P display-mode menu re-applies monitors.lua | window-management | The menu hard-coded scale 1.25 and an auto-placed external, which drifted from monitors.lua and left the laptop to the right of the external (x=3570); each mode now clears disabled/mirror, reloads the config, then applies only its own change | [window-management/display-mode-menu-follows-monitors-lua.md](window-management/display-mode-menu-follows-monitors-lua.md) |
| Refresh-rate switcher no longer re-places the laptop panel | window-management | `refresh-rate.sh` (SUPER+ALT+R and the 30 s battery guard) also set eDP-1 to `position = auto`, scale 1.25, putting the laptop right of the external (x=3570) whenever the battery zone changed, e.g. on unplugging the charger; it now passes only `mode` | [window-management/refresh-rate-script-keeps-monitor-layout.md](window-management/refresh-rate-script-keeps-monitor-layout.md) |

## Quick setup from scratch

To reproduce all of the above on a fresh CachyOS + Hyprland (noctalia) install:
1. Copy the `input = {...}` block from `input/scroll-direction.md` and
   `input/right-alt-as-super.md` into `~/.config/hypr/config/inputs.lua`.
2. Copy the `general = { layout = "master" }` line from `window-management/master-layout.md`
   into `~/.config/hypr/config/decorations.lua`.
3. Copy all the `hl.bind(...)` snippets from the `keybindings/` entries into
   `~/.config/hypr/config/binds.lua`, watching for the modifier-relocation notes in each
   file (some binds moved keys to avoid collisions with the vim hjkl binds).
4. `hyprctl reload` (or just save — Hyprland's Lua config auto-reloads on file change).

To reapply only some of these, just copy the individual entries you want — they're
independent of each other except where a "Notes" section says otherwise.
