---
name: noctalia-switcher-previews-shelved
description: "resolved by upgrades: Noctalia Super+Tab switcher shows live window previews since ~2026-10-05 (was icons-only because Hyprland couldn't capture hidden windows)"
metadata:
  node_type: memory
  type: project
  originSessionId: cb75de1d-21dd-4420-a36a-a194cd4e219c
  modified: 2026-10-07T14:00:28.756Z
---

Noctalia's window switcher (Super+Tab, `noctalia msg window-switcher`) is designed to show window snapshots with a small icon overlay; there is no setting for it.

**History:** on Hyprland 0.56.2-3.1 + Noctalia 5.2.0 (checked 2026-10-01) snapshots failed and cards fell back to big app icons. `grim -T <stableId>` hung for hidden windows (behind others, other workspaces, hidden special workspace). Jayavardhan decided then it wasn't worth chasing.

**Now fixed by upgrades, no config change (confirmed 2026-10-07):** `grim -T` captures hidden windows instantly (Zen on workspace 4, kitty in the hidden special workspace) and the switcher shows live previews. Candidates, not isolated further:
- Noctalia 5.2.1 (2026-10-03): release notes say it retains "the capture handles needed for previews".
- Hyprland 0.56.2-4.1 (2026-10-05): same upstream commit, a "clean" rebuild (no source patches).
- linux-cachyos 7.2.4 → 7.2.9 with nvidia-open (2026-10-05).
Since `grim` (which doesn't use Noctalia) now works too, the compositor/driver side changed as well, not only Noctalia.

**How to apply:** if previews break again after an update, re-run `grim -T <stableId>` on a hidden window first, to tell a compositor regression from a Noctalia one. Web-AI suggestions like `live_render` / `fps_limit` / `noctalia daemon` are invented.

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Noctalia]] · [[kitty]] · [[NVIDIA]] · [[Zen Browser]]
<!-- graph:end -->
