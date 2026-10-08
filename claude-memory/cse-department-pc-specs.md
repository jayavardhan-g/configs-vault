---
name: cse-department-pc-specs
description: "Specs of the spare desktop PC Jayavardhan got from the CSE department (DDR3, H97M-D3H, i7-4790K) and his laptop's RAM"
metadata:
  node_type: memory
  type: user
  originSessionId: 92049606-8acf-454a-9fe3-903d33288734
  modified: 2026-10-03T21:24:15.796Z
---

Desktop from the CSE department, set up 2026-10-03/04 as a headless home server/NAS (a
separate machine, NOT the laptop; full runbook in configs repo `homeserver/`). Reachable from
the laptop over Tailscale SSH with key auth. Specs:
- Motherboard: Gigabyte H97M-D3H (Haswell, DDR3 full-size DIMM only)
- CPU: Intel i7-4790K, iGPU only
- RAM: 8 GB DDR3
- Disk: ~460 GB, btrfs

His main machine is a laptop: ASUS ROG Strix G512LU, DDR4-3200 SO-DIMM, 2 physical slots,
1x 16 GB Samsung M471A2K43DB1-CWE installed, 1 slot free (as of 2026-10-03).

**Why:** He asked on 2026-10-03 whether the PC's RAM could go into the laptop. It can't, because the PC uses DDR3 desktop DIMMs and the laptop takes DDR4 SO-DIMMs.
**How to apply:** Use these specs for future hardware or upgrade questions. For laptop RAM, recommend a DDR4-3200 SO-DIMM, ideally 16 GB.

<!-- graph:begin -->
**Graph:** [[Tailscale]] · [[Home server]] · [[SSH]]
<!-- graph:end -->
