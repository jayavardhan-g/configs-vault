# Vim: minimal chrome, terminal-native colors

**Date:** 2026-08-30
**Category:** system
**Files touched:** `~/.vimrc`

<!-- graph:begin -->
**Graph:** [[Vim]]
<!-- graph:end -->

## What
Created `~/.vimrc` (didn't exist before) starting from a common community base config,
then stripped it down visually: no top tabline, no explicit colorscheme (inherit the
terminal's own palette instead), no sign-column gutter on the left, and a single bottom
statusline showing mode + filename + line number.

## Why
User wanted a plain look: "no bars at the top, don't want the theme (It should follow the
terminal theme only), no padding from the left, only one bar at the bottom indicating the
mode, file name, which line number."

## Change
Relative to the base config, four groups of settings:

```vim
" No top tabline - only the bottom statusline should be visible
set showtabline=0

" No left gutter/padding for signs
set signcolumn=no

" Single bottom bar: mode, filename, line/total
set laststatus=2
set noshowmode " mode now lives in the custom statusline, not the command line

" Full mode name (-- NORMAL --, -- INSERT --, ...), like the classic
" showmode bottom-left indicator, but inside the statusline instead.
function! StatuslineMode()
    let l:m = mode()
    let l:names = {
        \ 'n':  'NORMAL',
        \ 'i':  'INSERT',
        \ 'v':  'VISUAL',
        \ 'V':  'V-LINE',
        \ "\<C-v>": 'V-BLOCK',
        \ 'R':  'REPLACE',
        \ 'c':  'COMMAND',
        \ 's':  'SELECT',
        \ 'S':  'S-LINE',
        \ "\<C-s>": 'S-BLOCK',
        \ 't':  'TERMINAL',
        \ }
    return '-- ' . get(l:names, l:m, toupper(l:m)) . ' --'
endfunction

set statusline=%{StatuslineMode()}\ \|\ %f
set statusline+=%=
set statusline+=%l
set statusline+=/
set statusline+=%L
```

```vim
" No Vim colorscheme - follow the terminal's own theme/palette instead.
" (omit `colorscheme ...`, `set background=dark`, `set termguicolors`,
" and the t_8f/t_8b truecolor escape-sequence setup entirely)
syntax on
hi Normal ctermbg=NONE guibg=NONE
hi NonText ctermbg=NONE guibg=NONE guifg=NONE ctermfg=NONE
hi VertSplit guibg=NONE guifg=NONE ctermbg=NONE ctermfg=NONE

" Statusline: a colored accent bar using the terminal's numbered ANSI slots
" (0-15) rather than fixed hex colors, so it re-themes automatically with
" whatever the terminal's colorscheme defines for cyan/black/gray.
hi StatusLine   ctermfg=0  ctermbg=6 cterm=bold
hi StatusLineNC ctermfg=15 ctermbg=8 cterm=NONE
```

## Follow-up: indentation-based folding for every filetype (2026-09-03)

**What**: no `foldmethod` was ever set, so Vim's default `manual` folding applied - no
automatic folds anywhere. Added one global fold method, mirroring the equivalent change
made to Neovim's Treesitter-based folding in the same session (see
[[neovim-minimal-ssh-friendly-setup]]).

