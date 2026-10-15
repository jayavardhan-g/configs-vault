-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Replaces LazyVim's resize_splits (same augroup name, so it's cleared and
-- redefined): equalize every tab's windows when the terminal is resized, but
-- via nvim_win_call instead of `tabdo wincmd =`. :tabdo won't start from a
-- window with 'winfixbuf' set (leetcode.nvim sets it on its code, description
-- and menu windows): it jumps to the previous window instead, or splits a new
-- one when that's fixed too. So moving/resizing the kitty window from
-- Hyprland while in a LeetCode question kept moving focus into the console or
-- splitting the code window. nvim_win_call visits each tab without :tabdo.
vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("lazyvim_resize_splits", { clear = true }),
  callback = function()
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      vim.api.nvim_win_call(vim.api.nvim_tabpage_get_win(tab), function()
        vim.cmd("wincmd =")
      end)
    end
  end,
})
