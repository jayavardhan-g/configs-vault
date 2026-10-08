# Vim/Neovim parity pass + leader timeout fix

<!-- graph:begin -->
**Graph:** [[Neovim]] · [[Vim]] · [[SSH]]
<!-- graph:end -->

> **Superseded 2026-09-15 (Neovim side)**: Neovim was migrated to LazyVim - see
> [[lazyvim-migration]]. Every Neovim-specific change below (the `confirm`/quit-flow
> follow-ups, the buffer-tabline, bufferline.nvim/mini.bufremove) no longer describes the
> live Neovim config; kept for the reasoning trail.
>
> **Partially superseded 2026-09-15 (Vim side)**: once Neovim's own keybindings changed
> (LazyVim's defaults, not the hand-rolled ones this entry built to match), several
> `~/.vimrc` keybinds that were originally set *to match Neovim* were re-pointed at
> LazyVim's actual current keys instead - see the final follow-up section at the bottom.
> Everything else in this entry (OSC52 yank, `timeoutlen`, `confirm`, auto-pairs, the
> `:qa` smart-quit logic, the buffer-tabline itself) is unaffected and still current.

**Date:** 2026-08-30
**Category:** system
**Files touched:** `~/.vimrc`, `~/.config/nvim/lua/config/options.lua`,
`~/.config/nvim/lua/config/keymaps.lua`, `~/.config/nvim/lua/plugin-list.lua`,
`~/.vim/pack/plugins/start/vim-oscyank/` (new), `~/.vim/pack/plugins/start/auto-pairs/` (new)

## What
Fixed `timeoutlen` (too short to type a `<leader>` sequence comfortably) in both editors,
carried `spelllang` over to Neovim, then did a side-by-side feature audit between
`~/.vimrc` and the Neovim config (see [[vimrc-minimal-visual-config]] and
[[neovim-minimal-ssh-friendly-setup]]) and imported specific items in each direction —
picked interactively, not "import everything."

## Why
"After leader keypress the time to press others is very low" — `timeoutlen` was 300ms in
both configs, too tight for typing e.g. `<leader>ff` or `<leader>to` at a normal pace.
Also wanted the two configs checked for inconsistencies and gaps now that both exist,
since they were built in separate sessions from different starting points.

## Change

### Both editors
```vim
set timeoutlen=1000 " was 300 - more breathing room after <leader>
```
(`~/.vimrc` line; Neovim equivalent is `set.timeoutlen = 1000` in `lua/config/options.lua`.)

```vim
set confirm " Ask (naming the file) instead of silently refusing to close on unsaved changes
```
(`~/.vimrc` line; Neovim equivalent is `set.confirm = true`.) Fixes: closing a modified
buffer (`:q`, `:qa`, `<C-q>`, `<leader>x`) used to just throw a terse `E37` error - easy to
miss entirely since the quit keymaps are `silent`. With `confirm` on, Neovim/Vim instead
shows an interactive dialog naming the exact file and asking whether to save it, and this
happens regardless of `silent` (that keymap option suppresses echoed messages, not
interactive prompts).

### Carried from Vim → Neovim (`lua/config/options.lua` / `lua/config/keymaps.lua`)
```lua
set.spelllang = "en_us,de_de,es_es"
set.showmatch = true -- briefly flash the matching bracket/paren
```
```lua
-- Increment/decrement the number under the cursor
vim.keymap.set("n", "<leader>+", "<C-a>", opts)
vim.keymap.set("n", "<leader>-", "<C-x>", opts)

-- Yank from cursor to end of line via OSC52, like vim's Y = y$
vim.keymap.set("n", "<leader>Y", "<leader>y$", { remap = true, silent = true })
```

### Carried from Neovim → Vim (`~/.vimrc`)
```vim
set incsearch " Highlight search matches as you type the pattern

set undofile " Save undo history
" Without an explicit undodir, undofile scatters hidden .un~ files into
" whatever directory you're editing in - keep them in one place instead.
set undodir=~/.vim/undodir
```
```vim
" Yank via OSC52: lands in your LOCAL machine's clipboard even over a plain
" SSH session with no X/Wayland forwarding (kitty understands OSC52 both
" locally and over SSH), unlike plain "+y which only reaches whatever
" clipboard exists on the box vim is actually running on.
nmap <leader>y <Plug>OSCYankOperator
vmap <leader>y <Plug>OSCYankVisual
nmap <leader>Y <leader>y$
```
This replaced the previous plain-clipboard binds (`noremap <leader>y "+y"` /
`noremap <leader>Y "+Y"`) rather than living alongside them, matching the Neovim config's
choice to make OSC52 the only yank-to-clipboard path (it's a strict superset — also works
locally, not just over SSH).

`vim-oscyank` was installed for classic Vim as a native Vim8/9 package (no plugin manager
needed for this — Vim auto-loads anything under `~/.vim/pack/*/start/*`):
```
git clone --depth=1 https://github.com/ojroques/vim-oscyank ~/.vim/pack/plugins/start/vim-oscyank
```

### Auto-closing brackets/quotes (added 2026-08-31, Neovim swapped 2026-08-31)
Neither editor had this — `showmatch` (already set in both) only flashes the matching
bracket when you type a closing one, it doesn't insert the closing pair for you.

**Vim** (`~/.vim/pack/plugins/start/auto-pairs/`): `jiangmiao/auto-pairs`, installed as a
native Vim8/9 package:
```
git clone --depth=1 https://github.com/jiangmiao/auto-pairs ~/.vim/pack/plugins/start/auto-pairs
```
It's the only real option for classic Vim (pure Vimscript, no Lua). No further config
needed. Last pushed 2024-07-08, ~170 open issues — not abandoned, but low maintenance
velocity for its popularity.

**Neovim** was on the same `jiangmiao/auto-pairs` too at first (added to
`lua/plugin-list.lua`, for identical behavior with Vim), then swapped to
`windwp/nvim-autopairs` after checking both plugins' actual state: `nvim-autopairs` is
**Treesitter-aware** (won't pair brackets inside a string or comment, which matters given
the Treesitter setup this config already has — see
[[neovim-minimal-ssh-friendly-setup]]) and integrates with **nvim-cmp** (already in use
for completion here), and was far more actively maintained (pushed within the past week
vs. `auto-pairs`' mid-2024, ~15 open issues vs. ~170). It's Lua-only, so this is
Neovim-specific — Vim stays on `jiangmiao/auto-pairs`, its only real option anyway. This
is a deliberate, accepted divergence: the two editors no longer behave identically for
this one feature.

`lua/plugin-list.lua`:
```lua
"windwp/nvim-autopairs",
```
`after/plugin/autopairs.lua` (new):
```lua
require("nvim-autopairs").setup({
    disable_filetype = { "TelescopePrompt", "vim" },
})

local cmp_autopairs = require("nvim-autopairs.completion.cmp")
local cmp = require("cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
```
`disable_filetype` and the `cmp` integration snippet are both exactly as documented in
`nvim-autopairs`' own README, not invented.

## Follow-up: neo-tree was silently blocking the confirm dialog (2026-09-14)

**What broke**: closing a modified file that had been opened via `<leader>e` (neo-tree)
stopped showing the interactive `confirm` dialog above. Instead: a flat, non-interactive
warning —
```
[Neo-tree WARN] Cannot close because one of the files is modified. Please save or discard changes.
```
— with no filename, no Yes/No/Cancel choice, just a "Press ENTER to continue" prompt.
Plain `vim`, plain `nvim <file>` (no neo-tree involved), and `nvim -u NONE` (no plugins at
all) were all unaffected — only the `<leader>e` → open-a-file → edit → quit path hit this.

**Root cause**: `close_if_last_window = true` in
`~/.config/nvim/after/plugin/neotree.lua`. Neo-tree uses this to auto-close itself if it
would otherwise become the last window left in the tab (so you don't get stranded staring
at just the file tree). Checking whether that auto-close is safe involves neo-tree
scanning for unsaved buffers itself, and when it finds one, it intercepts the quit with
its own warning **before** Neovim's native `'confirm'` handling ever runs — not a bug in
`confirm` itself, just a different plugin grabbing the quit command first.

**Fix** — `~/.config/nvim/after/plugin/neotree.lua`:
```lua
close_if_last_window = false,
```
Verified end to end (spawned real nvim, opened a file via `<leader>e`, edited it,
`<C-q>`'d the file window, then `:qa`'d): closing the file window with neo-tree still open
now just hides that buffer (Neovim's `'hidden'` option, on by default — nothing lost,
nothing to confirm, since the buffer isn't actually being abandoned yet). Actually exiting
Neovim (`:qa`, or closing every window) correctly shows the full dialog again:
```
Save changes to "note.txt"?
[Y]es, (N)o, (C)ancel:
```
Trade-off accepted: if every real file window gets closed, the neo-tree sidebar now stays
open by itself instead of auto-closing — chosen deliberately over neo-tree's own warning
replacing the confirm dialog.

### `<C-q>` now always prompts, even with the sidebar open (2026-09-14, superseded same day)

**Superseded** by the full redesign below — `<C-q>` was reverted back to plain `:q` a few
hours later in the same session, once the actual requirement turned out to be "don't
prompt when just closing one file, only when quitting nvim/vim entirely." Kept here for
the reasoning trail; skip to the next section for the current behavior.

**What**: after the fix above, `<C-q>` on a modified file with the sidebar still open went
back to Neovim's normal behavior — closes the window silently (buffer just goes hidden,
nothing lost yet, so nothing to confirm), and only `:qa` (actually exiting) showed the
dialog. Wanted `<C-q>` itself to always prompt for that one file, sidebar open or not,
rather than having to remember `:qa` is the only path that asks.

**Change** — replaced the plain `<C-q>` → `:q` mapping in both editors with a function
that checks `'modified'` on the current buffer directly and calls `confirm()` itself,
instead of relying on Vim/Neovim's own "is this the last window on this buffer" check:

`~/.vimrc`:
```vim
function! QuitWithConfirm()
    if &modified
        let l:name = bufname('%')
        if l:name ==# ''
            let l:name = '[No Name]'
        endif
        let l:choice = confirm('Save changes to "' . l:name . '"?', "&Yes\n&No\n&Cancel")
        if l:choice == 1
            write
            quit
        elseif l:choice == 2
            quit!
        endif
    else
        quit
    endif
endfunction
nnoremap <C-q> :call QuitWithConfirm()<CR>
```

`~/.config/nvim/lua/config/keymaps.lua` (same logic, Lua):
```lua
local function quit_with_confirm()
  if vim.bo.modified then
    local name = vim.fn.bufname("%")
    if name == "" then
      name = "[No Name]"
    end
    local choice = vim.fn.confirm('Save changes to "' .. name .. '"?', "&Yes\n&No\n&Cancel")
    if choice == 1 then
      vim.cmd("write")
      vim.cmd("quit")
    elseif choice == 2 then
      vim.cmd("quit!")
    end
  else
    vim.cmd("quit")
  end
end
vim.keymap.set("n", "<C-q>", quit_with_confirm, opts)
```

Verified live in both editors: sidebar + file open, edit the file, `<C-q>` → dialog shows
immediately, no `:qa` needed. Plain `:q` typed manually (not through the keymap) still
follows the original last-window-only behavior — this only changes the `<C-q>` keymap
itself, not the underlying `:q` command.

## Follow-up: full quit/tab redesign - "don't bug me per file, bug me on real exit" (2026-09-14)

**What changed the requirement**: after using the `<C-q>`-always-prompts behavior above
for a bit, the actual want turned out to be the opposite for the common case — closing
one file while still working in nvim/vim shouldn't ask anything (nothing is lost, the
buffer just goes hidden), and only **actually exiting** the editor should trigger any
save/discard decisions. Five requirements, worked out via clarifying questions:
1. The sidebar (neo-tree/netrw) should never factor into any of this.
2. Closing one file while the session stays open just closes it - no prompt.
3. Closing the whole session with exactly one modified file: jump to it, ask Yes/No/Cancel.
4. Closing the whole session with several modified files: cycle through them one at a
   time with Yes/No/**Skip**/Save All/Discard All/Cancel per file (Skip = leave that one
   open and unsaved, keep asking about the rest; Cancel = abort the whole quit, whatever
   was already resolved earlier in the cycle stays resolved).
5. A visual indicator of open files/tabs.

**Investigated first, before writing anything**: spawned real nvim with 3 files and
`:qa`, confirmed Vim/Neovim's own `'confirm'` option (already on) already does most of
requirement 4 natively - cycles modified buffers one at a time, offers inline `Save All`/
`Discard All`, and auto-simplifies to a plain `Yes/No/Cancel` once only one buffer is
left. The only real gaps versus the requirements: no `Skip` option, and it doesn't visibly
jump focus to the file it's asking about. So the fix wraps native behavior rather than
replacing it for the single-file case, and only hand-rolls the loop for the multi-file
case (to add `Skip` + jumping).

**Tabs (requirement 5)**: real "one tab per file, VSCode-style" needs `bufferline.nvim`
(a plugin, Neovim-only) and is a *different* concept from Vim's own tabpages already bound
to `<leader>to/tx/tn/tp` (whole window layouts, not per-file). Went with a much cheaper
option instead: Vim's own **built-in tabline**, just turned back on. Since Vim's tabline
shows one entry per open tabpage with a `+` prefix on any tab containing a modified
buffer, and this codebase already opens each file as a tabpage in daily use, it gives the
"which files are open, which are modified" indicator that was actually wanted, with zero
plugins, identically in both editors. This directly **supersedes** the deliberate
`showtabline=0` decision in [[vimrc-minimal-visual-config]] ("no bars at the top, only one
bottom bar") - see that entry's Notes for the reversal.

### Change 1: tabline back on (both editors)

`~/.vimrc`:
```vim
set showtabline=1 " Built-in tabline, shown only when 2+ tabs are open
```
`~/.config/nvim/lua/config/options.lua`:
```lua
set.showtabline = 1 -- built-in tabline, shown only when 2+ tabs are open
```
`showtabline=1` (not `2`) specifically so it stays invisible with only one file open,
matching the "no bars unless there's something to show" spirit of the original decision.

### Change 2: `<C-q>` reverted to plain `:q` (both editors)

Undoes the `QuitWithConfirm`/`quit_with_confirm` functions from the section above -
closing one file is back to silent (buffer goes hidden, nothing lost, matches requirement 2):
```vim
nnoremap <C-q> :q<CR>
```
```lua
vim.keymap.set("n", "<C-q>", "<cmd>q<CR>", opts)
```

### Change 3: `:qa` becomes the smart, deliberate "quit everything" action

Typing `:qa` (exactly that string, at the `:` command line - not `:qall`/`:quita` in
full) now routes to a custom function, via a guarded `cnoreabbrev` (guarded so it only
fires when the whole command line is literally `qa`, not e.g. as a substring of a longer
command):

`~/.vimrc`:
```vim
function! s:FocusBuffer(bufnr) abort
    let l:wins = win_findbuf(a:bufnr)
    if len(l:wins) > 0
        call win_gotoid(l:wins[0])
    else
        execute 'tab sbuffer ' . a:bufnr
    endif
endfunction

function! s:ListModified() abort
    let l:out = []
    for l:buf in getbufinfo({'buflisted': 1})
        if l:buf.changed
            call add(l:out, l:buf.bufnr)
        endif
    endfor
    return l:out
endfunction

function! QuitAllSmart() abort
    let l:modified = s:ListModified()

    if empty(l:modified)
        qa
        return
    endif

    if len(l:modified) == 1
        " Only one file needs a decision: jump to it and let Vim's own
        " 'confirm' dialog (Yes/No/Cancel) handle the rest.
        call s:FocusBuffer(l:modified[0])
        qa
        return
    endif

    let l:i = 0
    while l:i < len(l:modified)
        let l:bufnr = l:modified[l:i]
        if getbufvar(l:bufnr, '&modified')
            call s:FocusBuffer(l:bufnr)
            let l:name = bufname(l:bufnr)
            if l:name ==# ''
                let l:name = '[No Name]'
            endif
            let l:choice = confirm('Save changes to "' . l:name . '"?', "&Yes\n&No\n&Skip\nSave &All\n&Discard All\n&Cancel")
            if l:choice == 1
                execute 'buffer ' . l:bufnr
                write
            elseif l:choice == 2
                call setbufvar(l:bufnr, '&modified', 0)
            elseif l:choice == 3
                " Skip: leave it modified, move on to the next one.
            elseif l:choice == 4
                let l:j = l:i
                while l:j < len(l:modified)
                    let l:b = l:modified[l:j]
                    if getbufvar(l:b, '&modified')
                        execute 'buffer ' . l:b
                        write
                    endif
                    let l:j += 1
                endwhile
                break
            elseif l:choice == 5
                let l:j = l:i
                while l:j < len(l:modified)
                    call setbufvar(l:modified[l:j], '&modified', 0)
                    let l:j += 1
                endwhile
                break
            else
                return " Cancel/Esc: stop here, already-resolved files stay resolved
            endif
        endif
        let l:i += 1
    endwhile

    if empty(s:ListModified())
        qa
    else
        echohl WarningMsg
        echo 'Quit cancelled - some files were skipped and are still unsaved.'
        echohl None
    endif
endfunction

command! QuitAllSmart call QuitAllSmart()
cnoreabbrev <expr> qa (getcmdtype() ==# ':' && getcmdline() ==# 'qa') ? 'QuitAllSmart' : 'qa'
```

`~/.config/nvim/lua/config/keymaps.lua` (same logic, Lua):
```lua
local function focus_buffer(bufnr)
  local wins = vim.fn.win_findbuf(bufnr)
  if #wins > 0 then
    vim.api.nvim_set_current_win(wins[1])
  else
    vim.cmd("tab sbuffer " .. bufnr)
  end
end

local function list_modified()
  local out = {}
  for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if buf.changed == 1 then
      table.insert(out, buf.bufnr)
    end
  end
  return out
end

local function quit_all_smart()
  local modified = list_modified()

  if #modified == 0 then
    vim.cmd("qa")
    return
  end

  if #modified == 1 then
    focus_buffer(modified[1])
    vim.cmd("qa")
    return
  end

  local i = 1
  while i <= #modified do
    local bufnr = modified[i]
    if vim.bo[bufnr].modified then
      focus_buffer(bufnr)
      local name = vim.fn.bufname(bufnr)
      if name == "" then
        name = "[No Name]"
      end
      local choice =
        vim.fn.confirm('Save changes to "' .. name .. '"?', "&Yes\n&No\n&Skip\nSave &All\n&Discard All\n&Cancel")
      if choice == 1 then
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd("write")
        end)
      elseif choice == 2 then
        vim.bo[bufnr].modified = false
      elseif choice == 3 then
        -- Skip: leave it modified, move on to the next one.
      elseif choice == 4 then
        for j = i, #modified do
          local b = modified[j]
          if vim.bo[b].modified then
            vim.api.nvim_buf_call(b, function()
              vim.cmd("write")
            end)
          end
        end
        break
      elseif choice == 5 then
        for j = i, #modified do
          vim.bo[modified[j]].modified = false
        end
        break
      else
        return -- Cancel/Esc: stop here, already-resolved files stay resolved
      end
    end
    i = i + 1
  end

  if #list_modified() == 0 then
    vim.cmd("qa")
  else
    vim.notify("Quit cancelled - some files were skipped and are still unsaved.", vim.log.levels.WARN)
  end
end

vim.api.nvim_create_user_command("QuitAllSmart", quit_all_smart, {})
vim.cmd([[cnoreabbrev <expr> qa (getcmdtype() ==# ':' && getcmdline() ==# 'qa') ? 'QuitAllSmart' : 'qa']])
```

The sidebar (neo-tree/netrw) satisfies requirement 1 for free here: `getbufinfo({buflisted
= 1})` never includes it (neither plugin lists its own UI buffer), so it's never counted
as modified and never interferes with any of this.

**Verified live, both editors**, spawning real nvim/vim processes and driving actual
keystrokes (not just reading the code):
- 2 tabs open → tabline renders both filenames with distinct active/inactive highlighting;
  modified ones get a `+` prefix.
- `<C-q>` on a modified file with the sidebar/other tabs still open → closes silently, no
  prompt, lands on whatever tab is next - confirmed no "Save changes" text appears at all.
- 3 tabs, only one modified, cursor sitting on an unrelated tab, then `:qa` → confirmed
  focus jumped to the modified tab (its tabline entry became the active-highlighted one)
  before showing `Save changes to "c.txt"? [Y]es, (N)o, (C)ancel:`.
- 3 tabs, all modified, `:qa` → first prompt correctly listed all six options including
  `(S)kip`; pressed Skip on file 1, No on file 2, Yes on file 3 (confirmed it actually
  wrote to disk); final result was exactly `Quit cancelled - some files were skipped and
  are still unsaved.` rather than exiting, since file 1 was still modified. Same sequence,
  same result, in both vim and nvim.

## Follow-up: buffer-based tabline instead of real tabpages (2026-09-15)

**What broke**: using the tabline redesign above as intended (one real Vim tab per file,
via `<leader>to`) meant every tab got its **own separate neo-tree/netrw sidebar** - a real
Vim tabpage is a fully independent window layout, so there's no way for one window object
to be shared across tabs. With 2 files open this way that's 4 real windows (2 sidebars + 2
files), so closing everything needed 4 `:q` presses instead of 2. Confirmed directly via
`getwininfo()`: `['1:neo-tree filesystem [1]', '1:a.txt', '2:neo-tree filesystem [2]',
'2:a.txt']` - two distinct neo-tree instances, `[1]` and `[2]`.

**Root cause, and the actual fix**: opening a *second* file from the sidebar **without**
creating a new tab (just navigating back into the same still-open sidebar and pressing
`l` again) already reuses the existing file window correctly - confirmed via the same
`getwininfo()` check, staying at exactly 2 windows (1 sidebar + 1 file) no matter how many
files get opened that way. The problem was never neo-tree/netrw - it was the tabline
itself teaching a real-tabpage-per-file workflow that doesn't fit one shared sidebar.
Fix: stop using real tabpages as "file tabs" and render the tabline from **buffers**
instead (VSCode-style: one entry per open file, all inside a single tab). Switching files
is `<Tab>`/`<S-Tab>` (already bound to `:bnext`/`:bprevious`), not `<leader>to`.

**Change 1** — replaced the plain `showtabline=1` line from the section above with a
custom buffer-based renderer, `~/.vimrc`:
```vim
function! BufferTabline() abort
    let l:s = ''
    let l:current = bufnr('%')
    for l:buf in getbufinfo({'buflisted': 1})
        if getbufvar(l:buf.bufnr, '&filetype') !=# 'netrw'
            let l:name = fnamemodify(l:buf.name, ':t')
            if l:name ==# ''
                let l:name = '[No Name]'
            endif
            let l:modified = l:buf.changed ? '+' : ''
            let l:s .= (l:buf.bufnr == l:current ? '%#TabLineSel#' : '%#TabLine#')
            let l:s .= ' ' . l:modified . l:name . ' '
        endif
    endfor
    return l:s . '%#TabLineFill#'
endfunction
set tabline=%!BufferTabline()

function! s:CountRealBuffers() abort
    let l:n = 0
    for l:buf in getbufinfo({'buflisted': 1})
        if getbufvar(l:buf.bufnr, '&filetype') !=# 'netrw'
            let l:n += 1
        endif
    endfor
    return l:n
endfunction

function! s:UpdateShowtabline() abort
    let &showtabline = s:CountRealBuffers() >= 2 ? 2 : 0
endfunction

augroup buffer_tabline_visibility | au!
    " Only buffer count needs to trigger this (not modified-state changes -
    " Vim redraws the tabline's content on its own already). BufModifiedSet
    " doesn't exist in this Vim version (it's Neovim-only) - don't add it.
    au BufAdd,BufDelete,BufEnter * call s:UpdateShowtabline()
augroup END
call s:UpdateShowtabline()
```

`~/.config/nvim/lua/config/options.lua` (same logic, Lua):
```lua
function _G.buffer_tabline()
  local s = ""
  local current = vim.fn.bufnr("%")
  for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    local ft = vim.bo[buf.bufnr].filetype
    if ft ~= "neo-tree" and ft ~= "netrw" then
      local name = vim.fn.fnamemodify(buf.name, ":t")
      if name == "" then
        name = "[No Name]"
      end
      local modified = buf.changed == 1 and "+" or ""
      s = s .. (buf.bufnr == current and "%#TabLineSel#" or "%#TabLine#")
      s = s .. " " .. modified .. name .. " "
    end
  end
  return s .. "%#TabLineFill#"
end
vim.o.tabline = "%!v:lua.buffer_tabline()"

local function count_real_buffers()
  local n = 0
  for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    local ft = vim.bo[buf.bufnr].filetype
    if ft ~= "neo-tree" and ft ~= "netrw" then
      n = n + 1
    end
  end
  return n
end

local function update_showtabline()
  vim.o.showtabline = count_real_buffers() >= 2 and 2 or 0
end
-- Only buffer count needs to trigger this (not modified-state changes -
-- Neovim redraws the tabline's content on its own already).
vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter" }, {
  callback = update_showtabline,
})
update_showtabline()
```
Hidden (`showtabline=0`) below 2 real file buffers, same "invisible unless there's
something to show" spirit as the original decision this all traces back to - see
[[vimrc-minimal-visual-config]].

**Change 2** — `QuitAllSmart`'s `FocusBuffer`/`focus_buffer` (from the section above) no
longer opens a new tab for a hidden modified buffer (`tab sbuffer`); it now reuses a
non-sidebar window in the current tab, or splits one if only the sidebar is open, to match
the single-tab model:

`~/.vimrc`:
```vim
function! s:FocusBuffer(bufnr) abort
    let l:wins = win_findbuf(a:bufnr)
    if len(l:wins) > 0
        call win_gotoid(l:wins[0])
        return
    endif
    for l:info in getwininfo()
        if l:info.tabnr == tabpagenr() && getbufvar(l:info.bufnr, '&filetype') !=# 'netrw'
            call win_gotoid(l:info.winid)
            execute 'buffer ' . a:bufnr
            return
        endif
    endfor
    vsplit
    execute 'buffer ' . a:bufnr
endfunction
```
`~/.config/nvim/lua/config/keymaps.lua` (same logic, Lua): iterates
`nvim_tabpage_list_wins(0)`, skips any window whose buffer's `filetype` is `neo-tree`/
`netrw`, reuses the first real one via `nvim_set_current_win` + `:buffer`, falls back to
`:vsplit` only if none exists.

**Bug caught during verification**: first pass used a single `au
BufAdd,BufDelete,BufEnter,BufModifiedSet * ...` autocmd in `~/.vimrc`. Plain Vim 9.2 has
no `BufModifiedSet` event (`E216: No such group or event`) - it's Neovim-only - which
aborted that whole `:autocmd` registration (not just the invalid event), silently breaking
the showtabline-visibility logic and cascading into broken window navigation later in the
same test. Fixed by dropping `BufModifiedSet` entirely, from **both** editors: it was
unnecessary anyway - only buffer *count* needs to retrigger the visibility check; the `+`
marker's content refreshes automatically whenever Vim/Neovim redraws the tabline, no
explicit event needed for that part.

**Verified live, both editors**, after the fix:
- Opened 3 files from the sidebar within one tab (navigating back into the sidebar between
  each, never using `<leader>to`): stayed at `1 tabs, 2 windows` the entire time -
  `getwininfo()` showed exactly one `neo-tree filesystem [1]` + the current file, no matter
  how many files had been opened.
- Tabline showed all three filenames as separate entries with a `+` prefix on modified
  ones, current buffer visually distinct (`TabLineSel` vs `TabLine` highlight).
- `:qa` with 2 of the 3 files modified: jumped to the first modified one (reusing the
  existing file window, confirmed no new tab was created - stayed at `1 tabs`), showed the
  full `Yes/No/Skip/Save All/Discard All/Cancel` prompt exactly as before.
- One file open only: `&showtabline` reads `0` in both editors - tabline stays invisible
  for the common single-file case.
- `~/.vimrc` sources with zero errors after the `BufModifiedSet` fix (re-verified after
  the first run surfaced `E216`).

## Follow-up: `<leader>tn`/`<leader>tp` were stuck (2026-09-15)

**What broke**: the buffer-tabline follow-up above moved files onto a single shared tab,
but `<leader>tn`/`<leader>tp` still ran `:tabn`/`:tabp` - real Vim tabpage navigation. With
only one real tabpage left (by design), those commands had nothing to cycle to, so they
appeared to just do nothing ("stuck at a tab").

**Change** — repointed `<leader>tn`/`<leader>tp` at the buffer-tabline instead (aliases of
the already-existing `<Tab>`/`<S-Tab>`), matching what the tabline actually shows now.
`<leader>to`/`<leader>tx` are left as real `:tabnew`/`:tabclose` - rarely needed day to day
under this model, kept only for the rare case of wanting a genuinely separate window
layout (e.g. an unrelated second project open side by side).

`~/.vimrc`:
```vim
nnoremap <leader>tn :bnext<CR>
nnoremap <leader>tp :bprevious<CR>
```
`~/.config/nvim/lua/config/keymaps.lua`:
```lua
vim.keymap.set("n", "<leader>tn", "<cmd>bnext<CR>", opts)
vim.keymap.set("n", "<leader>tp", "<cmd>bprevious<CR>", opts)
```

Verified live in nvim: with `a.txt`/`b.txt` open as buffers on one tab, `<leader>tn`
correctly cycled `a.txt → b.txt`, then wrapped back to `a.txt`.

## Follow-up: replaced hand-rolled tabline with real plugins (2026-09-15)

**Why**: after three separate bugs building the tabline from scratch (duplicate sidebar
per tab, `BufModifiedSet` not existing in plain Vim, stale `<leader>tn`/`tp`), stopped to
check whether an established, battle-tested solution already existed before continuing to
hand-roll. It did - researched rather than assumed:
- **`akinsho/bufferline.nvim`**: still the standard for this in Neovim as of 2026 (ships by
  default in LazyVim). Operates on buffers, not real tabpages - exactly the model this
  setup needs. Has a documented `offsets` option specifically for coexisting with a
  sidebar plugin as one persistent layout. Maintenance has slowed (last push 2025-01) but
  it's not displaced or abandoned.
- **`ap/vim-buftabline`**: the right fit for plain Vim specifically - purpose-built to
  *only* render the tabline (unlike `vim-airline`, which is a whole statusline framework
  and would fight this config's existing hand-rolled statusline). Actively maintained
  (pushed 2025-12).
- **The custom `:qa` smart-quit logic (Yes/No/Skip/Save All/Discard All/Cancel) has no
  existing equivalent** - checked `mini.bufremove`, `confirm-quit.nvim`, `vim-smartq`,
  `bufkill`, and others; none implement a per-file "skip and keep asking" flow during a
  multi-buffer quit. That part is intentionally **kept exactly as built** in the two
  follow-ups above - this change only replaces tabline *rendering*.

**Change - Neovim**: added `"akinsho/bufferline.nvim"` to `lua/plugin-list.lua` (clones
automatically via the existing `lua/manage.lua` loader, no manual step). Removed the whole
hand-rolled `buffer_tabline`/`count_real_buffers`/`update_showtabline` block from
`lua/config/options.lua`. New `after/plugin/bufferline.lua`:
```lua
require("bufferline").setup({
    options = {
        mode = "buffers", -- one tab per open file, not per real Vim tabpage
        always_show_bufferline = false, -- hidden with only one file open
        show_buffer_close_icons = false,
        show_close_icon = false,
        offsets = {
            {
                filetype = "neo-tree",
                text = "File Explorer",
                highlight = "Directory",
                separator = true,
            },
        },
    },
})
```
`<Tab>`/`<S-Tab>` and `<leader>tn`/`<leader>tp` (`lua/config/keymaps.lua`) switched from
`bnext`/`bprevious` to `BufferLineCycleNext`/`BufferLineCyclePrev`, since bufferline
supports drag-to-reorder tabs with the mouse (`mouse=a` already on) - cycling now follows
the *visual* tab order shown, not raw buffer-number order.

**Change - Vim**: installed as a native package (matching how `vim-oscyank`/`auto-pairs`
were installed):
```bash
git clone --depth=1 https://github.com/ap/vim-buftabline ~/.vim/pack/plugins/start/vim-buftabline
```
Removed the whole hand-rolled `BufferTabline`/`s:CountRealBuffers`/`s:UpdateShowtabline`
block (and its now-unnecessary `BufModifiedSet`-avoidance workaround) from `~/.vimrc`,
replaced with:
```vim
let g:buftabline_show = 1        " hidden below 2 real files, like the old custom logic
let g:buftabline_indicators = 1  " modified marker per tab
```
netrw's buffer is excluded automatically, for free - it was never `buflisted`, which is
all `g:buftabline_show`/vim-buftabline's own buffer enumeration looks at, same as the
hand-rolled version relied on.

**Verified live, both editors**, after the swap:
- Neovim: `bufferline.nvim` auto-cloned into `~/.local/share/nvim/plugins/` on next
  launch (confirmed present in that directory afterward). 3 files opened from the sidebar
  within one tab stayed at `1 tabs, 2 windows` throughout (same sidebar-sharing behavior
  as before, unaffected by the tabline swap). Tabs rendered with proper separators and a
  `●` modified-dot per akinsho's own styling (nicer than the hand-rolled `+`). `:qa` with
  2 modified files still jumped to the first one and showed the full
  `Yes/No/Skip/Save All/Discard All/Cancel` prompt exactly as before - the quit logic
  reads buffer state directly via the Vim/Neovim API, so it's fully decoupled from
  whatever renders the tabline.
- Vim: `&showtabline` reads `1` with one file open (bar hidden, no visible row) and the
  tab row `a.txt  b.txt` appears correctly the moment a second real file buffer opens.
  `:qa` still correctly showed `Save changes to "...a.txt"? [Y]es, (N)o, (C)ancel:`.

## Follow-up: `<leader>x` was collapsing the file window (2026-09-15)

**What broke**: `<leader>x` (`:bdelete`) on a file, with the sidebar (or any other window)
also open, closed the file's window entirely instead of switching it to a fallback
buffer - leaving the sidebar to expand and fill the whole screen. Afterward `<leader>e`
just toggled that single full-width sidebar open/closed, never showing both again until a
file was reopened from it. All three symptoms reported ("`<leader>x` deletes the buffer
but keeps only the explorer," "explorer expands fully," "`<leader>e` shows one or the
other, never both") were this **one** bug, not three.

**Root cause, isolated before touching anything**: confirmed via direct testing that this
has nothing to do with neo-tree or bufferline.nvim - reproduced identically with a plain
two-window vertical split and zero sidebar involved. `:bdelete`/`:bwipeout` closing the
window itself (rather than falling back to another buffer) once more than one window is
open is real Vim/Neovim behavior, not something introduced by this config.

**Researched rather than hand-rolled**: this is a well-known annoyance with an established
fix.
- **Neovim: `nvim-mini/mini.bufremove`** - actively maintained (pushed 2026-07), 0 open
  issues, explicitly built to delete a buffer while preserving window layout. Usable
  standalone (its docs explicitly cover installing it apart from the rest of `mini.nvim`).
  Checked alternatives first: `famiu/bufdelete.nvim` is **archived**/no longer maintained
  despite being more starred; `ojroques/nvim-bufdel` hasn't been pushed since 2023.
- **Plain Vim: `moll/vim-bbye`** - nothing purpose-built for this is *actively* maintained
  in the strict sense (`qpkorr/vim-bufkill` hasn't been pushed since 2022), but vim-bbye is
  stable, pure Vimscript, zero dependencies, and does exactly this - the same tier of
  plugin this config already accepted for Vim with `jiangmiao/auto-pairs` (see the
  "Auto-closing brackets/quotes" section above, chosen despite low maintenance velocity
  because it's the only real option and does its one job).

**Change - Neovim**: added `"nvim-mini/mini.bufremove"` to `lua/plugin-list.lua`. New
`after/plugin/bufremove.lua`:
```lua
require("mini.bufremove").setup()
```
`lua/config/keymaps.lua` - `<leader>x` changed from `<cmd>bdelete<CR>` to:
```lua
vim.keymap.set("n", "<leader>x", function()
  require("mini.bufremove").delete(0, false)
end, opts)
```

**Change - Vim**: installed as a native package (same pattern as `vim-oscyank`/
`auto-pairs`/`vim-buftabline`):
```bash
git clone --depth=1 https://github.com/moll/vim-bbye ~/.vim/pack/plugins/start/vim-bbye
```
`~/.vimrc` - `<leader>x` changed from `:bdelete<CR>` to `:Bdelete<CR>`.

**Verified live, both editors**, reproducing the exact original scenario (sidebar + two
real file buffers, delete the currently-shown one): the window no longer collapses in
either editor - it correctly falls back to the other real buffer (`a.txt`) instead, and
falls back to an empty scratch buffer (not a window close) once no real files are left.
`<leader>e` toggling afterward correctly shows both the sidebar and the file window
side by side again, exactly as before this bug.

## Notes
- **Not a real technical conflict**: `~/.vimrc` and `~/.config/nvim/` never load in the
  same process (you run either `vim` or `nvim`), so nothing here can break the other
  editor. The "conflicts" were purely about the same key doing different things depending
  on which editor is running - worth knowing so muscle memory doesn't trip you up, not
  bugs to fix.
- `signcolumn` staying `no` in Vim vs `yes` in Neovim is intentional, not an oversight -
  Neovim needs the gutter for LSP diagnostic icons; plain Vim has no LSP. See
  [[neovim-minimal-ssh-friendly-setup]].
- **Declined, don't re-propose without being asked**: clearing search highlight on `<Esc>`
  (`:noh`) in Neovim - low value since `hlsearch` is already off in both configs; and a
  `<leader>rl` reload-config keybind for Vim - Neovim has one, Vim doesn't, and it was
  explicitly left out.
- `<leader>Y` in both editors is deliberately kept as "yank cursor-to-end-of-line" (vim's
  classic `Y` = `y$` semantics), not "yank whole line" (`yy`) - confirmed this is what was
  wanted before implementing it in Neovim.
- The `<leader>Y` mapping works by re-triggering the already-defined `<leader>y` operator
  mapping with `$` appended, so it needs a **recursive** map (`nmap`/`remap = true`), not
  `noremap` - otherwise `<leader>` + `y` inside the RHS wouldn't resolve back to the
  OSCYank operator.

## Follow-up: re-matched Vim keybinds to LazyVim's actual keys, dropped jk/kj (2026-09-15)

**What**: since Neovim moved to LazyVim (see [[lazyvim-migration]]; the key-by-key LazyVim
comparison is in [[keybindings-and-editing]]), the reason several
`~/.vimrc` keybinds looked the way they did - "match what Neovim does" - no longer holds,
because Neovim's own keys changed. Re-pointed the Vim side at LazyVim's *current* defaults
instead of leaving it matching the old, now-dead hand-rolled Neovim config. Also dropped
`jk`/`kj` to exit insert mode entirely (no replacement requested).

**Why**: explicit request - keep OSC52 as-is, drop `jk`/`kj`, and bring the keybinds that
were changed to mirror Neovim back in line with what Neovim actually does now.

**Change** - `~/.vimrc`:
```vim
" Resize with arrows (Ctrl held - matches LazyVim's <C-Up/Down/Left/Right>,
" bare arrows freed up for normal cursor movement)
nnoremap <C-Up> :resize -2<CR>
nnoremap <C-Down> :resize +2<CR>
nnoremap <C-Left> :vertical resize -2<CR>
nnoremap <C-Right> :vertical resize +2<CR>

" Navigate buffers - H/L, matching LazyVim's <S-h>/<S-l> (this sacrifices
" H/L's default screen-top/bottom jump, same trade LazyVim makes)
nnoremap H :bprevious<CR>
nnoremap L :bnext<CR>

" window management
" Vertical split matches LazyVim's <leader>|; horizontal split stays on
" <leader>h (LazyVim's own <leader>- collides with increment/decrement,
" kept as-is on purpose - see the Notes below).
nnoremap <leader><Bar> <C-w>v
nnoremap <leader>h <C-w>s
nnoremap <leader>wd :close<CR>  " was <leader>xs

" Real Vim tabpages, under LazyVim's <leader><tab> prefix instead of the old
" <leader>to/tx/tn/tp
nnoremap <leader><tab><tab> :tabnew<CR>
nnoremap <leader><tab>d :tabclose<CR>
nnoremap <leader><tab>] :tabnext<CR>
nnoremap <leader><tab>[ :tabprevious<CR>
nnoremap <leader><tab>f :tabfirst<CR>
nnoremap <leader><tab>l :tablast<CR>

" Key matches LazyVim's native <leader>bd (mini.bufremove did the same job
" there before the migration); new-buffer moved off <leader>b to avoid
" clashing with it.
nnoremap <leader>bd :Bdelete<CR>  " was <leader>x
nnoremap <leader>bn :enew<CR>     " was <leader>b

" toggle line wrapping - matches LazyVim's <leader>uw
nnoremap <leader>uw :set wrap!<CR>  " was <leader>lw
```
Removed entirely (no LazyVim equivalent kept, none requested):
```vim
inoremap jk <ESC>
inoremap kj <ESC>
```

**Conflict surfaced and resolved by the user**: LazyVim's actual horizontal-split key is
`<leader>-`, which collides with this config's own `<leader>-` (decrement number - added
independently during the original parity pass above, not something LazyVim defines).
Checked and confirmed LazyVim has no leader-based increment/decrement keybind at all (it
just leaves Vim's native `<C-a>`/`<C-x>` alone), so there was no LazyVim convention being
protected by keeping `<leader>-` for decrement - purely this config's own addition.
Decision: **keep** `<leader>+`/`<leader>-` for increment/decrement unchanged, and leave
horizontal split on its old `<leader>h` rather than moving it to the colliding
`<leader>-`. Vertical split still moved to `<leader>|` (LazyVim's key, no conflict there).

**Verified**: `vim -Nu ~/.vimrc -c 'echo "OK"' -c 'qa!'` sources with zero errors after all
the above changes.

**Not changed / out of scope**: `<leader>se` (equalize windows) and `<leader>sb` (buffer
list) have no corresponding LazyVim-diff callout, left as-is. LazyVim's `<leader>cd` (line
diagnostics) has no Vim equivalent (no LSP in plain Vim) - not ported, matches the existing
`signcolumn=no`-in-Vim-vs-`yes`-in-Neovim divergence already noted above.
