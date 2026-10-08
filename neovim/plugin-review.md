# Plugin-by-plugin review

**Category:** neovim
**Files touched:** `lua/plugins/disabled.lua`, `lua/plugins/flash.lua`, `lua/plugins/gitsigns.lua`, `lua/plugins/todo-comments.lua` (all under `~/.config/nvim/`; copies in [`files/`](files/))

<!-- graph:begin -->
**Graph:** [[Neovim]]
<!-- graph:end -->

The one-by-one pass over LazyVim's optional plugins: tested live, then kept, adjusted or disabled. Final verdict table is in the last entry. Part of the LazyVim setup - see [[lazyvim-migration]] for the migration itself and the index of all topic files.

Entries are in the order they happened. They were split out of `lazyvim-migration.md` on 2026-09-23 without rewording, so "above" and "previous follow-up" refer to entries in this file unless a link says otherwise.

## Follow-up: freed s/S from flash.nvim, moved it to gs/gS (2026-09-22)

> **Superseded 2026-09-28**: flash is back on LazyVim's default `s`/`S` - see
> "flash back on s/S" below. The rest of this entry is the history.

**What**: began going through LazyVim's optional plugins one at a time (test live, then
decide keep/remove) as a review process - `flash.nvim` (jump-to-visible-location) was
first. It works well, but its default LazyVim binding is `s`/`S` in normal/visual/
operator-pending mode, which steals Vim's native substitute-char (`s`) and
substitute-line (`S`) - both muscle memory in daily use. Moved flash to `gs`/`gS`
instead, freeing `s`/`S` back to native.

**Why gs/gS specifically**: `<leader>s` was considered first, but it's not a free key -
it's LazyVim's "Search" group prefix with 30+ sub-bindings (`<leader>sg` grep, `<leader>sq`
quickfix, `<leader>su` undotree, `<leader>sh` help, etc. - confirmed live via
`nvim_get_keymap`). Making `<leader>s` itself a complete flash binding would force a
timeout-based disambiguation delay on every single one of those existing search
commands - not worth it for this. `gs`/`gS` confirmed genuinely free (native `gs` is an
obscure, essentially-unused "sleep N seconds" command) - same 2-keystroke-then-target
feel as the original binding, no leader delay.

**Change** - `~/.config/nvim/lua/plugins/flash.lua` (new):
```lua
return {
  {
    "folke/flash.nvim",
    -- stylua: ignore
    keys = {
      { "s", false, mode = { "n", "x", "o" } },
      { "S", false, mode = { "n", "o", "x" } },
      { "gs", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "gS", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },
}
```
`false` as the second positional element of a `keys` entry is lazy.nvim's documented way
to disable one specific default-provided keymap without touching the rest of the spec
(confirmed in `lazy.nvim`'s own `core/handler/keys.lua`) - `r`/`R` (operator-pending
remote flash) and `<c-s>`/`<c-space>` (cmdline toggle, treesitter incremental selection)
are untouched since they don't collide with anything.

**Verified live**: headless Neovim, forced `VeryLazy`. `nvim_get_keymap` confirms `s`/`S`
are no longer registered at all (native Vim behavior applies) and `gs`/`gS` resolve to
`Flash`/`Flash Treesitter`. End-to-end: normal-mode `s` on `hello world` correctly
deletes the character under cursor and enters insert mode (produced `XXello world` after
typing `XX`) - exactly native substitute-char behavior.

**Process note**: this is the first of a plugin-by-plugin review pass (test live -> keep
or remove/adjust -> next plugin) - more follow-ups in this vein will land here as they're
decided. Core infrastructure plugins that can't be meaningfully tested standalone
(`lazy.nvim`, `LazyVim`, `plenary.nvim`, `nui.nvim`, `mini.icons`, `mason.nvim`/
`mason-lspconfig.nvim`, `nvim-lspconfig`, `nvim-treesitter` core) are being skipped in
this review; `blink.cmp` and `mini.pairs` already have their own runtime toggles
(`<leader>ac`, `<leader>up`) so don't need a keep/remove decision here.

## Follow-up: gitsigns popup hunk preview on `<leader>ghP` (2026-09-22)

