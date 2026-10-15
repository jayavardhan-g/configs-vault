---
name: dms-trial-plan
description: DMS vs Noctalia measured 2026-10-16 — DMS 434 MB PSS vs Noctalia 116 MB at 30 min; switch via SHELL_NAME in hypr/config/shell.lua; keep/remove decision pending
metadata:
  type: project
---

**2026-10-15:** Jayavardhan wants a measured (not estimated) comparison of a full
Quickshell-based shell vs Noctalia 5 (native C++). Target is **DankMaterialShell**
(`dms-shell`, official `extra` repo), chosen over Caelestia (vertical-only bar, needs
quickshell-git, 7 AUR packages). He wants DMS configured **identical** to Noctalia first
(top bar, widgets, auto-hide, binds, theming) so no feature is silently lost and the
numbers compare the same feature set.

**Why:** decide whether to switch shells on evidence; baseline was Noctalia 114 MB PSS +
pomodoro `qs` 87 MB PSS.

**How to apply:** the single source of truth is the vault entry
`configs/cachyos/system/dms-trial.md` — keep its **Packages** ledger (every package
installed, repo, why, status) and dated **Log** updated with every step; he explicitly
asked for this. Never run `dms setup` (rewrites compositor configs). Noctalia stays
default until he decides. Measure both shells fresh (PSS at 1/5/30 min).

**Result 2026-10-16** (fresh starts, 30 min, same features): Noctalia 116 MB PSS, flat,
1.56% avg CPU; DMS (frame off) 434 MB PSS and still climbing, 2.14% avg CPU. Don't re-propose
switching to a full QML shell for memory. He declined DMS's connected frame (wastes space,
glitchy). Both shells stay switchable: `SHELL_NAME` in `~/.config/hypr/config/shell.lua` +
logout. Pending: his keep/remove decision on DMS (Undo section of the vault entry).

Related: [[quickshell-trial-plan]], [[lead-with-simpler-options]], [[ask-before-subjective-choices]]

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Noctalia]] · [[Quickshell]] · [[DankMaterialShell]] · [[CachyOS]]
<!-- graph:end -->
