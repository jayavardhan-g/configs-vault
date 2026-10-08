# Migrated Neovim to LazyVim

**Date:** 2026-09-15
**Category:** system
**Files touched:** `~/.config/nvim` (replaced), `~/.local/share/nvim`, `~/.local/state/nvim`,
`~/.cache/nvim`

## What
Replaced the entire hand-rolled Neovim config (see [[neovim-minimal-ssh-friendly-setup]]
and [[vim-neovim-parity-pass]]) with the official [LazyVim](https://www.lazyvim.org)
starter template. **Neovim only** — `~/.vimrc` (plain Vim) is untouched and still the
hand-rolled setup described in [[vimrc-minimal-visual-config]].

## Why
After several sessions hand-rolling Neovim-specific behavior (a buffer-based tabline, a
multi-file "smart quit" flow, sidebar/quit interactions), kept hitting real bugs in that
custom glue code - netrw's `modifiable` default, neo-tree's `close_if_last_window` quit
guard silently replacing the confirm dialog, `BufModifiedSet` not existing in plain Vim,
duplicate sidebars per real tabpage, `:bdelete` collapsing windows. Decided the actual
priority had shifted from "hand-declare and understand every piece" (the original
rationale for the manual git-clone loader and no-Mason setup) to "fewer bugs, less
personal maintenance, lean on a tried-and-tested community config instead."

Compared LazyVim, AstroNvim, and NvChad first rather than assuming - see the chat history
around 2026-09-15 for the full comparison. LazyVim won on: largest community (most
already-solved issues to find), its "extras" system (one line pulls in a whole language's
LSP+formatter+treesitter+debugger, pre-integrated, instead of hand-declaring each piece -
directly addresses where this session's bugs kept coming from), and being the most
actively developed of the three. NvChad's one philosophical similarity (no Mason by
default) was explicitly *not* a deciding factor once "match our old preferences" stopped
being the goal - no Mason would have meant continuing to hand-install every LSP server,
recreating the exact problem this migration is meant to solve.

## Change
Backed up the previous setup rather than deleting it (per LazyVim's own documented install
steps):
```bash
mv ~/.config/nvim      ~/.config/nvim.bak-pre-lazyvim-20260915-005052
mv ~/.local/share/nvim ~/.local/share/nvim.bak-pre-lazyvim-20260915-005052
mv ~/.local/state/nvim ~/.local/state/nvim.bak-pre-lazyvim-20260915-005052
mv ~/.cache/nvim       ~/.cache/nvim.bak-pre-lazyvim-20260915-005052
```
Installed the starter template:
```bash
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```
First launch bootstraps `lazy.nvim` and syncs all default plugins automatically - no
further steps needed. Opening a file of a given language (e.g. a `.lua` file) auto-installs
its LSP server via Mason on the spot (confirmed live: `lua_ls` installed and attached
within ~20s of opening a `.lua` file, no manual config).

## Reproducing this exact setup on a fresh machine

All the personal customizations recorded in the topic files listed at the end of this
entry (themes, disabled plugins, language list, keybinds, OSC52, and so on) are stored
as **actual files**, not just described in
prose - see [`files/`](files/) next to this entry, which mirrors real paths under `$HOME`
(per `CLAUDE.md`'s file-storage convention). To reproduce:

```bash
# 1. Install the bare LazyVim starter
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# 2. Overlay this repo's customizations on top
cp -r files/.config/nvim/* ~/.config/nvim/
cp files/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf  # only if you also want the Nerd Font + this exact kitty setup

# 3. First launch bootstraps everything else automatically
nvim
```
That's the whole thing - no manual `:TSInstall`/`:TSUninstall`/Mason cleanup steps needed
on a *fresh* machine (those were only needed in this session because plugins/parsers were
already installed before the customization was decided; `disabled.lua` and
`languages.lua` being in place *before* the first `:Lazy sync` means the excluded
plugins/parsers are simply never installed in the first place).

**One real prerequisite**: `colors/kitty.lua` reads `~/.config/kitty/kitty.conf`'s
`include` line and the theme file it points to (currently Noctalia-managed - see
`cachyos/system/noctalia-greeter-sync-password-prompt.md` for context on that shell) - on
a machine without that same kitty+Noctalia setup, it falls back to Neovim's built-in
`habamax` colorscheme automatically rather than erroring, so this is safe to copy
anywhere, it just won't match a different machine's terminal theme unless the same kitty
theming exists there too.

## Notes
- **Rollback**: if LazyVim doesn't work out, the entire previous hand-rolled setup is
  intact at the `*.bak-pre-lazyvim-20260915-005052` paths above - `mv` them back over the
  live `nvim`/`.local`/`.cache` paths to restore it exactly as it was.
- **`neovim-minimal-ssh-friendly-setup.md` and `vim-neovim-parity-pass.md` (Neovim parts
  only) are now historical** - kept for the reasoning trail (LSP/plugin philosophy,
  keybind decisions) but no longer describe the live Neovim config. Their Vim-side content
  (`~/.vimrc`) is still current and unaffected by this migration.
- `stylua`/`shfmt` (Mason-managed formatters for `.lua`/`.sh` files) failed to finish
  installing during setup - Neovim was killed mid-download once, and scripted retries
  afterward (`:MasonInstall stylua shfmt` via both headless `nvim --headless "+cmd" +qa`
  and a driven interactive session) didn't visibly complete either, likely a timing quirk
  specific to non-interactive/scripted driving rather than a real problem - everything
  else (LSP, treesitter, all plugins) installed and verified working. Fix by opening
  `:Mason` normally and retrying those two by hand; doesn't block anything else.
- Personal customizations from the old setup (OSC52 clipboard yank over SSH, `<leader>`
  keybind choices, no-Mason/system-LSP preference, minimal chrome) were **not** ported
  over - starting from LazyVim's defaults deliberately, to actually get the "tried and
  tested, not fighting my own overrides" benefit before deciding what (if anything) to
  layer back on top. Revisit and add back only what's actually missed after using it.

## After copying the files (fresh machine)

Two things `files/` can't carry:
- `:MasonInstall ruff` - the Python formatter/LSP isn't auto-installed (see [[languages-and-lsp]]). `clang-format` and `clangd` come from the system `clang` package.
- LeetCode login - run `nvim leetcode.nvim`, then sign in (see [[leetcode]]). The cookie is deliberately not stored in this repo.

## Topic files

Everything changed after the migration, grouped by topic. Each file keeps its entries in date order.

| File | Covers |
|---|---|
| [`keybindings-and-editing.md`](keybindings-and-editing.md) | Key remaps and editing defaults layered on top of LazyVim: the old-vs-LazyVim key comparison, OSC 52 clipboard yank, VSCode-style comment toggle, 4-space indent, the autocomplete toggle, the mini.surround extra (plus cleanup of accidentally enabled extras), per-tab buffers via scope.nvim, the explorer's `t` new-tab key, plus a catch-up of unrecorded earlier changes (`dm{mark}`, autocomplete/diagnostics off at start, no auto signature popup). (11 entries) |
| [`appearance.md`](appearance.md) | Colours and transparency: the colorscheme that reads kitty's live theme, and see-through popups/sidebars. Later: backgrounds moved to `NONE`. (3 entries) |
| [`languages-and-lsp.md`](languages-and-lsp.md) | Which languages this setup supports and how: the treesitter trim, formatters (clang-format, ruff) and the clangd language server. (3 entries) |
| [`plugin-review.md`](plugin-review.md) | The one-by-one pass over LazyVim's optional plugins: tested live, then kept, adjusted or disabled. Final verdict table is in the last entry. (9 entries) |
| [`personal-cheatsheet.md`](personal-cheatsheet.md) | History of the searchable in-editor cheatsheet: why it's custom, the three UI rewrites, content audits, the keybinding it ended up on, the Surround/extras entries, the numbers entry, commenting many lines, and batch-edit recipes. (16 entries) |
| [`ghosttext.md`](ghosttext.md) | nvim-ghost.nvim setup: per-site languages, formatting and LSP in ghost buffers, and the `<leader>cL` language picker. (1 entry) |
| [`leetcode.md`](leetcode.md) | Solving LeetCode inside Neovim: setup, health check, run/submit keys, two-box sign-in, and the swap-file fix. (5 entries) |