**What**: second plugin in the one-by-one review - `gitsigns.nvim`. LazyVim's default
`<leader>ghp` (`preview_hunk_inline`) hit two real limits while testing: long lines get
cut off with no way to wrap (confirmed against Neovim's own extmark API - `virt_lines`
only supports `trunc`/`scroll`, `wrap` is rejected outright:
`Invalid 'virt_lines_overflow': 'wrap'`), and the preview closes on *any* cursor
movement (`CursorMoved` autocmd in gitsigns' own source), so you can't scroll through a
tall hunk either. Added `<leader>ghP` for the non-inline `preview_hunk` (floating popup)
instead of replacing the inline one, and called a second time while already open it moves
focus into the window so `j`/`k` scroll freely without closing it (confirmed this works
after initially looking like the same closing bug - the first call only opens the popup,
cursor stays in the original window; the second call is what actually focuses in).

**Correction (still 2026-09-22, caught same day)**: initially described the popup as
"real wrapping" - checked directly and that's wrong, **the popup doesn't wrap either**
(`vim.wo[winid].wrap` is `false`, confirmed live; no wrap-related option is ever set
anywhere in `gitsigns/popup.lua`). What it actually does: auto-**widens** the floating
window to fit the hunk's longest line (verified live - a ~250-char test line produced a
266-column-wide popup), so on a normal terminal most long lines just fit without any
extra step. For a line wider than the actual terminal, the popup is a real window/buffer
(unlike inline's virtual-lines overlay), so once focused into it (the 2nd-call trick
above), ordinary `nowrap`-window horizontal scrolling (`$`, `zl`, etc.) reaches the rest
of the line - same net result (you can always see 100% of a line) but via width-then-
scroll, not word-wrap.

**Change** - `~/.config/nvim/lua/plugins/gitsigns.lua` (new):
```lua
return {
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      local on_attach = opts.on_attach
      opts.on_attach = function(buffer)
        if on_attach then
          on_attach(buffer)
        end
        vim.keymap.set(
          "n",
          "<leader>ghP",
          function() require("gitsigns").preview_hunk() end,
          { buffer = buffer, desc = "Preview Hunk (Popup)" }
        )
      end
      return opts
    end,
  },
}
```
Wraps (doesn't replace) the default `on_attach` so LazyVim's other 10 `gh*` bindings
stay intact - kept buffer-local (`buffer = buffer`) rather than global, matching how the
rest of gitsigns' keymaps behave (only present in buffers gitsigns actually attaches to,
i.e. git-tracked files).

**Verified live**: headless Neovim, opened a real file inside this git repo, forced
`VeryLazy` + `LazyFile`. Confirmed `<leader>ghP` registers as a **buffer-local** keymap
(not global) with `desc = "Preview Hunk (Popup)"`, and all 10 of LazyVim's original
`gh*` mappings (`s`, `r`, `S`, `u`, `R`, `p`, `b`, `B`, `d`, `D`) are still present
alongside it - the `on_attach` wrap didn't drop anything.

**`flash.nvim` decision**: kept, no changes beyond the `gs`/`gS` rebind from the
previous follow-up. (Later reverted to `s`/`S` - see the Superseded note on that follow-up.)

## Follow-up: `<leader>ghP` now auto-focuses in one keypress (2026-09-22)

**What**: previously `<leader>ghP` opened the popup but left focus in the original
window - needed pressing it a second time to actually move focus in for scrolling.
Changed it to call `gs.preview_hunk()` twice within the single keymap callback, so one
keypress does both (open, then focus) instead of requiring a second manual press.

**Why this is safe to call twice back-to-back with no delay**: `preview_hunk()`'s own
first lines are `if popup.is_open('hunk') then popup.focus_open('hunk'); return end` -
i.e. calling it while already open is the officially-intended way to focus in, not a
workaround. Tested whether the two calls needed a `vim.schedule`/delay between them in
case window creation is async - checked directly (headless, two synchronous calls with
no `vim.wait` in between): current window ends up being the popup, not the original,
confirming no delay is needed - hunk data is already cached from gitsigns' background
tracking, so window creation completes synchronously within the same call.

**Change** - `~/.config/nvim/lua/plugins/gitsigns.lua`:
```lua
vim.keymap.set("n", "<leader>ghP", function()
  local gs = require("gitsigns")
  gs.preview_hunk()
  gs.preview_hunk()
end, { buffer = buffer, desc = "Preview Hunk (Popup, focused)" })
```

**Verified live**: headless Neovim, real git repo, simulated the actual `<leader>ghP`
keypress (not just calling the Lua function directly). Confirmed via
`nvim_get_current_win()` that focus ends up on the floating popup window
(`relative = "win"`), not the original file window, after a single keypress.

## Follow-up: plugin review results so far (2026-09-22)

Continuing the one-by-one review pass:
- `persistence.nvim` (session save/restore per project) - tested live, **kept**, no
  changes - already just LazyVim's default.
