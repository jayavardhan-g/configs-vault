---
name: ask-before-subjective-choices
description: "Ask before picking an arbitrary/subjective detail (keybinding, naming, cosmetic choice) while implementing a request - don't just pick one and go."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0e323c19-3efb-4da4-a4a8-82fc1dac00f2
  modified: 2026-09-22T14:05:05.208Z
---

When implementing something that requires a pure-preference call with no objectively
"correct" answer - which keybinding to bind a new toggle to, what to name a new file,
which of several equally-valid conventions to follow - propose 1-3 options (or the one
you'd lead with) and ask, rather than silently picking one and implementing it.

**Why:** In the nvim config work (see [[nvim-lazyvim-config-session]]), I picked
`<leader>uo` for a new autocomplete-toggle keymap without asking, then the user pushed
back: "Wouldn't ac be better for autocomplete toggling. Why don't you ask me for my
opinion before you do something?" The binding wasn't technically wrong (verified free,
no collision) - the issue was making a preference decision on the user's behalf instead
of surfacing it as a choice.

**How to apply:** Distinguish preference calls from technical-correctness calls:
- Technical/correctness (verify a keymap doesn't collide, confirm a config option
  actually works, pick the objectively-right fix for a bug) - just do it, no need to ask.
- Pure preference (which free key to use, what to call a new file/variable when multiple
  reasonable names exist, cosmetic/style choices not already established elsewhere in the
  project) - ask first, or at minimum state the choice made and invite a correction before
  moving on to further dependent work.
This applies broadly, not just to Neovim - any session where an implementation detail has
no forcing technical reason to land on one specific value.

<!-- graph:begin -->
**Graph:** [[Neovim]]
<!-- graph:end -->
