# GhostText (edit browser text in Neovim)

**Category:** neovim
**Files touched:** `lua/plugins/ghosttext.lua`, `lua/config/keymaps.lua` (all under `~/.config/nvim/`; copies in [`files/`](files/))

<!-- graph:begin -->
**Graph:** [[Neovim]]
<!-- graph:end -->

nvim-ghost.nvim setup: per-site languages, formatting and LSP in ghost buffers, and the `<leader>cL` language picker. Part of the LazyVim setup - see [[lazyvim-migration]] for the migration itself and the index of all topic files.

Entries are in the order they happened. They were split out of `lazyvim-migration.md` on 2026-09-23 without rewording, so "above" and "previous follow-up" refer to entries in this file unless a link says otherwise.

## Follow-up: GhostText buffers get a language, formatting and LSP (2026-09-23)

**What**: text opened from the browser via GhostText (`nvim-ghost.nvim`) had no file
extension, so formatting, indentation and the LSP didn't work in it. Asked for either a
way to give the temporary buffer an extension, or at least apply a language's rules.

**Also found: nvim-ghost was never recorded here.** `lua/plugins/ghosttext.lua` existed
in the live config but was absent from `files/` and from every changelog entry, so a
fresh-machine rebuild from this repo would have silently dropped GhostText entirely.
Now tracked.

**Root cause - two separate problems, found by testing each in isolation**:
- nvim-ghost creates each textarea as an **unnamed `nofile` scratch buffer**, and sets
  the filetype from the browser's `syntax` hint (`binary.py`: `filetype =
  data["syntax"]`) - usually empty for a plain textarea, sometimes a MIME type such as
  `text/x-c++src` that isn't a Neovim filetype at all.
- With a filetype set, **formatting already works** (conform ran `clang-format` on the
  scratch buffer fine). The **LSP does not**: it stays at 0 clients. Tested the
  variants: unnamed+`nofile` no; named+`nofile` no; named+normal buftype **yes**. The
  gate is in Neovim itself - `$VIMRUNTIME/lua/vim/lsp.lua`, `lsp_enable_callback`:
  "Only ever attach to buffers ... that represent an actual file", rejecting any
  `buftype` other than `""` / `help`.

**Why not just make it a normal buffer**: nvim-ghost closes ghost buffers with a plain
`:bdelete N` (`binary.py`, `handle_close`), which **refuses** a modified normal buffer
("No write since last change") - the tab would get stuck open when the page closes.
Instead: keep it `nofile`, give it a real **name with the right extension**
(`~/.cache/nvim/nvim-ghost/<host>-<bufnr>.<ext>`, bufnr so two textareas from one site
don't collide), and **start the matching servers by hand** with
`vim.lsp.start(config, { bufnr })` for each `vim.lsp.get_configs({ enabled = true,
filetype = ft })` - that path has no buftype gate. Verified `bdelete` still succeeds
afterwards. Nothing is written to disk.

Also needed: `nvim-lspconfig` is lazy-loaded on file-open events (LazyVim's `LazyFile`
= `BufReadPost`/`BufNewFile`), which a ghost buffer never fires - so a Neovim started
purely to serve GhostText would never load it. `require("lazy").load(...)` handles it.
(Note while testing: `doautocmd User LazyFile` does **not** trigger that - `LazyFile`
is a lazy.nvim event alias, not a real User event.)

**Decisions** (asked, per the preference rule): per-site defaults + a picker;
**`leetcode.com` -> C++** as the only site default for now; picker on **`<leader>cL`**
(checked free at runtime *and* by grepping LazyVim core + extras - and the runtime
probe was sanity-checked against known-taken keys this time); picker works in **every**
buffer, not just ghost ones - which also fixes the earlier-reported odd
indentation/autopairs in plain `:enew` scratch buffers, since they have no filetype
either.

**Change**:
- `lua/plugins/ghosttext.lua` - `site_filetypes` table (host -> filetype); a `User`
  autocmd in nvim-ghost's own `nvim_ghost_user_autocommands` group (the plugin only
  creates that group if it doesn't already exist, so ours isn't clobbered) that tags
  the buffer with its host and applies the site default when the browser hint isn't a
  real filetype; a `FileType` autocmd that, for tagged buffers, names the buffer and
  (re)attaches servers - detaching ones that don't serve the new filetype.
- `lua/config/keymaps.lua` - `<leader>cL`: `Snacks.picker.select` over your languages
  first (cpp, c, python, markdown, text) then every other filetype. Calls Snacks
  directly because `vim.ui.select` is the stock numbered prompt in this setup (checked).

**A real bug caught by testing before it shipped**: the first version's `User`
autocmd used pattern `*`, which fires for **every** plugin's plain `doautocmd User
Foo`, not just nvim-ghost's - lazy.nvim alone fires `VeryLazy`, `LazyRender`,
`LazyDone`. In testing, a ghost buffer got retagged with host `LazyRender` and renamed
`LazyRender-4.py`; worse, any unnamed `nofile` plugin UI buffer that happened to be
current (the `:Lazy` window is one) could have been tagged and renamed. Fixed by only
accepting an event whose name looks like a hostname (has a dot, or is `localhost`).
Re-verified: a plugin UI buffer hit with foreign `User` events stays untagged and
unnamed, and the ghost buffer keeps its real host.

**Verified live** (simulating nvim-ghost's exact buffer creation + event):
leetcode.com -> `ft=cpp`, `buftype=nofile`, named `leetcode.com-2.cpp`, clangd
attached, error diagnostic reported; github.com (no default) stays plain; switching a
ghost buffer cpp -> python detaches clangd and attaches ruff; `bdelete` clean. Picker:
opens with cpp/c/python/markdown/text first, choosing python sets `ft=python`, and
Python auto-indent then works after `def f():` in an `:enew` buffer. (Headless tests
must force the picker to re-match after setting its input - an earlier "chose python,
got cpp" result was that artifact, confirmed by checking the filtered list before
confirming.)

**Cheatsheet**: new "GhostText & buffer language" category (3 entries), plus
`<leader>cL` in the customizations summary. Keymap coverage 280/284, same four known
non-gaps. Note: format-on-save never fires in ghost buffers (never written) - documented
to use `<leader>cf` before submitting.
