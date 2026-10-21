---
type: entity
hub: "[[Desktop]]"
---
# Monitors

Laptop panel (eDP-1, 1.2 scale) plus an external monitor: layout, refresh rate, SUPER+P display-mode menu, per-monitor workspaces.

**Hub:** [[Desktop]]
**Config:** `~/.config/hypr/config/monitors.lua`, `~/.config/hypr/scripts/display-mode.sh`, `refresh-rate.sh`
**Related:** [[Hyprland]] · [[Mango]]

<!-- auto:begin -->
## Entries

- [[absolute-workspace-and-monitor-binds|Bare SUPER+num for workspaces, SUPER+bracket for monitors]]
- [[cachyos/keybindings/display-mode-menu|Windows-style display mode menu: SUPER+P]]
- [[mango-focusdir-monitor-wrap-quirk|Known quirk: SUPER+hjkl focus-direction wraps to the other monitor from any edge]]
- [[special-workspace-toggle|Smart special-workspace (scratchpad) toggle]]
- [[workspace-switching|hjkl workspace switching]]
- [[mango-nvidia-cpu-spin-switched-to-hyprland|Switched default session back to Hyprland — Mango has an unresolved NVIDIA GPU-selection bug]]
- [[quickshell-pomodoro-widget|Pomodoro widget on SUPER+C (Quickshell, click-through corner timer + stats) — REMOVED]]
- [[display-mode-menu-follows-monitors-lua|SUPER+P display-mode menu re-applies monitors.lua]]
- [[monitor-gap-blocks-directional-focus|Directional focus across the monitor gap]]
- [[refresh-rate-script-keeps-monitor-layout|Refresh-rate switcher no longer re-places the laptop panel]]
- [[cachyos/window-management/xpad-workspace-and-monitor-persistence|Xpad notes pinned to a monitor-aware workspace 7]]
- [[default-layout-per-tag|Per-tag default layout: scroller for 1-4, fair for tag 5]]
- [[mango/display-mode-menu|Windows-style display mode menu: SUPER+P (ported from Hyprland)]]
- [[known-bugs|Known bug: moving a window onto a monitor with a fullscreen client leaves focus stuck]]
- [[multi-monitor-setup|Multi-monitor setup: scale, position, workspace count, and monitor keybinds]]
- [[screenshots|Screenshots: fixed the broken satty pipeline]]
- [[mango/xpad-workspace-and-monitor-persistence|Tried and reverted: dedicated Xpad tag on Mango]]
- [[xpad-sticky-notes|Xpad — desktop sticky notes]]
<!-- auto:end -->
