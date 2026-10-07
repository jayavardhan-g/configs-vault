-- Per-tab buffer lists: each tab page only lists the buffers opened in it,
-- so bufferline, H/L and the buffer picker show that tab's files only.
-- Vim's buffers are otherwise global (every tab lists every buffer).
--
-- Sessions: persistence.nvim (LazyVim's session plugin) would restore every
-- buffer into every tab, so scope's per-tab state is saved into the session
-- (needs "globals" in sessionoptions - LazyVim already sets it) and put back
-- after a restore.
return {
  {
    "tiagovla/scope.nvim",
    event = "VeryLazy",
    opts = {},
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceSavePre",
        callback = function()
          pcall(vim.cmd.ScopeSaveState)
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceLoadPost",
        callback = function()
          pcall(vim.cmd.ScopeLoadState)
        end,
      })
    end,
  },
}
