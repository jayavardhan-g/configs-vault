-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Delete a character without yanking it (plain x overwrites the unnamed
-- register, clobbering whatever you last copied with y)
vim.keymap.set("n", "x", '"_x', { noremap = true, silent = true })

-- Yank to the system clipboard - reaches the LOCAL machine even over SSH
-- via OSC52 (see options.lua). Scoped to <leader>y so plain y/yy don't
-- touch the system clipboard on every internal yank.
local yank_opts = { noremap = true, silent = true }
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', yank_opts)
vim.keymap.set("n", "<leader>Y", '"+y$', yank_opts)

-- VSCode-style comment toggle. Overrides LazyVim's default terminal-toggle
-- binding on this key (<leader>ft/<leader>fT still open a terminal).
-- remap=true is required: "gcc"/"gc" are themselves keymaps (Neovim's
-- built-in comment support, not a raw command), so noremap would try to
-- interpret g/c/c literally instead of dispatching through them.
local comment_opts = { remap = true, silent = true, desc = "Toggle comment" }
vim.keymap.set("n", "<C-/>", "gcc", comment_opts)
vim.keymap.set("n", "<C-_>", "gcc", comment_opts)
vim.keymap.set("v", "<C-/>", "gc", comment_opts)
vim.keymap.set("v", "<C-_>", "gc", comment_opts)

-- Toggle blink.cmp's autocomplete engine on/off at runtime (it gets in the
-- way sometimes). Gated via vim.g.blink_cmp_enabled, checked by the
-- "enabled" function in plugins/completion.lua. Snacks.toggle gives
-- which-key integration (shows on/off state, icon, color) for free.
-- <leader>uC was tried first, but was already taken (LazyVim's colorscheme
-- picker) - confirmed live via nvim_get_keymap, not just by grepping
-- keymaps.lua, since that one is registered outside this file. Settled on
-- <leader>ac ("autocomplete") instead - nothing else is bound under
-- <leader>a at all, confirmed the same way.
-- Starts OFF: autocomplete stays out of the way until <leader>ac turns it on
-- for the session.
vim.g.blink_cmp_enabled = false
Snacks.toggle({
  name = "Autocomplete",
  get = function() return vim.g.blink_cmp_enabled ~= false end,
  set = function(state)
    vim.g.blink_cmp_enabled = state
    if not state then
      pcall(function() require("blink.cmp").hide() end)
    end
  end,
}):map("<leader>ac")

-- Searchable cheatsheet - see lua/cheatsheet.lua for the implementation.
--
-- Key history, so this doesn't get relitigated: bare `?` is native
-- backward-search and stays. `<leader>?` looks free in a headless probe but
-- is claimed by LazyVim (editor.lua, "Buffer Keymaps") - it's a lazy `keys`
-- spec, so the mapping only materialises once which-key loads. `g?` worked
-- fine but was swapped out on request. `??` also works but makes `?` a
-- mapping prefix. `<leader>h` is genuinely unclaimed: no custom mapping, no
-- sub-mappings under it, and no native command lost. Only LazyVim's
-- harpoon2 extra wants `<leader>h`, and that extra isn't enabled here - if
-- it ever is, this is the one that would need moving.
vim.keymap.set("n", "<leader>h", function()
  require("cheatsheet").open()
end, { desc = "Cheatsheet" })

-- Pick the language (filetype) of the current buffer. For buffers with no
-- file extension to go on - GhostText textareas and :enew scratch buffers -
-- where indentation, formatting and the LSP otherwise have nothing to key
-- off. In a ghost buffer, the FileType autocmd in plugins/ghosttext.lua also
-- attaches the language server. Snacks' picker is called directly: plain
-- vim.ui.select is the stock numbered prompt in this setup.
vim.keymap.set("n", "<leader>cL", function()
  local buf = vim.api.nvim_get_current_buf()
  local items, seen = {}, {}
  for _, ft in ipairs({ "cpp", "c", "python", "markdown", "text" }) do
    items[#items + 1], seen[ft] = ft, true
  end
  for _, ft in ipairs(vim.fn.getcompletion("", "filetype")) do
    if not seen[ft] then
      items[#items + 1] = ft
    end
  end
  Snacks.picker.select(items, { prompt = "Language for this buffer" }, function(choice)
    if choice and vim.api.nvim_buf_is_valid(buf) then
      vim.bo[buf].filetype = choice
    end
  end)
end, { desc = "Set Buffer Language" })

-- dm{mark} deletes a mark - the mirror of m{mark} setting one (a convention
-- from mark plugins; Vim itself only has :delmarks). dm- clears every
-- lowercase mark in this buffer. `dm` was free: `m` isn't a motion, so the
-- `d` operator never used it, and dd/dw/d$ etc. still run instantly since
-- no other mapping starts with "d".
vim.keymap.set("n", "dm", function()
  local char = vim.fn.getcharstr()
  if char == "-" then
    vim.cmd("delmarks!")
  elseif char:match("^[%a%d]$") then
    pcall(vim.cmd.delmarks, char)
  end
end, { desc = "Delete mark (dm{mark}, dm- = all in buffer)" })
