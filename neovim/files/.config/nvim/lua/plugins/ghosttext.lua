-- GhostText: edit browser textareas in Neovim.
--
-- The server is our own (lua/ghosttext/), not nvim-ghost.nvim - see the
-- header there for why. Each textarea opens as an unnamed scratch buffer
-- (buftype=nofile) with the filetype the page hinted (Monaco/Ace/CodeMirror
-- language), if any. Two things still need help, and they need different fixes:
--
--   formatting  only needs a filetype -> per-site defaults below, plus the
--               <leader>cL picker (config/keymaps.lua) for anything else.
--   LSP         also needs a file path, and Neovim's auto-attach refuses any
--               buffer whose buftype isn't "" ($VIMRUNTIME/lua/vim/lsp.lua:
--               "Only ever attach to buffers ... that represent an actual
--               file"). Flipping buftype to "" would make Neovim nag about
--               unsaved changes when the field closes, so the buffer stays
--               nofile, is given a name with the right extension, and the
--               matching language servers are started by hand.

-- Sites that should open straight into a language (host -> filetype).
local site_filetypes = {
  ["leetcode.com"] = "cpp",
}

local extensions = {
  c = "c",
  cpp = "cpp",
  python = "py",
  markdown = "md",
  text = "txt",
  lua = "lua",
  sh = "sh",
  javascript = "js",
  typescript = "ts",
  rust = "rs",
  go = "go",
  java = "java",
  json = "json",
  yaml = "yaml",
}

--- Give a ghost buffer a path matching its filetype and attach the language
--- servers for it. Safe to call repeatedly (e.g. when the language changes).
---@param buf integer
local function attach_language(buf)
  local host, ft = vim.b[buf].ghost_host, vim.bo[buf].filetype
  if not host or ft == "" then
    return
  end

  local dir = vim.fn.stdpath("cache") .. "/nvim-ghost"
  vim.fn.mkdir(dir, "p")
  -- buffer number keeps two textareas from the same site from colliding
  local name = ("%s/%s-%d.%s"):format(dir, host:gsub("[^%w%.%-]", "_"), buf, extensions[ft] or ft)
  if vim.api.nvim_buf_get_name(buf) ~= name then
    pcall(vim.api.nvim_buf_set_name, buf, name)
  end

  -- lspconfig loads on file-open events, which a ghost buffer never fires;
  -- a Neovim started only to serve GhostText would otherwise never load it
  require("lazy").load({ plugins = { "nvim-lspconfig" } })

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    local fts = client.config.filetypes
    if fts and not vim.list_contains(fts, ft) then
      vim.lsp.buf_detach_client(buf, client.id)
    end
  end
  for _, config in ipairs(vim.lsp.get_configs({ enabled = true, filetype = ft })) do
    vim.lsp.start(config, { bufnr = buf })
  end
end

return {
  {
    "ghosttext",
    virtual = true, -- lives in lua/ghosttext/, nothing to install
    lazy = false,
    config = function()
      require("ghosttext").setup()

      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("ghost_open", { clear = true }),
        pattern = "GhostTextOpen",
        callback = function(ev)
          local buf = ev.data.buf
          local host = ev.data.host:gsub(":%d+$", ""):gsub("^www%.", "")
          vim.b[buf].ghost_host = host
          if vim.bo[buf].filetype == "" and site_filetypes[host] then
            vim.bo[buf].filetype = site_filetypes[host] -- FileType below attaches
            return
          end
          attach_language(buf)
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ghost_language", { clear = true }),
        callback = function(ev)
          if vim.b[ev.buf].ghost_host then
            attach_language(ev.buf)
          end
        end,
      })
    end,
  },
}
