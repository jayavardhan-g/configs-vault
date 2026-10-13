---
name: ghosttext-custom-stack
description: GhostText here is custom - own Lua server in nvim config + patched unsigned add-on in Zen; rebuild with build.py after upstream updates
metadata:
  type: project
---

Since 2026-10-12 GhostText doesn't use nvim-ghost.nvim or the AMO add-on. The server
is `~/.config/nvim/lua/ghosttext/` (hub on port 4001, per-instance WebSocket ports,
`:GhostTextStatus`, `User GhostTextOpen` event). The browser side is a patched build
of GhostText 26.5.12 (`neovim/ghosttext-extension/`, id `ghosttext-patched@configs.local`),
installed unsigned in Zen with `xpinstall.signatures.required=false`.

**Why:** upstream had bugs that broke multi-line edits, rich-text fields and current
CodeMirror 6, and nvim-ghost's server raced its own threads - see [[ghosttext-shortcomings-audit]]
and [[ghosttext]].

Since 2026-10-13 the add-on source is the fork jayavardhan-g/GhostText (`patched`
branch, clone `~/claude/GhostText`); releases are built by GitHub Actions on `v*` tags
only. The user wants **no npm installed locally** - never run npm/node builds on the PC;
tag and let GitHub build.

**How to apply:** for any GhostText problem, start from those notes and run the test
suites in `neovim/ghosttext-extension/tests/`, not nvim-ghost docs. If Zen auto-updates
or GhostText upstream moves past 26.5.12, `build.py` refuses to build; re-check its
patches against the new minified files. Don't suggest reinstalling nvim-ghost or the
AMO GhostText. Related: [[GhostText]], [[Neovim]], [[Zen Browser]].

<!-- graph:begin -->
**Graph:** [[Neovim]] · [[Zen Browser]] · [[GhostText]]
<!-- graph:end -->
