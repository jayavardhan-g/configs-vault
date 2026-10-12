vim.opt.rtp:prepend(vim.fn.expand("~/.config/nvim"))
vim.o.swapfile = false
local g = require("ghosttext")
g.setup({ port = tonumber(vim.env.TEST_PORT) })
g.start()
vim.api.nvim_create_autocmd("User", { pattern = "GhostTextOpen", callback = function(ev)
  _G.opened = { buf = ev.data.buf, host = ev.data.host, cur = vim.api.nvim_get_current_buf() }
end })
