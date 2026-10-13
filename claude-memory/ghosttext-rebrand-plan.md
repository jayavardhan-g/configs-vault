---
name: ghosttext-rebrand-plan
description: Shelved idea (2026-10-13) - turn the patched GhostText fork into an own-branded extension; open decisions are name, icon, nvim-side rename, fork vs standalone repo
metadata:
  type: project
---

Raised 2026-10-13 and parked "for now, keep it the same": rebrand the add-on built from
the jayavardhan-g/GhostText fork into an extension of our own, inspired by GhostText.

**Already established:**
- Allowed: GhostText is MIT. Keep the copyright and license text, and credit "Based on
  GhostText by Federico Brigante" in the readme.
- Scope: name, add-on id, 6 icon sizes (`source/icons/`), toolbar title, options page,
  and about 29 user-facing "GhostText" strings (notifications, console prefix, links to
  ghosttext.fregante.com - point those at our own readme).
- Keep the GhostText **protocol** (port 4001, same JSON messages), so the Neovim server
  and other GhostText-compatible editors keep working unchanged.
- Release flow stays the same: GitHub Actions on `v*` tags, no npm on the PC.

**Open decisions** (the user's call - ask, don't pick; see [[ask-before-subjective-choices]]):
1. Name - must not contain "GhostText". Ideas offered: NvimField, FieldLink,
   TextBridge, Inkwell.
2. Icon - user-supplied, or a simple one made to a style/colours they give.
3. Neovim side - rename `lua/ghosttext/`, `:GhostTextStatus`/`:GhostTextLog` and the
   `User GhostTextOpen` event to match, or leave them as they are.
4. Repo - keep it as the fork (suggested: upstream fixes still pull in, with conflicts
   limited to the renamed files), or detach into a standalone repo.

**Why:** the fork already holds most of the code that matters, and upstream releases
about once a year, so owning the identity is low-cost. Parked by choice, not blocked.

**How to apply:** if the user brings up rebranding or naming the extension, start from
these decisions rather than re-deriving them. A new add-on id means a fresh install in
Zen (remove the old one; settings reset to defaults). Related: [[ghosttext-custom-stack]],
[[ghosttext-extension]], [[GhostText]].

<!-- graph:begin -->
**Graph:** [[Neovim]] · [[Zen Browser]] · [[GhostText]]
<!-- graph:end -->
