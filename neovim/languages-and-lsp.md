# Languages, formatters and language servers

**Category:** neovim
**Files touched:** `lua/plugins/languages.lua`, `lua/plugins/formatting.lua`, `lua/plugins/clangd.lua`, `lua/config/options.lua`, `lua/plugins/noice.lua` (all under `~/.config/nvim/`), `~/.clang-format`; copies in [`files/`](files/)

<!-- graph:begin -->
**Graph:** [[Neovim]]
<!-- graph:end -->

Which languages this setup supports and how: the treesitter trim, formatters (clang-format, ruff) and the clangd language server. Part of the LazyVim setup - see [[lazyvim-migration]] for the migration itself and the index of all topic files.

Entries are in the order they happened. They were split out of `lazyvim-migration.md` on 2026-09-23 without rewording, so "above" and "previous follow-up" refer to entries in this file unless a link says otherwise.

## Follow-up: trimmed to the languages actually used (2026-09-15)

**What**: only language actually used is C++, Python, C, Markdown, and plain text - so
removed everything LazyVim's defaults ship for HTML/JSX/Lua-editing specifically, dropped
both bundled themes, and fixed a gap (C++ wasn't actually in the default treesitter list).

**Change** - `~/.config/nvim/lua/plugins/disabled.lua` (new):
```lua
return {
  -- Themes: no extra theme plugin - use Neovim's own built-in "habamax"
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", enabled = false },
  { "LazyVim/LazyVim", opts = { colorscheme = "habamax" } },

  -- HTML/JSX-specific - not used
  { "windwp/nvim-ts-autotag", enabled = false },
  { "folke/ts-comments.nvim", enabled = false },

  -- Lua-specific dev helper - not customizing via Lua
  { "folke/lazydev.nvim", enabled = false },
}
```
`~/.config/nvim/lua/plugins/languages.lua` (new) - `ensure_installed` is an
`opts_extend` list (LazyVim concatenates overrides, it doesn't replace them), so removing
entries needs a function-form `opts` that filters the already-merged list rather than just
passing a shorter one:
```lua
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      local remove = { html = true, javascript = true, jsdoc = true, tsx = true, typescript = true }
      opts.ensure_installed = vim.tbl_filter(function(lang)
        return not remove[lang]
      end, opts.ensure_installed)
      table.insert(opts.ensure_installed, "cpp") -- wasn't in the default list, only bare "c" was
      return opts
    end,
  },
}
```
Then applied directly rather than waiting for the next launch: `:Lazy sync` + `:Lazy
clean` removed the 5 disabled plugins from disk; `:TSInstall cpp` +
`:TSUninstall html javascript jsdoc tsx typescript` (confirmed "Uninstalled 5/5
languages") updated the compiled parsers to match; `lua-language-server` (auto-installed
by Mason during earlier testing, before this trim was decided) was removed by deleting
`~/.local/share/nvim/mason/packages/lua-language-server` directly, since `:MasonUninstall`
wasn't registering reliably when driven non-interactively.

**Verified live**: clean launch, `vim.g.colors_name` reads `habamax` (later replaced, see the
colorscheme follow-up in [[appearance]]), no tokyonight/catppuccin references anywhere, no errors, dashboard
renders correctly, `cpp.so` present under the treesitter parser dir. 27 plugins remain
(down from 32).

**Kept on purpose, not removed**: the `lua`/`luadoc`/`luap`/`vim`/`vimdoc` treesitter
parsers - these are what let Neovim render its own `:help` pages and any `.lua`/`.vim`
files correctly; tiny footprint, not really "a Lua plugin" in the sense that was asked to
go. Flagged to the user rather than silently kept.

## Follow-up: wired up real formatters for C/C++/Python (2026-09-22)

**What**: testing `conform.nvim` revealed LazyVim's defaults only configure formatters
for `lua`/`fish`/`sh` - zero for C/C++/Python/Markdown, since those come from
language "extras" this setup deliberately skipped. `<leader>cf`/format-on-save were
silently no-ops for every language actually in use. Installed and wired up real
formatters rather than leaving the plugin as dead weight.

**Decisions** (asked rather than picked unilaterally, per the standing "ask before
subjective calls" rule):
- Python: **ruff format** over black - fast (Rust), black-compatible output, and since
  `nvim-lint` also has zero Python linters configured, ruff can cover both jobs later
  from one already-installed tool instead of adding two.
- Markdown: **skipped** - the standard tool (prettier) needs npm/Node, which this setup
  has deliberately avoided pulling in (HTML/JS/TS treesitter parsers were already
  removed for the same reason - see the very first follow-up above).
- C/C++: `clang-format` - not really a decision, it's the standard tool and was **already
  installed system-wide** (`/usr/bin/clang-format`, part of the `clang` package) -
  nothing new to install, just wire it up.

**Change** - `~/.config/nvim/lua/plugins/formatting.lua` (new):
```lua
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cpp = { "clang-format" },
        c = { "clang-format" },
        python = { "ruff_format" },
      },
    },
  },
}
```

**Installed**: `ruff` via Mason (`require('mason-registry'):get_package('ruff'):install()`,
driven directly through the Lua API rather than the `:MasonInstall` ex-command - that
command isn't registered yet right after forcing `VeryLazy` in a scripted headless
session, same class of headless-Mason friction noted in the original migration entry
([[lazyvim-migration]])). Confirmed installed: `ruff 0.16.8` at
`~/.local/share/nvim/mason/bin/ruff`.

**Not auto-installed on a fresh machine**: unlike LSP servers (auto-installed by
`mason-lspconfig.nvim` when a matching filetype is opened), conform's formatters have no
such auto-install bridge in this setup (would need `mason-tool-installer.nvim`, not
installed - one tool didn't justify adding a whole plugin for it). Reproducing this on a
fresh machine needs one extra manual step: `:MasonInstall ruff` (or the Lua snippet
above) after the initial `:Lazy sync`. `clang-format` has no such gap since it's a
system package, not Mason-managed.

**Verified live**: headless Neovim, real messy files. C++: `int main(){int x=1;return
x;}` -> properly braced/indented/spaced 4-line output via `clang-format`. Python:
`x=1` / `y =2` -> `x = 1` / `y = 2` via `ruff_format`. `list_formatters()` confirms
exactly one formatter resolves per filetype as configured, no unexpected fallbacks.

## Follow-up: clangd set up - C/C++ finally has an LSP (2026-09-23)

**What**: closed the gap flagged repeatedly during the plugin review ([[plugin-review]]). `.c` / `.cpp` files had **no language
server at all** - no go-to-definition, references, hover or diagnostics - despite C++
being a primary language here. Formatting worked only because `clang-format` runs
independently of any LSP.

**Nothing needed installing**: `clangd` 22.1.8 is already at `/usr/bin/clangd`, shipped
by the same `clang` system package that provides `clang-format`. Checked before reaching
for Mason, and `mason = false` is set on the server so Mason doesn't install a second
copy.

**Deliberately not the full `lang.clangd` extra** (asked rather than decided): that extra
also pulls in `clangd_extensions.nvim`. Inspected what that actually contributes here -
an AST viewer, inlay-hint tweaks, and an **nvim-cmp** score comparator that does nothing
in this setup since we use blink.cmp. Crucially, source/header switching is provided by
`nvim-lspconfig` itself (it creates `LspClangdSwitchSourceHeader` in its own
`lsp/clangd.lua`), **not** by the extra plugin - so the minimal route loses essentially
nothing. The clangd `cmd` flags were taken from LazyVim's extra so the tuning matches.

**Change** - `~/.config/nvim/lua/plugins/clangd.lua` (new): `nvim-lspconfig` server entry
with `mason = false`, LazyVim's clangd flags (`--background-index`, `--clang-tidy`,
`--header-insertion=iwyu`, `--completion-style=detailed`, `--function-arg-placeholders`,
`--fallback-style=llvm`), root markers, utf-16 offset encoding, and `<lead>ch` for
source/header switching (confirmed free via `nvim_get_keymap` before binding).

**Verified live, functionally - not just "it attached"**: on a real `.cpp` file clangd
attaches (`name=clangd`, root resolved correctly), **go-to-definition** on a call
correctly jumped to the definition line, **hover** returned the full signature with
parameter list, and a deliberately broken file produced **3 correct diagnostics**
("Cannot initialize a variable of type 'int' with an lvalue...", "Use of undeclared
identifier", "Expected ';' after return statement (fix available)"). `<lead>ch`
confirmed registered as a buffer-local keymap.

**Cheatsheet corrected**: the "C and C++ have no LSP (known gap)" entry was now false -
replaced with a clangd entry covering `<lead>ch`, the `--clang-tidy` behaviour, and the
`compile_commands.json` caveat (CMake's `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`; without it
clangd falls back to weaker single-file analysis). Also added a "Language servers"
section to the customizations summary. Coverage re-checked: 279/283, no regression.

## Follow-up: diagnostics hidden by default (2026-09-23)

**What**: LSP diagnostics (signs, underlines, virtual text) now start disabled in every
Neovim session; `<leader>ud` (LazyVim's `Snacks.toggle.diagnostics()`) turns them back on.
Asked whether this should be global or LeetCode-only - answer was everywhere.

**Why**: user wanted them out of the way by default, enabled on demand.

**Change** - `~/.config/nvim/lua/config/options.lua`, appended (copy in
[`files/`](files/.config/nvim/lua/config/options.lua)):
```lua
vim.diagnostic.enable(false)
```
`~/.config/nvim/cheatsheet.md`: the `<lead>ud` line notes it starts off.

**Verified live**: headless Neovim on a `.cpp` file with an undeclared call, clangd
attached, forced `VeryLazy`: `vim.diagnostic.is_enabled()` is `false` while
`vim.diagnostic.get(0)` still holds the 1 error (clangd keeps computing them - toggling
on shows them instantly); `<leader>ud` is "Toggle Diagnostics", and toggling flips it to
`true`. Confirmed nothing in LazyVim re-enables diagnostics globally after startup.

**Notes**: the toggle is per session - every new Neovim starts with them off again.

## Follow-up: clang-format indents 4 spaces, not 2 (2026-09-23)

**What**: `<leader>cf` (conform -> clang-format) was indenting C/C++ with 2 spaces despite
`shiftwidth=4`. Added a home-wide `~/.clang-format`.

**Why**: clang-format never reads Vim's `shiftwidth`; with no `.clang-format` found it
falls back to LLVM style (`IndentWidth: 2`). `--fallback-style` in conform's args was
tried first - it only accepts predefined style names, not inline `{...}` settings
("Invalid fallback style"). `--style={...}` would work but overrides every project's own
`.clang-format`. A file in `$HOME` is found by clang-format's parent-directory search for
anything under home (including leetcode.nvim's `~/.local/share/nvim/leetcode/`), while a
project's closer `.clang-format` still wins.

**Change** - `~/.clang-format` (new; copy in [`files/`](files/.clang-format)):
```yaml
BasedOnStyle: LLVM
IndentWidth: 4
AccessModifierOffset: -4
```
`AccessModifierOffset: -4` keeps `public:`/`private:` flush left, as before and as
LeetCode's templates write them - LLVM's `-2` with 4-space indent would put them at
column 2.

**Verified live**: headless Neovim, forced `VeryLazy`, `conform.format()` on a
LeetCode-shaped `.cpp` under `$HOME`: body indented 4, `public:` at column 0.

**Notes**: files outside `$HOME` (e.g. `/tmp`) still get LLVM's 2-space default.

## Follow-up: signature help no longer pops up by itself (2026-09-25)

**What**: the floating window showing a function's parameters while typing a call
(e.g. `max(const Tp &a, const Tp &b) -> const Tp &` after `std::max(`) is noice.nvim's
LSP signature help - LazyVim enables noice, and noice's default
`lsp.signature.auto_open` opens it on every LSP trigger character (`(`, `,`). Turned
the auto-open off; it's shown on demand with `<C-k>` (insert) / `gK` (normal), both
LazyVim's existing "Signature Help" keys. Not blink.cmp: its signature feature is left
disabled by LazyVim, and its documentation window only accompanies the completion menu
(itself off by default now).

**Why**: user wanted it only when asked for, same as diagnostics and autocomplete.

**Change** - `~/.config/nvim/lua/plugins/noice.lua` (new; copy in
[`files/`](files/.config/nvim/lua/plugins/noice.lua)):
```lua
return {
  {
    "folke/noice.nvim",
    opts = {
      lsp = {
        signature = {
          auto_open = { enabled = false },
        },
      },
    },
  },
}
```
Cheatsheet: new "Function parameters (signature help)" entry in the LSP category, added
to both the original and the user's copy (see [[personal-cheatsheet]]).

**Verified live**: headless Neovim, clangd attached, forced `VeryLazy`: merged
`auto_open.enabled` is `false`; typing `std::max(1, ` opened no float; `<C-k>` then
opened the noice float reading `max(const Tp &a, const Tp &b) -> const Tp &`.
