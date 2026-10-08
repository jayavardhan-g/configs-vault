# Neovim: minimal, manually-managed, SSH-friendly setup

<!-- graph:begin -->
**Graph:** [[kitty]] · [[Neovim]] · [[Vim]] · [[SSH]]
<!-- graph:end -->

> **Superseded 2026-09-15**: Neovim was migrated to LazyVim - see
> [[lazyvim-migration]]. This entry (and its follow-ups below) no longer describes the
> live Neovim config; kept for the reasoning trail behind decisions made along the way.
> `~/.vimrc` (plain Vim) is unaffected and still matches this entry's Vim-side content.

**Date:** 2026-08-30
**Category:** system
**Files touched:** `~/.config/nvim/` (new), `~/.config/kitty/kitty.conf`

## What
Built a Neovim config from scratch, picking and choosing specific features out of two
reference dotfile repos (`hendrikmi/neovim-kickstart-config` and a second hand-rolled
`nvim` config) rather than adopting either wholesale. Also set kitty's font to a Nerd Font
so file-explorer/git-status icons render instead of showing as boxes.

## Why
Wanted a Neovim setup usable for real coding work even when connecting to a remote box
over plain SSH (terminal-only, no VSCode/GUI) — including a directory browser, since the
built-in `netrw` (`:Ex`) is workable but clunky. Also wanted the plugin/LSP-management
philosophy to match how the rest of this machine's setup has been done: read exactly
what's installed and why (see AUR PKGBUILD reviews elsewhere in this repo), not hand
control to an auto-installing tool.

## Reference repos and what they actually contain
Full inventories (kept here for future reference, since the temp/ checkouts get deleted):

**`neovim-kickstart-config`** (kickstart.nvim + `lazy.nvim`): `lazy.nvim` plugin manager
(lockfile, auto-install) · LSP via `nvim-lspconfig` + **Mason** (auto-downloads server
binaries) for `ts_ls`/`ruff`/`pylsp`/`html`/`cssls`/`tailwindcss`/`dockerls`/`sqlls`/
`terraformls`/`jsonls`/`yamlls`/`lua_ls` · `nvim-cmp` + `LuaSnip` + `friendly-snippets` ·
`none-ls` + `mason-null-ls` for format-on-save (prettier/eslint_d/shfmt/stylua/ruff) ·
Telescope + `telescope-fzf-native` + `telescope-ui-select` · **neo-tree** file explorer
(git status, diagnostics, image preview, window-picker) · standard `nvim-treesitter` ·
`lualine` + `bufferline` + `alpha-nvim` dashboard + `indent-blankline` · `nord.nvim`
colorscheme (fixed) · `gitsigns.nvim` · `vim-tmux-navigator`, `vim-sleuth`, `vim-fugitive`+
`vim-rhubarb`, `which-key.nvim`, `nvim-autopairs`, `todo-comments.nvim`,
`nvim-colorizer.lua`.

**Hand-rolled `nvim` config**: ~30-line custom `git clone` plugin loader, no lockfile ·
LSP entirely hand-declared per server (`cmd`/`filetypes`/`root_markers`), no Mason —
expects system-installed binaries · bare `nvim-cmp` (no snippets) · format-on-save wired
directly to the LSP's own formatter capability, no separate formatter plugin · **no file
explorer** (relies on `netrw`) · Telescope + **Harpoon2** (pinned-file quick-jump) ·
fully vendored/compiled treesitter parsers + two hand-written ~100-line modules
reimplementing `nvim-treesitter-context` and `nvim-treesitter-textobjects` · **`vim-oscyank`**
(OSC52 clipboard — copies to the *local* machine's clipboard even over plain SSH with no
X/Wayland forwarding) · `undotree`, a custom floating-terminal toggle, `nvim-highlight-colors`,
niche per-language `ftplugin`s (Zig/Nix/Go templ/Hare) not relevant here.

## Decisions made (asked via clarifying questions, not assumed)
- **Plugin manager**: manual git-clone loader (adapted from the hand-rolled config),
  not `lazy.nvim` — fits the "read/understand exactly what's installed" approach used
  elsewhere in this repo.
- **File explorer**: **neo-tree.nvim** — actively maintained (not archived; that confusion
  was probably with the old, actually-archived `NERDTree`), works fine as a sidebar over
  plain SSH.