- `nvim-treesitter-textobjects` (`]f`/`[f`/`]c`/`[c`/`]a`/`[a` - jump between
  function/class/parameter boundaries) - tested live, **not useful, disabled**. Note
  this is unrelated to `mini.ai` (the `af`/`if`/`daf`/etc. select-a-function plugin),
  which stays - LazyVim splits "jump between" and "select" into two separate plugins.

**Change** - `~/.config/nvim/lua/plugins/disabled.lua`, appended:
```lua
{ "nvim-treesitter/nvim-treesitter-textobjects", enabled = false },
```

**Verified live**: headless Neovim, forced `VeryLazy`. Confirmed the plugin no longer
appears in `require('lazy').plugins()` at all, and `]f` has no buffer-local keymap in a
`.cpp` buffer (previously bound by this plugin).

## Follow-up: mini.ai disabled (2026-09-22)

**What**: `mini.ai` (`af`/`if`/`daf`/`diu`/`dae` etc. - select function/class/call/
camelCase-segment as a text object) - tested live, decided not needed. Unrelated to
`mini.pairs` (autopairs), a separate mini.nvim module - stays enabled.

**Change** - `~/.config/nvim/lua/plugins/disabled.lua`, appended:
```lua
{ "nvim-mini/mini.ai", enabled = false },
```

**Verified live**: headless Neovim, forced `VeryLazy`. Confirmed `mini.ai` no longer
appears in `require('lazy').plugins()`.

## Follow-up: nvim-lint disabled (2026-09-22)

**What**: `nvim-lint` - decided not needed after discussing what linters actually add on
top of formatters/LSP diagnostics. Concretely checked this setup's actual state first:
**C++ has no LSP attached at all** (not clangd, nothing - confirmed live, a bigger gap
than "no linter"), and **Python's `ruff` already attaches as an LSP** (side effect of
installing it as a conform.nvim formatter - see [[languages-and-lsp]]) and surfaces its own
lint diagnostics inline already - making a separate `nvim-lint` + ruff wiring redundant
for Python specifically. No linter was ever configured for any language in use anyway
(`linters_by_ft` only had `fish` by default).

**Change** - `~/.config/nvim/lua/plugins/disabled.lua`, appended:
```lua
{ "mfussenegger/nvim-lint", enabled = false },
```

**Verified live**: headless Neovim, forced `VeryLazy`. Confirmed `nvim-lint` no longer
appears in `require('lazy').plugins()`.

**Flagged, not yet acted on**: C++ has zero LSP (`clangd`) set up - no diagnostics,
go-to-definition, or hover for C/C++ at all currently. This is a separate, bigger
decision than the linter question - revisit if/when C++ tooling depth becomes a priority.

## Follow-up: plugin review - noice/bufferline kept, trouble.nvim disabled (2026-09-22)

- `bufferline.nvim` (tab-style open-buffers bar) - tested live, **kept**, no changes.
- `noice.nvim` (floating cmdline/messages/popup UI) - tested live, **kept**, no changes.
- `grug-far.nvim` (project-wide search/replace UI) - discussed the built-in
  quickfix-based alternative (`:grep` + `:cfdo s///g | update` - `rg` already installed
  and wired as `grepprg`, confirmed live), which needs no plugin but has no live preview.
  **Kept** grug-far for the preview.
- `trouble.nvim` (diagnostics/symbols/references panel) - tested live, **not needed,
  disabled**.

**Change** - `~/.config/nvim/lua/plugins/disabled.lua`, appended:
```lua
{ "folke/trouble.nvim", enabled = false },
```

**Verified live**: headless Neovim, forced `VeryLazy`. Confirmed `trouble.nvim` no
longer appears in `require('lazy').plugins()`.

## Follow-up: todo-comments.nvim kept, fixed its 4 dead keymaps (2026-09-22)

**What**: `todo-comments.nvim` tested live and kept. Its LazyVim default keymaps include
2 that depend on `trouble.nvim` (disabled in the previous follow-up) and 2 that depend on
Telescope - which isn't installed in this setup **at all** (picker is `snacks`, confirmed
via `lazyvim_picker`/the actual installed plugin list) - so all 4 would error if pressed.
Confirmed live before deciding what to do: `TodoTelescope` and `TodoTrouble` both fail.

**Decision** (asked, since this had real options): `<leader>xt`/`<leader>xT`
(Trouble-dependent) dropped outright - no working replacement without Trouble.
`<leader>st`/`<leader>sT` (Telescope-dependent) rerouted to Snacks' grep picker instead,
pre-filled with the todo keywords as a regex search.

