---
name: quickshell-trial-plan
description: Quickshell runs next to Noctalia (autostarted) for the SUPER+C pomodoro; the left-edge side island is still shelved
metadata:
  node_type: memory
  type: project
  originSessionId: 23998626-e4c5-4225-a9a4-88bdf9a9f75c
  modified: 2026-10-02T17:33:10.156Z
---

**2026-10-02:** Quickshell is installed and autostarted (`qs -d` in autostart.lua) next to
Noctalia. It hosts the pomodoro widget on SUPER+C (`~/.config/quickshell/Pomo*.qml`,
recorded in `configs/cachyos/system/quickshell-pomodoro-widget.md`). Jayavardhan chose
Quickshell over a Noctalia plugin because Noctalia desktop widgets sit on the Bottom
layer and can't move. The widget is a click-through, translucent corner notch.

**Port to Noctalia re-evaluated and declined (2026-10-02):**
- Memory: `qs` ~175 MB (Qt/QML baseline) vs Noctalia ~138 MB.
- Noctalia bars can't be click-through and short bars only centre on an edge. Every
  Noctalia placement either covered something (tabs, a scrollbar strip), reserved
  window space (~2%), or was hidden by the auto-hide bar.
- Jayavardhan chose to keep Quickshell for ~1% of RAM. Don't re-propose the port unless
  Noctalia gains click-through or free-positioned overlay surfaces.

**Still shelved (since 2026-09-30):** the left-edge hover "side island" (media + xpad
notes). Its QML is saved in `configs/cachyos/system/quickshell-trial/`, and
`quickshell-trial-shelved.md` holds the gotchas (e.g. Lua dispatch strings).

**Why:** Jayavardhan wants custom widgets that Noctalia's Luau plugins can't do, added
one at a time.

**How to apply:** new widget requests go into the existing `~/.config/quickshell/`
config (add a component and instantiate it in `shell.qml`), not a fresh one. Reuse the
`Theme` singleton (live Noctalia palette) and the `Btn` / `Icon` / `Ring` helpers. First
check whether Noctalia already covers it ([[noctalia-plugin-registry]],
[[lead-with-simpler-options]]).

<!-- graph:begin -->
**Graph:** [[Noctalia]] · [[Quickshell]] · [[Xpad]]
<!-- graph:end -->
