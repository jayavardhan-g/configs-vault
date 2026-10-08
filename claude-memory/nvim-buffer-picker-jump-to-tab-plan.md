---
name: nvim-buffer-picker-jump-to-tab-plan
description: "shelved: make <leader>fB (all buffers) jump to the tab page that holds the buffer, using scope.nvim's per-tab cache"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f3fb706-f4ce-4b17-9eba-1aac22507c50
  modified: 2026-10-04T17:32:49.982Z
---

Shelved on 2026-10-04 ("leave it for future work"). With scope.nvim (per-tab buffer lists, `~/.config/nvim/lua/plugins/scope.lua`), Snacks' `<leader>fB` "Buffers (all)" opens the picked buffer in the *current* tab, and it then joins this tab's list. User wanted to know whether it jumps to the buffer's own tab; it doesn't.

Idea: custom confirm action on `<leader>fB`. Look the buffer up in `require("scope.core").cache[tabhandle]` (only refreshed on TabLeave, so use live `buflisted` for the current tab). Then `nvim_set_current_tabpage` + `:buffer`, falling back to opening it in the current tab. Snacks' built-in `drop` action isn't enough: its `find_win()` only finds buffers *visible in a window* in another tab, not ones sitting in that tab's hidden list.

**Why:** the user declined a separate tab-page picker ("searching through all buffers is enough"); only this jump behaviour was deferred.

**How to apply:** if they bring up cross-tab buffer search again, start from this; a key choice may be needed ([[ask-before-subjective-choices]]).

<!-- graph:begin -->
**Graph:** [[Neovim]]
<!-- graph:end -->
