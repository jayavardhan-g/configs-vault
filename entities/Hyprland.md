---
type: entity
hub: "[[Desktop]]"
---
# Hyprland

Wayland compositor, the daily-driver session. Config is Lua, split into topic files.

**Hub:** [[Desktop]]
**Config:** `~/.config/hypr/config/*.lua`, `~/.config/hypr/scripts/` (copies in `cachyos/files/.config/hypr/`)
**Related:** [[Noctalia]] · [[Mango]] · [[niri]] · [[Monitors]] · [[uwsm]]

<!-- auto:begin -->
## Entries

- [[mango-border-width-and-color|Mango border width matched to Hyprland; gradient approximated with a flat color]]
- [[mango-cursor-theme|Mango cursor theme matched to Hyprland's]]
- [[mango-unfocused-opacity|Mango transparency: opacity vs. blur, and what's actually live]]
- [[window-decorations|Tighter gaps + orange-only active border]]
- [[right-alt-as-super|Right Alt acts as Super]]
- [[scroll-direction|Scroll direction: Windows-style per device type]]
- [[absolute-workspace-and-monitor-binds|Bare SUPER+num for workspaces, SUPER+bracket for monitors]]
- [[browser-launch-super-b|SUPER+B also launches the browser (alongside SUPER+W)]]
- [[dead-bind-cleanup|Dead-bind cleanup: hyprpicker removed, SUPER+T fixed, SUPER+SHIFT+7 added]]
- [[cachyos/keybindings/display-mode-menu|Windows-style display mode menu: SUPER+P]]
- [[finger-ergonomics|Finger mapping for modifier-heavy keybinds]]
- [[float-toggle|Float toggle rebind: SUPER+ALT+Space → SUPER+SHIFT+F]]
- [[floating-window-nudge|Floating-window nudge on SUPER+ALT (and the session-lock move it forced)]]
- [[kill-mode-cannot-use-escape|Kill mode can't be bound to Escape: SUPER+Escape → SUPER+ALT+Q]]
- [[layout-cycle|SUPER+N cycles layout engine: master → dwindle → scrolling]]
- [[mango-emoji-picker|Ported emoji picker bind (SUPER+.) from Hyprland to Mango]]
- [[power-button-session-menu|Power button opens the session menu instead of powering off]]
- [[resize|Window resizing: submap and reset]]
- [[screenshot-keys|Screenshot keys: Print, SUPER+Print, F6]]
- [[scroller-proportion-preset-remap|Scroller width-preset cycle: ALT+X → SUPER+U]]
- [[special-workspace-toggle|Smart special-workspace (scratchpad) toggle]]
- [[vim-navigation|Vim-style hjkl window navigation]]
- [[wallpaper-picker-on-super-w|Wallpaper picker rebind: SUPER+SHIFT+W → SUPER+W]]
- [[workspace-switching|hjkl workspace switching]]
- [[cachyos-mango-noctalia-setup|Installing cachyos-mango-noctalia alongside an existing cachyos-hypr-noctalia setup]]
- [[dms-trial|DankMaterialShell (DMS) trial: a Noctalia-identical setup, measured against Noctalia]]
- [[limine-snapshot-restore-notification-autostart|Limine snapshot-restore notification never appeared under Hyprland]]
- [[mango-nvidia-cpu-spin-switched-to-hyprland|Switched default session back to Hyprland — Mango has an unresolved NVIDIA GPU-selection bug]]
- [[niri-tried-and-reverted|Tried niri, went back to Hyprland]]
- [[noctalia-greeter-sync-password-prompt|Noctalia greeter-sync password prompt]]
- [[quickshell-pomodoro-widget|Pomodoro widget on SUPER+C (Quickshell, click-through corner timer + stats) — REMOVED]]
- [[uwsm-orphan-autoremove-breaks-login|pacman autoremove took out uwsm, silently broke uwsm-managed Hyprland login]]
- [[vscode-official-build|VSCode (official Microsoft build) + keyring for Settings Sync]]
- [[colresize-unmaximize-first|Scrolling column resize (SUPER+U) un-maximizes first]]
- [[disable-focus-follows-mouse|Disable focus-follows-mouse (sloppyfocus)]]
- [[display-mode-menu-follows-monitors-lua|SUPER+P display-mode menu re-applies monitors.lua]]
- [[master-layout|Master layout (one big window + others share the rest)]]
- [[monitor-gap-blocks-directional-focus|Directional focus across the monitor gap]]
- [[persistent-special-workspace-apps|Auto-relaunch apps into the special workspace, laid out on every start]]
- [[refresh-rate-script-keeps-monitor-layout|Refresh-rate switcher no longer re-places the laptop panel]]
- [[cachyos/window-management/xpad-workspace-and-monitor-persistence|Xpad notes pinned to a monitor-aware workspace 7]]
- [[homeserver-setup|Home server / NAS (the spare CSE-department desktop)]]
- [[appearance-and-input|Appearance and input matched to the Hyprland setup]]
- [[mango/display-mode-menu|Windows-style display mode menu: SUPER+P (ported from Hyprland)]]
- [[keybinds|Keybinds reworked to match the Hyprland setup]]
- [[multi-monitor-setup|Multi-monitor setup: scale, position, workspace count, and monitor keybinds]]
- [[spotify-and-spotx|Spotify (Flatpak, user-scope) + SpotX patch]]
- [[xpad-sticky-notes|Xpad — desktop sticky notes]]
<!-- auto:end -->
