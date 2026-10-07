return {
  {
    "folke/noice.nvim",
    opts = {
      lsp = {
        signature = {
          -- noice pops up the function signature by itself whenever you type
          -- a trigger character like ( or , - off. <C-k> in insert mode
          -- (gK in normal mode) still shows it on demand; the manual request
          -- goes through the same noice window.
          auto_open = { enabled = false },
        },
      },
    },
  },
}