- **LSP install**: system packages, **no Mason** — each server hand-declared with its
  system `cmd`, no auto-downloaded binaries outside pacman's view.
- **Languages configured**: Lua, Python, C/C++.
- **Colorscheme**: originally no named colorscheme (same "follow the terminal" spirit as
  `~/.vimrc`) — later superseded by `vscode.nvim` to match VSCode's palette, see the
  "Follow-up: colorscheme now matches VSCode" section below.
- **Extras**: only OSC52 clipboard yank (`vim-oscyank`) was picked from the offered list
  (Harpoon, gitsigns+fugitive, and a floating-terminal toggle were all explicitly
  declined — don't add them back without being asked).

## Change
Final file layout under `~/.config/nvim/`:

```
init.lua                        -- requires config.options, config.keymaps, manage, lsp
lua/config/options.lua          -- vim.opt settings
lua/config/keymaps.lua          -- keymaps ported from ~/.vimrc, plus OSC52 yank + diagnostics
lua/manage.lua                  -- minimal git-clone plugin loader
lua/plugin-list.lua             -- list of plugins to clone
lua/lsp.lua                     -- hand-declared lua_ls/pylsp/clangd + LspAttach keymaps
after/plugin/completion.lua     -- nvim-cmp setup
after/plugin/treesitter.lua     -- nvim-treesitter (main branch), parser install, native highlighting + indent
after/plugin/telescope.lua      -- Telescope setup + <leader>f* find/grep keymaps
after/plugin/neotree.lua        -- neo-tree setup + <leader>e toggle
after/plugin/lualine.lua        -- single global statusline, mode/filename/location only
after/plugin/colors.lua         -- vscode.nvim colorscheme (transparent background)
```

`lua/plugin-list.lua`:
```lua
return {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
    { "nvim-neo-tree/neo-tree.nvim", branch = "v3.x" },
    { "nvim-treesitter/nvim-treesitter", branch = "main" }, -- was "master", see Bug fix below
    "nvim-telescope/telescope.nvim",
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "nvim-lualine/lualine.nvim",
    "ojroques/vim-oscyank",
}
```

Key `<leader>` mappings added on top of the `~/.vimrc` set: `<leader>e` (toggle neo-tree),
`<leader>ff`/`fg`/`fb`/`fo`/`fh`/`fs`/`fc` (Telescope find/grep), `<leader>y` in normal/visual
mode (OSC52 yank, operator-pending like plain `y`), `<leader>rn`/`ca` (LSP rename/code
action, buffer-local once an LSP attaches), `[d`/`]d`/`<leader>d`/`<leader>q` (diagnostics
navigation).

### Keybindings reference

General (same look-and-feel as `~/.vimrc`'s keymaps, plus the additions below):

| Key | Action |
|---|---|
| `<C-s>` | Save |
| `<leader>sn` | Save without triggering format-on-save |
| `<C-q>` | Quit |
| `x` | Delete char without yanking it |
| `<C-d>` / `<C-u>` | Half-page down/up, cursor re-centered |
| `n` / `N` | Next/prev search match, re-centered |
| Arrow keys | Resize the current split |
| `Tab` / `S-Tab` | Next/prev buffer |
| `<leader>x` / `<leader>b` | Delete buffer / new buffer |
| `<leader>v` / `<leader>h` | Vertical / horizontal split |
| `<leader>se` / `<leader>xs` | Equalize splits / close split |
| `<C-h/j/k/l>` | Move focus between splits |
| `<leader>to/tx/tn/tp` | New/close/next/prev tab |
| `<leader>lw` | Toggle line wrap |
| `jk` or `kj` (insert) | Escape to normal mode |
| `<leader>y` (normal/visual) | Yank via OSC52 (works over plain SSH) |
| `<leader>rl` | Reload config |
| `<C-/>` (also `<C-_>`) | Toggle comment on the line (normal) / selection (visual) — Neovim's built-in `gcc`/`gc`, no plugin |

Diagnostics:

| Key | Action |
|---|---|
| `[d` / `]d` | Previous/next diagnostic |
| `<leader>d` | Show diagnostic under cursor (floating) |
| `<leader>q` | Send all diagnostics to the location list |

LSP (buffer-local, only once a server attaches — Lua/Python/C++ configured):

| Key | Action |
|---|---|
| `K` | Hover docs |
| `gd` / `gD` | Go to definition / declaration |
| `gi` | Go to implementation |
| `gr` | List references |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| *(automatic)* | Format on save |

Telescope:

| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | List open buffers |
| `<leader>fo` | Recently opened files |
| `<leader>fh` | Help tags |
| `<leader>fs` | Grep word under cursor |
| `<leader>fc` | Grep current filename |
| `<C-j>` / `<C-k>` (inside the prompt) | Move selection down/up |

neo-tree:

| Key | Action |
|---|---|
| `<leader>e` | Toggle the file tree |
| `l` | Open file / expand folder |
| `h` | Close/collapse the current node |
| `<cr>` or `<space>` | Open / expand-collapse (neo-tree defaults) |
| `a` / `d` / `r` | Add / delete / rename |
| `?` | Show neo-tree's own full help |

Prerequisites this session did **not** install (user chose to do this manually):
```
sudo pacman -S neovim lua-language-server python-lsp-server
```
`clangd`, `ripgrep`, and `fd` were already present on this machine (clangd for C/C++,
ripgrep/fd are what Telescope's `find_files`/`live_grep` shell out to).

`~/.config/kitty/kitty.conf` — added, above `background_opacity`:
```
font_family                 MesloLGS Nerd Font Mono
```
(A Nerd Font was already installed system-wide; kitty just wasn't pointed at one, so it
was falling back to NotoSansMono. Needs a new kitty window, or `ctrl+shift+F5` inside an
existing one, to pick up the change.)

## Bug fix: error opening markdown files (2026-08-31)

**What happened:** opening a markdown file threw an error, traced to the `nvim-treesitter`
setup.

**Fix applied:**
1. `lua/plugin-list.lua` — changed the `nvim-treesitter` clone from `branch = "master"` to
   `branch = "main"`.
2. `after/plugin/treesitter.lua` — replaced the old `configs.setup({...})` call with a
   `FileType` autocmd that starts highlighting natively per-buffer:
   ```lua
   vim.api.nvim_create_autocmd("FileType", {
       group = vim.api.nvim_create_augroup("treesitter-highlight", { clear = true }),
       callback = function(event)
           -- Silently start Treesitter highlighting if a parser is available for this filetype
           pcall(vim.treesitter.start, event.buf)
       end,
   })
   ```
   (The old `ensure_installed`/`auto_install`/`highlight`/`indent` block was commented out
   rather than deleted, left in place in the file as a record of the previous approach.)

**Why this fixes it:** `master` is `nvim-treesitter`'s old pre-2024-rewrite branch — its
bundled parsers and its `nvim-treesitter.configs` module (which the old `treesitter.lua`
called `.setup()` on) are frozen and can drift out of compatibility with newer Neovim
treesitter runtimes, which is what surfaced as the markdown error. `main` is the actively
maintained branch going forward, but it dropped the legacy `configs` module entirely — on
`main`, the plugin's job is just installing/updating parsers (`:TSUpdate`), and enabling
highlighting is done through Neovim's own native `vim.treesitter.start()` API instead,
which is what the `FileType` autocmd above does.

## Follow-up: Treesitter indent + missing parsers (2026-08-31)

Indentation was left out of the markdown fix above (no equivalent to the old
`indent = { enable = true }` was wired up on `main`). Getting it working surfaced a
second, separate gap: the `main` branch no longer installs parsers as part of any
`setup()` call at all, and this config had nothing else installing them either — Neovim
bundles a few parsers itself (`c`/`lua`/`markdown`/`query`/`vim`/`vimdoc`) and several more
were already covered by pacman's `tree-sitter-*` grammar packages, but **`python` and
`bash` weren't pacman-installed yet, and there is no `tree-sitter-cpp` package in the
official repos at all** — so those three filetypes were silently getting zero Treesitter
highlighting or indent (caught by the `pcall`, no error shown).

Final `after/plugin/treesitter.lua`:
```lua
-- require("nvim-treesitter.configs").setup({
--     ensure_installed = { "lua", "vim", "vimdoc", "python", "c", "cpp", "bash", "markdown", "query" },
--     auto_install = true,
--     highlight = { enable = true },
--     indent = { enable = true },
-- })

require("nvim-treesitter").install({ "lua", "vim", "vimdoc", "python", "c", "cpp", "bash", "markdown", "query" })

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("treesitter-highlight", { clear = true }),
    callback = function(event)
        local ok = pcall(vim.treesitter.start, event.buf)
        if ok then
            vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})
```
`require("nvim-treesitter").install({...})` (documented in the plugin's own README) is a
no-op for anything already installed, and compiles anything missing from source — async,
so a filetype's parser may still be building in the background the very first time it's
opened after a fresh install; a `:e` (reopen) picks it up once the build finishes.
`indentexpr` is only set when `vim.treesitter.start` actually succeeded, so filetypes with
no parser keep their normal indentscript instead of an empty `indentexpr`.

**This needed one more system package**: parser compilation on `main` shells out to an
external `tree-sitter` CLI binary, which wasn't installed — `.install()` failed for every
language with `ENOENT: no such file or directory (cmd): 'tree-sitter'`. Installed via:
```
sudo pacman -S tree-sitter-cli
```
(official repo, not AUR). After that, `require('nvim-treesitter').install({'cpp','python','bash'})`
compiled all three successfully. This was a real back-and-forth during the session: the
`install()` call was added, then briefly **reverted** (along with the `indentexpr` line)
back to the highlighting-only version above because it was erroring with the CLI missing,
then **re-added** once `tree-sitter-cli` was installed and confirmed working. The commented-out
legacy `configs.setup()` block stays in the file as a record of the pre-`main`-branch approach.

**What Treesitter actually adds vs. the fallback** (came up mid-diagnosis, worth keeping):
without a parser for a filetype, Neovim falls back to its bundled regex-based
`syntax/<lang>.vim` highlighting and that language's traditional `indent/<lang>.vim`
indentscript — not "nothing," just less precise (regex pattern-matching has no real
understanding of code structure, vs. Treesitter's actual parse tree) and without Treesitter's
optional extras (smart text objects, better folding, sticky-context plugins). LSP features
(hover, go-to-definition, diagnostics, rename, format-on-save) are entirely separate from
Treesitter and unaffected either way — format-on-save here goes through `vim.lsp.buf.format()`
in `lua/lsp.lua`, not Treesitter.

## Follow-up: colorscheme now matches VSCode (2026-08-31)

**What changed**: superseded the earlier "no named colorscheme, follow the terminal"
approach (see the outdated Notes bullet below) with `Mofiqul/vscode.nvim`, which ports
VSCode's own Dark+/Light+ syntax palette.

**Why**: wanted Neovim's highlighting to visually match VSCode's default dark theme.
Tried the "no plugin" route first — tuning Neovim's own built-in default highlight groups
(some Treesitter capture groups, like `@keyword.function`, had no color at all defined
under the bare default) — but that can only rearrange *Neovim's own* default palette, it
can't reproduce VSCode's actual colors, which don't exist anywhere in Neovim to begin
with. Matching VSCode's specific palette by hand would mean manually writing out dozens of
hex values across Treesitter captures, LSP semantic tokens, and UI plugin highlight groups
— exactly the "too much config for the goal" case, so a small purpose-built colorscheme
plugin was used instead.

Added to `lua/plugin-list.lua`: `"Mofiqul/vscode.nvim"`.

`after/plugin/colors.lua` (replaces the old manual background-clearing):
```lua
require("vscode").setup({
    transparent = true,
})
vim.cmd.colorscheme("vscode")
```

`after/plugin/lualine.lua` — `theme = "auto"` changed to `theme = "vscode"` to match.

## Follow-up: Treesitter-based folding for every language (2026-09-03)

**What**: markdown files (and every other filetype) had no folds at all - Neovim's
default `foldmethod` is `manual`, and nothing in this config had ever set it.

**Why**: asked whether markdown files fold by default (they don't); wanted one fold
method that works across every language already covered by the Treesitter setup above,
rather than a per-filetype `ftplugin`.

**Change** — `lua/config/options.lua`:
```lua
set.foldmethod = "expr"
set.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- Start each buffer fully unfolded, but via `zR` (sets 'foldlevel' to the
-- buffer's real deepest fold level) rather than a hardcoded foldlevel=99.
-- With foldlevel=99, `zm` (foldlevel -= 1) has to be pressed ~95+ times
-- before it reaches actual fold depth and visibly closes anything; zR fixes
-- that by landing foldlevel on the true max depth immediately. Gated to
-- once per buffer (not every BufWinEnter) so revisiting a buffer/split
-- doesn't blow open folds you closed by hand.
vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "*",
  callback = function(args)
    if vim.b[args.buf].fold_zr_done then
      return
    end
    vim.b[args.buf].fold_zr_done = true
    vim.cmd("normal! zR")
  end,
})
```
`vim.treesitter.foldexpr()` is Neovim's built-in (no plugin) Treesitter-driven fold
expression - one `foldexpr` that works for any filetype with a parser already
installed/started (see the Treesitter section above), and degrades to "no folds" rather
than erroring for filetypes with none. The `BufWinEnter` autocmd keeps buffers fully
unfolded on open (Treesitter folding without this defaults to everything collapsed,
which is rarely what you want) - see the fold-level follow-up below for why it replaced
a plain `foldlevel = 99`.

Normal fold keys apply as usual: `za` toggle, `zM` close all, `zR` open all, `zc`/`zo`
close/open one.

## Follow-up: word wrap enabled (2026-09-03)

**What**: switched from `set.wrap = false` to `set.wrap = true` (long lines wrap onto the
next screen line instead of scrolling horizontally), matching the same change made to
`~/.vimrc` - see [[vimrc-minimal-visual-config]].

**Change** — `lua/config/options.lua`:
```lua
set.wrap = true
```
`linebreak`/`breakindent` (already set) keep the wrap point on a word boundary and
indent-aligned. `<leader>lw` already toggles this at runtime if wrap is only wanted for a
specific buffer/session.

## Notes
- **Superseded (2026-09-03)**: the fold-level follow-up above used to be a flat
  `set.foldlevel = 99` / `set.foldlevelstart = 99`. That's a literal number, not the
  buffer's real fold depth — `zm` (which does `foldlevel -= 1`) had to be pressed ~95+
  times before it reached actual fold nesting and visibly closed anything, so it looked
  broken until `zM` (close all, sets `foldlevel = 0`) was pressed first. Replaced with the
  `BufWinEnter` → `zR` autocmd shown above, since `zR` sets `'foldlevel'` to the buffer's
  *actual* deepest fold level rather than a hardcoded number — same "everything unfolded
  on open" result, but `zm` now works correctly on the very first press. Same root cause
  and fix applied to `~/.vimrc` — see [[vimrc-minimal-visual-config]].
- **No distinct "Dark Modern" variant exists** in `vscode.nvim` — only `dark`/`light`
  (classic Dark+/Light+), which is the closest available match. Dark Modern mostly
  changed VSCode's own UI chrome rather than its syntax token colors, so this is visually
  close in practice.
- **`transparent = true`** keeps the same "see kitty's own translucent background
  through" look this config had before, at the cost of not getting VSCode's actual dark
  background color. Set it to `false` in `colors.lua` for VSCode's real background
  instead.
- To switch to the light variant: `:lua require('vscode').load('light')`, or set
  `style = "light"` in the `setup()` call in `colors.lua` for it to load that way by
  default.
- **Superseded**: the "no named colorscheme, follow the terminal" approach originally
  used here (no colorscheme loaded, Neovim's built-in default highlight groups, only
  backgrounds cleared to `none`) — see the "Follow-up: colorscheme now matches VSCode"
  section above for why and what replaced it. `~/.vimrc` (see
  [[vimrc-minimal-visual-config]]) still follows the terminal's own ANSI palette with no
  colorscheme at all — that choice wasn't changed, only Neovim's was.
- `lualine`'s theme is now `"vscode"` (was `"auto"`) to match the colorscheme above.
- `neo-tree`'s window mappings rebind `l` → open / `h` → close_node (vim-style, matching
  the hjkl navigation pattern already used for Hyprland window focus — see
  [[vim-navigation]]), on top of neo-tree's own defaults (`<cr>`/`<space>` still work).
- The two reference repos' more idiosyncratic pieces were deliberately **not** ported:
  the hand-rolled config's vendored/compiled treesitter parsers (architecture-specific
  binaries checked into a repo — brittle to replicate; standard `nvim-treesitter`
  auto-compiles for whatever machine it runs on instead) and its custom
  sticky-context/textobjects reimplementations (real plugins exist for both if wanted
  later: `nvim-treesitter-context`, `nvim-treesitter-textobjects`).
- If Python/C++ formatting-on-save feels incomplete later: `pylsp` ships a basic
  formatter (autopep8) already wired through the generic `BufWritePre` hook in
  `lua/lsp.lua`; nothing was added for C/C++ (`clangd`'s formatter needs a
  `.clang-format` file in the project to do anything useful).
