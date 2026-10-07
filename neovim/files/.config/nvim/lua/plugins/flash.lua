-- Flash is on LazyVim's default keys: s / S (jump / treesitter jump), plus
-- r / R in operator-pending mode. It sat on gs / gS for a while (to keep
-- Vim's native s = substitute-char and S = substitute-line); moved back to
-- s / S on request, since `cl` and `cc` already do what native s and S did.
--
-- Kept as a file so options have an obvious home, e.g. flash in every `/`
-- search: opts = { modes = { search = { enabled = true } } }.
return {
  { "folke/flash.nvim" },
}
