---
name: alt-tab-carousel-declined
description: "declined: ALT+Tab as a same-workspace Noctalia carousel isn't possible per-bind; user kept plain cycle_next"
metadata:
  node_type: memory
  type: project
  originSessionId: df583c43-ad59-4f52-a250-413774fcabe5
  modified: 2026-10-02T04:36:34.556Z
---

Asked 2026-10-02 for ALT+Tab to show a carousel like SUPER+Tab (`noctalia msg window-switcher`), but only for the current workspace's windows. Noctalia 5.2's `window-switcher` IPC takes no scope argument; workspace filtering is only the global `[shell.window_switcher] current_workspace_only` setting, which would also change SUPER+Tab.

**Why:** user was offered (a) both switchers workspace-only, (b) a wrapper script that flips the setting and runs `config-reload` on every press, or (c) revert. They chose to revert: ALT+Tab stays `hl.dsp.window.cycle_next()` and SUPER+Tab stays the all-windows carousel.
**How to apply:** don't propose this again unless the user asks, or a newer Noctalia adds a per-call scope to `window-switcher`. Related: [[noctalia-switcher-previews-shelved]].

<!-- graph:begin -->
**Graph:** [[Noctalia]]
<!-- graph:end -->
