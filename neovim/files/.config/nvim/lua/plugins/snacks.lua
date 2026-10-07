-- Snacks settings that differ from LazyVim's defaults.

-- "Open in a new tab page" (pickers: <C-t>, explorer: t). Replaces Snacks'
-- own `tab` action, which loads and lists the file in the *current* tab
-- before running `:tab sbuffer`. With scope.nvim (per-tab buffer lists, see
-- scope.lua) that leaked every file opened this way into the old tab's
-- list. Creating the tab first with `:tabedit` keeps it in the new tab only.
local function open_in_new_tab(picker, item)
  if not item then
    return
  end
  if item.dir then
    -- explorer folder: expand / collapse, like l / <CR>
    return picker:action("confirm")
  end
  local items = picker:selected({ fallback = true })
  if picker.opts.jump and picker.opts.jump.close == false then
    vim.api.nvim_set_current_win(picker.main) -- explorer stays open
  else
    picker:close()
  end
  for _, it in ipairs(items) do
    local path = Snacks.picker.util.path(it)
    if path and not it.dir then
      vim.cmd.tabedit(vim.fn.fnameescape(path))
      if it.pos and it.pos[1] > 0 then
        pcall(vim.api.nvim_win_set_cursor, 0, { it.pos[1], it.pos[2] })
        vim.cmd("normal! zz")
      end
    end
  end
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        actions = {
          tab = open_in_new_tab,
        },
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  -- Open the file under the cursor in a new tab page (on a
                  -- folder it just expands/collapses it, like l / <CR>).
                  -- Pickers use <C-t> for this, but the explorer keeps
                  -- <C-t> for "terminal here" (Snacks' default).
                  ["t"] = "tab",
                },
              },
            },
          },
        },
      },
    },
  },
}
