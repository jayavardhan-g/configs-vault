---
name: quickshell-trial-plan
description: Quickshell pomodoro (SUPER+C) removed 2026-10-21 as unused; no qs autostart, no ~/.config/quickshell; side island still shelved
metadata:
  node_type: memory
  type: project
  originSessionId: 23998626-e4c5-4225-a9a4-88bdf9a9f75c
  modified: 2026-10-21T00:00:00.000Z
---

**Removed 2026-10-21 (Jayavardhan: "I'm not using it"):** the pomodoro widget, its
`qs -d` autostart, `~/.config/quickshell/` and `~/.local/share/pomodoro/` (history,
phone-pairing state, Firebase key) are gone. SUPER+C is the calculator again. The
`quickshell` package stays only because `dms-shell` (the DMS trial) depends on it.
Record: `configs/cachyos/system/quickshell-pomodoro-widget.md`; the last QML copies are
in vault commit `d3eb46e`. Its phone side (laptop Focus sync) only existed on the Sync
app's unmerged `feat/focus-sync` branch, i.e. the separate "Sync dev" app. That branch
was deleted 2026-10-21 and archived as tag `archive/feat-focus-sync` in jayavardhan-g/Sync.

**Earlier history:** Quickshell ran next to Noctalia from 2026-10-02 for that widget,
chosen over a Noctalia plugin because Noctalia desktop widgets sit on the Bottom layer
and can't be click-through. A port to Noctalia was evaluated and declined the same day.

**Still shelved (since 2026-09-30):** the left-edge hover "side island" (media + xpad
notes). Its QML is saved in `configs/cachyos/system/quickshell-trial/`, and
`quickshell-trial-shelved.md` holds the gotchas (e.g. Lua dispatch strings).

**How to apply:** don't suggest the pomodoro or Quickshell widgets again unless
Jayavardhan asks. For a desktop-widget request, check Noctalia first
([[noctalia-plugin-registry]], [[lead-with-simpler-options]]); a new Quickshell config
would start from scratch (or from commit `d3eb46e`).

<!-- graph:begin -->
**Graph:** [[Noctalia]] · [[Quickshell]] · [[Xpad]]
<!-- graph:end -->
