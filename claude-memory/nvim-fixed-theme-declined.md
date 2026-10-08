---
name: nvim-fixed-theme-declined
description: declined: fixed Neovim theme + transparency; colors/kitty.lua keeps following the Noctalia palette
metadata:
  type: project
---

2026-10-07: Jayavardhan asked whether a fixed Neovim theme with a transparent background would handle changing contrast better. Answer was no: the visible background is kitty's Noctalia-generated bg at background_opacity 0.6 plus the wallpaper showing through, so a fixed theme would only lock the text colours against a background that keeps changing. colors/kitty.lua takes its text colours from the same palette as that background. Jayavardhan chose to leave it as is.

**Why:** the contrast risks are wallpaper bleed-through (fixable by kitty opacity/blur) and deliberately faint highlight groups (fixed one at a time), not the theme itself.

**How to apply:** don't re-suggest a fixed theme. If contrast complaints come up, offer: raise kitty opacity or blur, live-reload colors/kitty.lua on Noctalia palette change, or fix the individual highlight group.

<!-- graph:begin -->
**Graph:** [[Noctalia]] · [[kitty]] · [[Neovim]]
<!-- graph:end -->