**Why**: wanted the same "one fold method that works across languages" outcome as
Neovim, but plain Vim has no Treesitter. First tried `foldmethod=syntax` (reads fold
regions out of each filetype's bundled `syntax/<lang>.vim`), but testing showed this
Vim's bundled `python.vim`/`lua.vim`/`vim.vim` define **no fold regions at all** - those
filetypes stayed fully unfolded. Switched to `foldmethod=indent` instead: pure
indentation-depth folding, language-agnostic, so it actually works for Python/Lua/C/Bash
without depending on what each syntax file happens to implement. Markdown headings are
unaffected by this choice either way, since `ftplugin/markdown.vim` overrides
`foldmethod` to its own heading-based `expr` locally, regardless of the global setting.

**Change** — `~/.vimrc`:
```vim
filetype plugin indent on
let g:markdown_folding = 1 " enable heading folds in ftplugin/markdown.vim
set foldmethod=indent

" Start each buffer fully unfolded, but via `zR` (sets 'foldlevel' to the
" buffer's real deepest fold level) rather than a hardcoded foldlevel=99.
" With foldlevel=99, `zm` (foldlevel -= 1) has to be pressed ~95+ times
" before it reaches actual fold depth and visibly closes anything; zR fixes
" that by landing foldlevel on the true max depth immediately. Gated to
" once per buffer (not every BufWinEnter) so revisiting a buffer/split
" doesn't blow open folds you closed by hand.
function! s:OpenFoldsOnce()
    if !exists('b:fold_zr_done')
        let b:fold_zr_done = 1
        normal! zR
    endif
endfunction
augroup fold_zr_once | au!
    au BufWinEnter * call s:OpenFoldsOnce()
augroup END
```
`filetype plugin indent on` was not previously set at all in this config (only bare
`syntax on`) - needed here because folding for markdown specifically comes from
`ftplugin/markdown.vim` (not the syntax file), which only loads with the `plugin` part
on. This also means ftplugin/indent files for every other filetype now load too, where
they didn't before - a real (wanted) behavior change, not just a folding side effect.

**Verified, not assumed** — tested headlessly against real sample files (`.py`, `.c`,
`.lua`, `.sh`, and this repo's own `.md` files) with `foldmethod=indent` and the real
`~/.vimrc` loaded:
- **Python, Lua, C, Bash**: all fold correctly on nested indentation (function bodies,
  if-blocks) - no per-language flag needed, unlike the `syntax` attempt above.
- **Markdown**: still folds by heading, via `ftplugin/markdown.vim`'s own
  `foldmethod=expr` override (`g:markdown_folding = 1` above) - confirmed the buffer-local
  `&foldmethod` reads `expr`, not `indent`, inside a markdown buffer.
- **Rejected**: `foldmethod=syntax` + `g:sh_fold_enabled` (bash's own opt-in flag) - works,
  but `indent` covers strictly more filetypes with less config, so this was dropped
  rather than kept as a fallback.

## Follow-up: word wrap enabled (2026-09-03)

**What**: switched from `nowrap` (long lines run off-screen, scroll horizontally) to
`wrap` (long lines wrap onto the next screen line).

**Change** — `~/.vimrc`:
```vim
set wrap " Wrap long lines onto the next screen line
```
`linebreak` (already set) means the wrap point still lands on a word boundary rather than
mid-word. `<leader>lw` already toggles this at runtime (`:set wrap!`) if wrap is only
wanted for a specific buffer/session.

## Notes
- **Superseded (2026-09-14)**: `showtabline=0` above ("never show the top tabline") was
  changed to `showtabline=1` (shown only when 2+ tabs are open) as part of a quit/tab
  redesign that wanted a visual indicator of open files - see
  [[vim-neovim-parity-pass]]'s "full quit/tab redesign" section. Everything else in this
  entry (no colorscheme, no left gutter, single bottom statusline) is unchanged; this only
  affects whether the tabline can appear at all, and only when actually using multiple
  tabs day to day, which this setup didn't do before that redesign.
- **Superseded (2026-09-03)**: the fold-level setting above used to be a flat
  `set foldlevel=99` / `set foldlevelstart=99`. That's a literal number, not the buffer's
  real fold depth — `zm` (which does `foldlevel -= 1`) had to be pressed ~95+ times before
  it reached actual fold nesting and visibly closed anything, so it looked broken until
  `zM` (close all, sets `foldlevel=0`) was pressed first. Replaced with the `BufWinEnter`
  autocmd shown above, since `zR` sets `'foldlevel'` to the buffer's *actual* deepest fold
  level rather than a hardcoded number — same "everything unfolded on open" result, but
  `zm` now works correctly on the very first press. Same root cause and fix applied to the
  Neovim config — see [[neovim-minimal-ssh-friendly-setup]].
- Dropping `set termguicolors` is what actually makes "follow the terminal theme" work —
  with it on, syntax groups render via a colorscheme's hardcoded hex `gui*` colors instead
  of the terminal's own ANSI palette, regardless of colorscheme choice. `syntax on` alone
  (no `colorscheme` line, no termguicolors) falls back to the default `cterm*` highlight
  groups, which do respect the terminal's palette.
- `hi Normal/NonText/VertSplit ctermbg=NONE` clears Vim's own background fill so the
  terminal's background shows through instead of Vim imposing one.
- `signcolumn=no` removes the reserved gutter column entirely; if a plugin adding
  gutter signs (git diff markers, LSP diagnostics) gets added later, this will need to
  become `signcolumn=yes` again or signs won't render.
- `timeoutlen`, `incsearch`, `undodir`, and the yank keybindings were changed after this
  entry was written - see [[vim-neovim-parity-pass]] for the current state of those.
- Statusline coloring went through two attempts before landing on the numbered-ANSI-slot
  version above: first `hi link StatusLine Normal` (blend fully with the background), but
  that just rendered as plain terminal-foreground text with no bar at all — not what was
  wanted. Switched to `ctermfg`/`ctermbg` using palette slot numbers (`0`-`15`) instead of
  fixed hex colors: since `termguicolors` is off, Vim renders through these numbered ANSI
  slots, which are whatever colors the terminal's own theme assigns to them — so the bar
  gets a colored accent (cyan background here) that still re-themes automatically if the
  terminal's colorscheme changes, rather than being a fixed color independent of the
  terminal.
