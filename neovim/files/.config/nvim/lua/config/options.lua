-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- LazyVim defaults shiftwidth/tabstop to 2 for every filetype - too narrow
-- for this setup's languages (C/C++/Python/Markdown/text). 4 spaces
-- everywhere instead; expandtab (spaces not tabs) is already LazyVim's
-- default and stays as-is.
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

-- Over SSH only, register OSC52 as the provider for the "+"/"*" registers
-- so <leader>y (see keymaps.lua) still reaches the LOCAL machine's
-- clipboard with no X/Wayland forwarding (kitty understands OSC52 both
-- locally and over SSH). Left alone entirely when not over SSH - wl-copy
-- already works fine there via LazyVim's own unnamedplus default and
-- Neovim's built-in provider auto-detection; overriding it unconditionally
-- would replace that working local path with OSC52 escape codes too.
if vim.env.SSH_CONNECTION then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end

-- Diagnostics (LSP errors/warnings: signs, underlines, inline text) start
-- hidden everywhere - they're distracting while still typing. <leader>ud
-- (LazyVim's Snacks toggle) turns them back on for the session. The LSP
-- still computes them while hidden, so toggling on shows them instantly.
vim.diagnostic.enable(false)