**Change** - `~/.config/nvim/lua/plugins/todo-comments.lua` (new):
```lua
return {
  {
    "folke/todo-comments.nvim",
    -- stylua: ignore
    keys = {
      { "<leader>xt", false },
      { "<leader>xT", false },
      { "<leader>st", function() Snacks.picker.grep({ search = "TODO|FIX|FIXME|HACK|WARN|PERF|NOTE" }) end, desc = "Todo" },
      { "<leader>sT", function() Snacks.picker.grep({ search = "TODO|FIX|FIXME" }) end, desc = "Todo/Fix/Fixme" },
    },
  },
}
```

**Verified live**: headless Neovim. `<leader>xt`/`<leader>xT` are now simply unbound
(harmless "no mapping" instead of a Lua error). `<leader>st`/`<leader>sT` resolve to the
new `desc`s ("Todo"/"Todo/Fix/Fixme"), confirming they're overridden, not just
coexisting with the old broken ones. Functional test: simulated the actual `<leader>st`
keypress on a file containing a `// TODO:` comment - window count jumped from 1 to 5
(Snacks picker's input/results/preview windows), confirming the picker genuinely opens
with no error, not just that the keymap resolves.

## Follow-up: plugin review pass complete (2026-09-22)

`which-key.nvim` (keybinding popup) and `lualine.nvim` (statusline) - both kept, no
changes. This closes out the one-by-one review started earlier this session.

**Final results, 14 plugins reviewed** (core infra like `lazy.nvim`/`LazyVim`/
`plenary.nvim`/`nui.nvim`/`mini.icons`/`mason.nvim`/`mason-lspconfig.nvim`/
`nvim-lspconfig`/`nvim-treesitter` core excluded - not practical to test standalone):

| Plugin | Verdict |
|---|---|
| `flash.nvim` | kept - briefly rebound to `gs`/`gS`, since back on default `s`/`S` (`gs` is now surround) |
| `gitsigns.nvim` | kept - added `<leader>ghP` popup preview |
| `persistence.nvim` | kept, unchanged |
| `nvim-treesitter-textobjects` | **disabled** |
| `mini.ai` | **disabled** |
| `conform.nvim` | kept - wired up `clang-format` (C/C++) + `ruff format` (Python), installed `ruff` |
| `nvim-lint` | **disabled** |
| `grug-far.nvim` | kept |
| `bufferline.nvim` | kept, unchanged |
| `noice.nvim` | kept, unchanged |
| `trouble.nvim` | **disabled** |
| `todo-comments.nvim` | kept - fixed 4 keymaps broken by the trouble.nvim/no-telescope situation |
| `which-key.nvim` | kept, unchanged |
| `lualine.nvim` | kept, unchanged |

`blink.cmp` and `mini.pairs` were excluded from the keep/remove decision since they
already have runtime toggles (`<leader>ac`, `<leader>up`) instead.

**Still flagged, not addressed**: C++ has no LSP (`clangd`) attached at all - no
diagnostics/go-to-def/hover for C/C++. Bigger, separate decision from anything in this
review pass.

## Follow-up: flash back on s/S (2026-09-28)

**What**: user asked to move flash back to LazyVim's default `s`/`S`. Asked first what
replaces native `s`/`S` - the answer: `cl` (= `s`) and `cc` (= `S`), identical including
counts; `C` / `D` (cursor to end of line) are unaffected, which was the user's actual
worry about `S`. Offered keeping native `s`/`S` on `gs`/`gS` as a swap; declined, so
`gs` is Vim's own "sleep" again and `gS` is unmapped.

**Change** - `~/.config/nvim/lua/plugins/flash.lua` (copy in
[`files/`](files/.config/nvim/lua/plugins/flash.lua)): the `keys` overrides removed;
the file stays as a one-line spec so flash options have an obvious home (the
cheatsheet's `Default:` lines for flash point here):
```lua
return {
  { "folke/flash.nvim" },
}
```

**Verified live**: `s` = "Flash" and `S` = "Flash Treesitter" in n/x/o modes; `gs`/`gS`
native in all three. Also checked while here: flash's char mode has
`multi_line = true`, so `f(` pressed on line 1 landed on the `(` on line 3 - the
cheatsheet's "stays on the line" was wrong, now corrected, with `f`/`F` again = next /
previous match (verified) and a `Default:` line for `multi_line = false` (verified in a
scratch config: `f(` then stays on line 1).

**Cheatsheet**: flash entry now `s`/`S` (not custom) with the `cl`/`cc` note; replace-mode
entry lists `cl`/`cc`; the `s/S → gs/gS` row removed from "Keys changed from stock
LazyVim"; `f`/`t` entry corrected; `gs` (sleep) added; the re-run audit also exposed
`<lead>gS` (git stash picker, `<CR>` = `git stash apply`) - previously masked by the
flash `gS` span - now added. Audit: 0 in every section.
