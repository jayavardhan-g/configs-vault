---
name: dms-trial-plan
description: In-progress trial (started 2026-10-15) — DankMaterialShell configured identical to Noctalia, then memory/CPU measured; package ledger + log live in the vault entry
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

Related: [[quickshell-trial-plan]], [[lead-with-simpler-options]], [[ask-before-subjective-choices]]

<!-- graph:begin -->
**Graph:** [[Noctalia]] · [[Quickshell]] · [[DankMaterialShell]] · [[CachyOS]]
<!-- graph:end -->
