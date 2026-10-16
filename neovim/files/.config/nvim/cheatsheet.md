# Cheatsheet

Searchable reference for this exact setup. `<lead>` = Space (the leader key).
Entries tagged **[custom]** differ from stock LazyVim - the default is noted too.
Boxes labelled "What you see" are sketches of the real UI, not pixel-exact.

## Find & Search

### Find text in the current line
Starts on the cursor's line - but here Flash extends these: if the
character isn't on this line, `f` keeps going onto the lines after it.

- `f{char}` / `F{char}` - jump to next / previous `{char}` on this line
- `f` / `F` again - the next / previous match (as well as `;` / `,`)
- `t{char}` / `T{char}` - jump just before next / after previous `{char}`
- `;` / `,` - repeat that jump forward / backward
- `0`, `^`, `$` - start of line, first non-blank, end of line

What you see:

```text
  local timeout = get_timeout(config)
  █                                        press  f(
  local timeout = get_timeout(config)
                             █             cursor lands on the "("

  then  ;  → jumps to the next "(" on the line, if any
```

Combine with operators: `df(` deletes up to and including the `(`, `dt(`
stops just before it.

Default: keep `f` / `t` on the current line - `opts = { modes = { char = {
multi_line = false } } }` on the flash spec in `lua/plugins/flash.lua` -
true/false (now `true`).

### Find text in the current file
- `/pattern` then `<CR>` - search forward from the cursor
- `n` / `N` - next / previous match
- `*` / `#` - search the word under the cursor forward / backward
- `<lead>sb` - fuzzy-search this buffer's lines in a picker

What you see:

```text
  every match highlights at once, and the count shows bottom-right:

      local timeout = 30
            ▔▔▔▔▔▔▔
      if timeout > 0 then
         ▔▔▔▔▔▔▔
  /timeout                                          [2/7]
                                                     ▲
                                        you are on match 2 of 7
```

Search is case-smart: an all-lowercase pattern matches any case, but adding
a capital makes it case-sensitive. `<Esc>` clears the highlighting.

Defaults, in `lua/config/options.lua`:
- `vim.opt.ignorecase = true` - true/false: ignore case in searches
- `vim.opt.smartcase = true` - true/false: …unless the pattern has a capital
(now both `true`)

### Find text across the whole project
- `<lead>sg` - live grep from the project root (ripgrep)
- `<lead>/` - same thing, shorter key
- `<lead>sG` - grep from the current working directory instead
- `<lead>sw` / `<lead>sW` - grep the word under the cursor (root / cwd)

What you see:

```text
  ╭─ Grep ─────────────────────────╮╭─ Preview ──────────────╮
  │ > timeout                      ││  local timeout = 60    │
  ├────────────────────────────────┤│  if timeout > 0 then   │
  │ config.lua:12   timeout = 60   ││    run(timeout)        │
  │ init.lua:40     timeout_ms=300 ││  end                   │
  │ util.lua:8      -- timeout doc ││                        │
  ╰────────────────────────────────╯╰────────────────────────╯
```

Results update as you type. `<CR>` jumps to the match, `<Esc>` cancels.

### Find text in open buffers only
- `<lead>sB` - grep across buffers you already have open

Narrower than a project grep - useful when you know it's in a file you're
already working in.

### Find files by name
- `<lead><lead>` or `<lead>ff` - find files from the project root
- `<lead>fF` - find files from the current working directory
- `<lead>fg` - only git-tracked files
- `<lead>fc` - jump straight to a Neovim config file
- `<lead>fn` - create a new file

Fuzzy: typing `cfglua` will match `config/keymaps.lua`.

Default: show hidden and git-ignored files without `<M-h>` / `<M-i>` -
`picker = { sources = { files = { hidden = true, ignored = true } } }` in
the `opts` of `lua/plugins/snacks.lua` - true/false (now both `false`).

### Find recently used files
- `<lead>fr` - recent files (project root)
- `<lead>fR` - recent files (cwd)
- `<lead>fp` - switch between projects · in it, each key first makes the
  project this tab's working directory: `<C-f>` find files · `<C-g>` grep
  · `<C-r>` recent files · `<C-e>` explorer · `<C-w>` just switch ·
  `<C-t>` a new tab for another project

### Find help, keymaps and commands
- `<lead>sh` - search Neovim's `:help` pages
- `<lead>sk` - search every keymap currently bound · in it, `<M-g>` /
  `<M-b>` hide or show global / this buffer's keymaps
- `<lead>sC` - search available commands
- `<lead>sa` - search autocommands
- `<lead>sM` - man pages
- `<lead>sp` - plugin specs

`<lead>sk` is the fastest way to answer "what was that key again?" - it
lists the live keymap table, including everything custom in this setup.

### Find TODO / FIXME comments
- `<lead>st` - all todo-style comments **[custom]**
- `<lead>sT` - only `TODO` / `FIX` / `FIXME` **[custom]**
- `]t` / `[t` - next / previous todo comment in this file

What you see:

```text
  // TODO: handle the empty case
     ▔▔▔▔  highlighted in a distinct colour, inline

  // FIXME: off-by-one here
     ▔▔▔▔▔
```

Stock LazyVim points these at a Telescope command, which errors here -
this setup uses the Snacks picker and has no Telescope installed. Rerouted
to a Snacks grep pre-filled with the todo keywords.

### TODO comments in a list
- `:TodoQuickFix` / `:TodoLocList` - all TODO / FIX / NOTE comments in the
  quickfix / location list (`:TodoQuickFix keywords=TODO,FIX` to narrow)

The `:TodoTelescope`, `:TodoFzfLua` and `:TodoTrouble` variants exist, but
need plugins that aren't installed here.

### Find history (searches, commands, notifications)
- `<lead>s/` - previous searches
- `<lead>sc` or `<lead>:` - command history
- `<lead>n` - notification history
- `<lead>snh` - message history (noice)
- `<lead>snl` - show the last message again

Useful when a message flashed past before you could read it.

### Find marks, jumps, registers
- `<lead>sm` - list marks (`<C-x>` deletes the highlighted one)
- `<lead>sj` - list the jump list
- `<lead>s"` - list register contents
- `<lead>su` - browse the undo tree

### Clear search highlighting
- `<Esc>` - clear the highlight from the last search
- `<lead>ur` - redraw, clear highlight, refresh diff
- `:noh` - the same, as a command

Default: `vim.opt.hlsearch = false` in `lua/config/options.lua` - true/false; `false`
never highlights matches at all (now `true`).

### Search tricks
- `?pattern` - search **backward** (`n` / `N` follow that direction)
- `/` then `<CR>` - repeat the last search · `:s//new/` reuses it too
- `?` then `<CR>` - repeat the last search, backward
- `g*` / `g#` - like `*` / `#`, but also match inside longer words
- `/foo/e` - land on the **end** of the match · `/foo/e+1` one past it
- `/foo/+2` - two lines below the match · `/foo/s-1` one before its start
- `<C-g>` / `<C-t>` - while typing a search: jump to the next / previous
  match before pressing `<CR>`
- `q/` / `q?` - search history in an editable window

### Keys inside any picker
Files, grep, buffers, help - every picker shares these. `?` shows them all.
`<lead>sR` reopens the last picker with its search intact.

- `<CR>` - open · `<C-s>` / `<C-v>` / `<C-t>` - in a split / vsplit / tab
  (`<C-t>` is a custom version here - see "What a tab is here")
- `<Tab>` / `<S-Tab>` - mark several items · `<C-a>` - mark all
- `<C-q>` - send the marked (or all) results to the quickfix list
- `<C-j>` / `<C-k>` (or `<C-n>` / `<C-p>`) - move · `<C-d>` / `<C-u>` - by pages
- `<C-f>` / `<C-b>` - scroll the preview
- `<M-h>` - show hidden files · `<M-i>` - show git-ignored files
- `<M-r>` - regex on/off (grep) · `<C-g>` - live grep on/off
- `<M-p>` - preview on/off · `<M-m>` - maximise · `<M-w>` - cycle focus
- `<M-f>` - follow symlinks · `<M-d>` - debug-inspect the item
- `<C-w>H` / `J` / `K` / `L` - move the whole picker left / bottom / top / right
- `<C-Up>` / `<C-Down>` - earlier / later searches
- `<C-r><C-w>` / `<C-r><C-a>` / `<C-r><C-l>` - type in the word / WORD /
  line from under the cursor · `<C-r><C-f>` / `<C-r><C-p>` - the file path
- `/` - jump between the search box and the list · `<Esc>` / `q` - close
- `<C-r>#` - type in the previous file's name · double-click - open

`<M-…>` means Alt. In the list (after `<Esc>` or `/`), `j` / `k`, `gg` / `G`
and `zt` / `zz` / `zb` work too; `i` goes back to typing.

## Replace

### Replace inside the current file
- `:%s/old/new/g` - every occurrence in the file
- `:s/old/new/g` - only on the current line
- `:68,78s/old/new/g` - only between lines 68 and 78
- `:-5,+5s/old/new/g` - 5 lines above to 5 lines below cursor
- `:%s/old/new/gc` - ask before each replacement
- `:s#old/path#new/path#g` - use `#` (or `;`) as delimiter to avoid escaping `/`

What you see:

```text
  before:                      after :%s/timeout/delay/g
    local timeout = 30           local delay = 30
    if timeout > 0 then          if delay > 0 then
    run(timeout)                 run(delay)

                                 3 substitutions on 3 lines
```

`%` = whole file, `g` = every match per line (without it, only the first
on each line), `c` = confirm. Any single-byte delimiter (like `#`, `;`, `@`) can
replace `/` to make changing URLs or file paths clean without `\/` escaping.

### Replace with confirmation
- `:%s/old/new/gc`

What you see:

```text
  replace with new (y/n/a/q/l/^E/^Y)?

    y  replace this one        n  skip it
    a  replace all remaining   q  stop here
    l  replace this one then stop
```

### Replace only within a selection
Select lines with `V`, then type `:s/old/new/g`.

What you see:

```text
  :'<,'>s/old/new/g
   ▔▔▔▔▔
   Vim fills this range in for you - it means "the selection"
```

### Replace the word under the cursor
- `*` to search it, then `:%s//new/g`

Leaving the pattern empty reuses your last search, so you never retype it.

### Replace across the whole project
- `<lead>sr` - grug-far: search & replace across many files, with preview

What you see:

```text
  ╭─ grug-far ────────────────────────────────────╮
  │ Search:   timeout                             │
  │ Replace:  delay                               │
  │ Files:    *.lua                               │
  ├───────────────────────────────────────────────┤
  │ config.lua:12                                 │
  │ -   local timeout = 60                        │
  │ +   local delay = 60                          │
  │                                               │
  │ init.lua:40                                   │
  │ -   timeout_ms = 300                          │
  │ +   delay_ms = 300                            │
  ╰───────────────────────────────────────────────╯
```

Every match is listed with the exact before/after **before** anything is
written. Edit the Search/Replace/Files fields in place and the list updates.
The key to actually apply is shown in the buffer's own header.

### Keys inside grug-far
`\` is the local leader here, so `\r` means backslash then `r`.

- `\r` - replace everywhere · `\s` - write the edited results back to the
  files · `\l` - just this line
- `\j` / `\k` - apply the next / previous match only
- `<CR>` - go to the match · `\o` - open it but stay here · `\i` - preview
- `<CR>` in the history window (`\t`) - reuse that search
- `\q` - send results to the quickfix list
- `\e` - switch search engine (ripgrep / ast-grep)
- `\x` - switch the replacement to a Lua or Vimscript expression
- `\t` / `\a` - history: open / add · `\f` - refresh · `\b` - abort
- `\c` - close · `g?` - help
- `:GrugFarWithin` - search only inside the visual selection
- `\n` / `\p` - write back just the next / previous match · `\v` - just
  this file
- `\w` - show the ripgrep command being run
- `:GrugFar` - open it (same as `<lead>sr`)

### Replace across files without a plugin
- `:grep <pattern>` - fill the quickfix list (uses ripgrep)
- `:cfdo s/old/new/g | update` - substitute in every listed file and save

Faster to type than grug-far, but runs blind with no preview. Still undoable
per file with `u`, and nothing is written until `update` runs.

## Saving & quitting

### Save
- `:w` - save · `<C-s>` - save, from any mode
- `:w {file}` - write a copy under another name (you keep editing this one)
- `:sav {file}` - "save as": from now on you're editing the new file
- `:up` - save only if something changed
- `:wa` - save every changed buffer
- `:w !{cmd}` - feed the buffer to a shell command, e.g. `:w !wc -w`

### Quit
- `:q` - close the window (refuses if that would lose unsaved changes)
- `:q!` or `ZQ` - close, throwing changes away
- `:wq`, `:x` or `ZZ` - save and close (`:x`/`ZZ` only write if changed)
- `:qa` - quit everything · `:qa!` - quit, discarding everything
- `:wqa` / `:xa` - save everything and quit
- `<C-z>` - suspend Neovim to the shell; type `fg` there to come back

### Reload, revert and file info
- `:e` - reload the file if it changed on disk
- `:e!` - throw away all unsaved changes and reload
- `:checktime` - check every buffer for outside changes (runs automatically
  when Neovim regains focus)
- `<C-g>` - file name, line count and position
- `g<C-g>` - word, character and byte counts (of the selection in visual)
- `:f {name}` - rename the buffer (the file on disk is untouched)
- `:pwd` / `:cd {dir}` - show / change the working directory ·
  `:lcd {dir}` - for this window only (long names `:chdir` / `:lchdir`;
  `:tcd` / `:tchdir` for a tab)

## Buffers

### What a buffer is
A file loaded into memory. Not a window (a viewport onto a buffer) and not a
tab (a whole layout of windows). One buffer can be shown in several windows,
and closing a window doesn't close the buffer.

### Open a file
- `:e {path}` - open a file into a new buffer
- `:enew` - blank new buffer
- `<lead><lead>` - find a file by name and open it

### Switch between buffers
With more than one tab page, everything here except `<lead>fB` covers
only the **current tab page's** buffers (scope.nvim **[custom]** - see
"What a tab is here").

- `H` / `L` - previous / next buffer
- `[b` / `]b` - same thing
- `<lead>bb` - jump back to the buffer you were just in
- `<lead>` then a backtick - same thing, one key shorter
- in the buffer list, `<C-x>` (or `dd` after `<Esc>`) closes the
  highlighted buffer
- `<lead>,` or `<lead>fb` - fuzzy-pick from this tab page's buffers ·
  `<lead>fB` - every buffer in every tab page, plus hidden ones. Picking
  one opens it **here**, in the current tab page - it doesn't jump to
  the tab page it came from
- `<lead>bj` - pick a buffer by an on-screen letter label

What you see (the bufferline across the top):

```text
  ▎ init.lua  │  cheatsheet.md ●  │  keymaps.lua       
    ▔▔▔▔▔▔▔▔                ▲
    current                 ● = unsaved changes

  H ← move left        move right → L
```

### Close buffers
- `<lead>bd` - close this buffer, keep the window open
- `<lead>bD` - close this buffer and its window
- `<lead>bo` - close every buffer except this one
- `<lead>bl` / `<lead>br` - close all buffers left / right of this one
- `<lead>bP` - close all buffers that aren't pinned
- `<lead>bi` - close buffers not visible in any window

`<lead>bd` is the one you want day-to-day: it won't collapse your split
layout the way `:bdelete` does.

### Pin and reorder buffers
- `<lead>bp` - pin this buffer (protects it from `<lead>bP`)
- `[B` / `]B` - move this buffer left / right in the bufferline

### List buffers
- `:ls` or `:buffers` - plain list with numbers (this tab page's buffers)
- `:ls!` - every buffer, including other tab pages' and hidden ones
- `:b {number}` or `:b {name}` - switch directly

### More buffer commands
- `<C-^>` (or `:e #`) - flip to the previous buffer
- `:bn` / `:bp` - next / previous · `:bf` / `:bl` - first / last
- `:bm` - next buffer with unsaved changes
- `:bd` - delete the buffer (closes its windows too) · `:bw` - wipe it
  completely
- `:bufdo {cmd}` - run a command in every buffer, e.g.
  `:bufdo %s/old/new/ge | update`
- `:ball` - open every buffer in its own window
- `:badd {file}` - add a file to the list without opening it
- `:ls!` - include hidden/unlisted buffers
- `:files` - another name for `:ls`
- `:bun` - unload a buffer but keep it listed · `:hid` - hide this window's
  buffer (keeps its changes) · `:unh` - a window for every loaded buffer
- `:sb {n}` / `:sbn` / `:sbp` - split and show buffer n / the next / the
  previous
- `:drop {file}` - edit a file, reusing a window that already shows it
- `:vie {file}` / `:sv {file}` - open read-only (here / in a split)
- `:nos e {file}` - open without a swap file
- `:fin {name}` - find a file along `path` and open it (`:sf` in a split,
  `:tabf` in a tab) · `:checkp` - list `#include`s that can't be found

Default for where `:find` looks: `vim.opt.path:append("**")` in
`lua/config/options.lua` - a comma-separated list; `**` searches every
subfolder (now `".,,"`: this file's folder and the working directory).

### Bufferline commands
Tab-complete `:BufferLine` to see them all. The useful ones:

- `:BufferLinePick` - label every tab with a letter; type one to switch
- `:BufferLinePickClose` - same, but closes the one you pick
- `:BufferLineSortByDirectory` / `:BufferLineSortByExtension` /
  `:BufferLineSortByRelativeDirectory` / `:BufferLineSortByTabs` - reorder
  the tabs
- `:BufferLineGoToBuffer {n}` - the nth tab from the left
- `:BufferLineCloseOthers` / `:BufferLineCloseLeft` /
  `:BufferLineCloseRight` - close in bulk
- `:BufferLineCycleNext` / `:BufferLineCyclePrev` - what `L` / `H` run
- `:BufferLineMoveNext` / `:BufferLineMovePrev` - what `]B` / `[B` run
- `:BufferLineGroupToggle {name}` / `:BufferLineGroupClose {name}` -
  collapse / close a group of tabs (no groups are set up here)
- `:BufferLineTogglePin` - same as `<lead>bp`
- `:BufferLineTabRename {name}` - label the current tab page

## Windows & Splits

### Split the window
- `<lead>-` - split below (horizontal)
- `<lead>|` - split right (vertical)
- `:sp {file}` / `:vsp {file}` - split and open a specific file

What you see:

```text
      <lead>|                       <lead>-
  ╭────────┬────────╮           ╭─────────────────╮
  │        │        │           │                 │
  │   A    │   B    │           │        A        │
  │        │        │           ├─────────────────┤
  │        │        │           │        B        │
  ╰────────┴────────╯           ╰─────────────────╯
   <C-h>  ←→  <C-l>              <C-k> ↑↓ <C-j>
```

Defaults, in `lua/config/options.lua`:
- `vim.opt.splitbelow = true` / `vim.opt.splitright = true` - true/false:
  new splits open below / to the right (now both `true`)

### Move between splits
- `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` - focus left / down / up / right
- `<C-w>` then `<lead>` - window "hydra" mode: repeatable window commands

### Resize splits
- `<C-Left>` / `<C-Right>` - narrower / wider
- `<C-Up>` / `<C-Down>` - taller / shorter

### Close or zoom a split
- `<lead>wd` - close this window (the buffer stays open)
- `<lead>wm` - zoom this split to fill the screen; press again to restore

Zoom is handy for briefly reading a file in a cramped 3-way split.

### Vim's own window keys (`<C-w>`)
`<C-w>` then one key. A count before `<C-w>` works for most, and
`:wincmd {key}` does the same from the command line.

- `<C-w>s` / `<C-w>v` - split this window horizontally / vertically
- `<C-w>n` - new empty window · `:new` / `:vnew` - same, below / beside
- `<C-w>h` `j` `k` `l` - move focus (what `<C-h>` … `<C-l>` do)
- `<C-w>w` / `<C-w>W` - next / previous window · `<C-w>p` - the last one
- `<C-w>t` / `<C-w>b` - top-left / bottom-right window
- `<C-w>c` (or `:clo`) - close this window · `<C-w>q` - quit it like `:q`
- `<C-w>o` (or `:on`) - close every **other** window

### Resize and rearrange windows
- `<C-w>=` - make all windows the same size
- `<C-w>+` / `<C-w>-` - taller / shorter (`10<C-w>+` = 10 lines)
- `<C-w>>` / `<C-w><` - wider / narrower
- `<C-w>_` / `<C-w>|` - maximise height / width (`{n}<C-w>_` sets exactly n)
- `:res {n}` / `:vert res {n}` - set the height / width
- `<C-w>H` `J` `K` `L` - move this window to the far left / bottom / top / right
- `<C-w>r` / `<C-w>R` - rotate the windows · `<C-w>x` - swap with the next
- `<C-w>T` - move this window into its own tab

### Open things in a split
- `<C-w>f` - split and open the file path under the cursor
- `<C-w>gf` - open it in a new tab instead
- `<C-w>F` / `<C-w>gF` - the same, also going to the line number after
  the name
- `<C-w>P` - jump into the preview window
- `<C-w>^` - split and open the previous buffer
- `<C-w>]` - split and jump to the definition under the cursor
- `<C-w>}` - show it in a preview window · `<C-w>z` (or `:pc`) closes that
- `:vert {cmd}` - make a split vertical, e.g. `:vert help` ·
  `:bo {cmd}` / `:to {cmd}` - put it at the very bottom / top
- `:windo {cmd}` - run a command in every window of this tab
- `:abo {cmd}` / `:bel {cmd}` - open the split above-left / below-right of
  this one (`:lefta` / `:rightb` are the same)
- `:hor {cmd}` - force a split to be horizontal
- `<C-w>i` - split and jump to where the word under the cursor is declared
  (searching `#include`s)
- `<C-w>g]` / `<C-w>g}` - split and pick a tag / preview-pick it
- `:fc` - close the top floating window · `:fc!` - close every float
- `:helpc` - close the help window
- `:redr` - redraw the screen · `:redraws` - just the status lines

## Tabs

### What a tab is here (the numbers at the top right)
A saved layout of windows, not a single file. Day-to-day switching is
buffers (`H`/`L`); tabs are for keeping separate workspaces.

What you see:

```text
   main.cpp   util.h   notes.md                           1  2
  └──── buffers: your open files ────┘          tab pages ┘  └ highlighted
        H / L to switch                          = the one you're on
```

The left part is **buffers** drawn as tabs (bufferline). The numbers on
the right are real Vim **tab pages** - they only appear once there are
two or more, so seeing them means one got opened (`<lead><Tab><Tab>`,
`:tabnew`, `<C-w>T`, ...).

- `gt` / `gT` - next / previous tab page · `2gt` - go to tab 2
- `<lead><Tab>d` - close the current tab page (its files stay open as
  buffers) · `<lead><Tab>o` - keep only this one; the numbers disappear

Each tab page has its **own buffers** here **[custom]** (scope.nvim):
the bar, `H` / `L` and the buffer picker (`<lead>,`) show only the files
opened in the current tab page. A file opened in two tab pages is listed
in both.

- `:ScopeMoveBuf {n}` - move the current buffer to tab page `n`
- `:setlocal nobuflisted`, then switch away (`H` / `L`) - drop the current
  file from **this** tab page's list only (`<lead>bd` closes it everywhere)
- `<lead>bd` - close a buffer; it leaves this tab page's list
- closing a tab page drops its list (the files stay loaded)
- sessions keep the per-tab lists (`<lead>qs` restores them)

`:tabe {file}` or `<C-t>` in a picker opens a file in a new tab page
directly. `<lead><Tab><Tab>` starts it with an empty `[No Name]` buffer,
which a newly opened file then replaces.

Opening in a new tab page from a picker (`<C-t>`) or the explorer (`t`)
uses a custom action **[custom]** that creates the tab page first
(`:tabedit`). Snacks' own version loaded the file in the *old* tab page
first, so with per-tab lists it showed up in both. Grep results still
land on the matching line.

Default: stock Vim / LazyVim - buffers are global, so every tab page's
bar lists **every** buffer, and a new tab page's `[No Name]` shows up in
all of them. Undo: delete `lua/plugins/scope.lua` (now: per-tab).

Default: stock LazyVim, unchanged - bufferline in `buffers` mode, tab
numbers shown when there are 2+ tab pages, the bar hidden while only one
file is open. `<lead>uA` toggles the whole bar.

### Create, close, switch tabs
- `<lead><Tab><Tab>` - new, empty tab
- `:tabe {file}` - open a file in a new tab
- `<C-t>` in a file picker (`<lead><space>`, `<lead>/`, ...) - open the
  selected result in a new tab (in the file explorer it's `t` instead -
  `<C-t>` there opens a terminal)
- `<C-w>T` - move the current window out into its own tab
- `:tab {cmd}` - run a command in a new tab: `:tab help gt`, `:tab split`
  (same file, new tab), `:tab term`
- `<lead><Tab>]` / `<lead><Tab>[` - next / previous
- `<lead><Tab>f` / `<lead><Tab>l` - first / last
- `<lead><Tab>d` - close this tab
- `<lead><Tab>o` - close all other tabs
- Native: `:tabnew`, `gt` / `gT`, `:tabclose`

Not to be confused with **kitty's** tabs (the terminal's own, one level
up): Ctrl+Shift+T new · Ctrl+Shift+W close · Ctrl+Tab / Ctrl+Shift+Tab
switch. They're kept off bare Ctrl+T / Ctrl+W on purpose - kitty would
grab those before Neovim, killing `<C-t>` (picker: open in a new tab
page) and every `<C-w>` window command.

### More tab commands
- `{n}gt` - go to tab n · `g<Tab>` - the last tab you were in
- `:tabm {n}` - move this tab (`:tabm 0` first, `:tabm` last, `:tabm +1`)
- `:tabo` - close all other tabs · `:tabs` - list tabs and their windows
- `:tab {cmd}` - open a command's window as a tab, e.g. `:tab help`,
  `:tab split`
- `:tabdo {cmd}` - run a command in every tab
- `:tabe {file}` - open a file in a new tab
- `:tabn` / `:tabp` - next / previous · `:tabfir` / `:tabl` - first / last
- `:tcd {dir}` - a working directory just for this tab

## Moving around

### Basic motions
- `h` `j` `k` `l` - left, down, up, right
- `w` / `b` - start of next / previous word; `e` - end of word
- `W` / `B` / `E` - same but whitespace-separated (ignores punctuation)
- `{` / `}` - previous / next paragraph
- `%` - jump to the matching bracket

What you see:

```text
  local result = compute(a, b)
  █                                start

  w    → local │result = compute(a, b)      next word start
  W    → local result │= compute(a, b)      punctuation ignored
  $    → end of line
  %    → with cursor on "(" jumps to the matching ")"
```

### Jump to a line or file position
- `gg` / `G` - top / bottom of file
- `{n}G` or `:{n}` - go to line n
- two backticks in a row - jump back to where you just were

### Jump anywhere on screen - Flash (s / S)
- `s` then 2 characters - labels appear on matches; press one to jump
- `S` - same, but jumps between code structures (treesitter)

What you see:

```text
  press  s  then type  re

    local result = compute(rate, offset)
          ▔▔a                   ▔▔s
    return result
    ▔▔d       ▔▔f

  now press a / s / d / f to jump straight to that spot
```

This is LazyVim's default. It takes over Vim's own `s` / `S` - use `cl`
(change one character) and `cc` (change the whole line) instead, which do
exactly the same, counts included.

Because Flash owns `s` / `S`, surround lives on `gs` (`gsa`, `gsd`, `gsr` -
see Surround) instead of mini.surround's own `sa` / `sd` / `sr`.

Flash could move onto `f` instead, but that loses find-a-character: Flash
already upgrades `f` / `F` / `t` / `T` (see "Find text in the current
line"), and edits like `df,` / `ct)` depend on them.

### Scroll the view
- `<C-d>` / `<C-u>` - half page down / up
- `<C-f>` / `<C-b>` - full page forward / backward
- `zz` / `zt` / `zb` - center / top / bottom the cursor line on screen

`zz` is the one worth building a habit around - it re-centres the line
you're working on without moving the cursor.

Default: `vim.opt.scrolloff = 4` in `lua/config/options.lua` - a number: lines kept visible
above and below the cursor (now `4`). Smooth scrolling: see UI toggles.

### Jump list (go back and forward)
- `<C-o>` - go back to where you were
- `<C-i>` - go forward again
- `<lead>sj` - browse the whole jump list

Works across files, so it's the "back button" after a go-to-definition.

### Marks
- `m{a-z}` - set a mark at the cursor
- a backtick then `{a-z}` - jump to that mark
- `<lead>sm` - list all marks · in that list, `<C-x>` deletes the
  highlighted one
- `dm{a-z}` - delete a mark (`dmi` removes mark i) · `dm-` - delete every
  lowercase mark in this file **[custom]**
- `:delm {a-z}` - the built-in way to delete one

A mark shows as its letter just left of the line number, so a stray
letter there means you pressed `m` and then that letter.

```text
  ma        set mark "a" here
  ...move around, other files...
  `a        jump straight back
```

### More word and line motions
- `ge` / `gE` - back to the end of the previous word / WORD
- `g_` - last non-blank character of the line
- `+` / `-` - first non-blank of the next / previous line (`<CR>` = `+`)
- `_` - first non-blank of this line (`3_` goes two lines down)
- `(` / `)` - previous / next sentence
- `{n}|` - column n, e.g. `20|`
- `M` - middle line of the screen

Vim's `H` / `L` (top / bottom of the screen) are buffer switching here;
`:norm! H` still reaches the stock behaviour if you ever need it.

### Jump around inside code
- `[(` / `])` - back / forward to the `(` or `)` enclosing the cursor
- `[{` / `]}` - to the start / end of the enclosing `{ }` block
- `[m` / `]m` - start / end of a method (class bodies in C++/Java)
- `[/` / `]/` - start / end of a `/* */` comment
- `[#` / `]#` - the enclosing `#if` / `#else` / `#endif`
- `[[` / `]]` - in code with a language server: previous / next
  **reference** to the symbol under the cursor. Elsewhere: previous / next
  section (a `{` in column 0)
- `[]` / `][` - previous / next end of a section (a `}` in column 0)

### Scroll a line at a time
- `<C-e>` / `<C-y>` - scroll the view down / up one line; the cursor stays put
- `z<CR>` / `z.` / `z-` - like `zt` / `zz` / `zb`, but also put the cursor on
  the first non-blank
- `z+` - the next page: the line below the window moves to the top ·
  `z^` - the previous page: the line above moves to the bottom

### Change list: where you edited
- `g;` / `g,` - back / forward through the places you **changed** text
- `:changes` - list them

The jump list (`<C-o>`) remembers where you jumped; this one only where you
typed. `g;` right after an interruption takes you back to your last edit.

### More marks
- `m{A-Z}` - a **file** mark: capital letters work across files, and
  jumping to one opens its file
- `'{a-z}` - jump to the mark's line; a backtick instead of `'` goes to the
  exact column
- `''` - back to the line you were on before the last jump
- `'.` - where you last changed text · `'^` - where you last left insert
  (`gi` jumps there and starts inserting)
- `'[` / `']` - start / end of the text you last changed or yanked
- `'<` / `'>` - start / end of the last visual selection
- `'(` / `')` - start / end of the sentence · `'{` / `'}` - of the paragraph
- `:ma {a-z}` - set a mark from the command line (`:5ma a`) ·
  `:cle` - clear the jump list
- `['` / `]'` - previous / next lowercase mark (`[` or `]` then a backtick:
  the same, to the exact column)
- `:marks` - list them · `:delm a` - delete mark a · `:delm!` - delete all
  lowercase marks
- `g'{mark}` - jump without adding to the jump list

### Open the file under the cursor
- `gf` - open the file whose path is under the cursor
- `gF` - same, and go to the line number after it (`main.cpp:42`)
- `<C-w>f` / `<C-w>gf` - in a split / a new tab
- `gx` - open a URL or path with the system's default app instead

## Editing

### Enter insert mode
- `i` / `a` - insert before / after the cursor
- `I` / `A` - insert at first non-blank / end of line
- `o` / `O` - open a new line below / above
- `<Esc>` - back to normal mode

### Delete, change, yank
- `d{motion}` - delete (`dw` word, `dd` line, `d$` to end of line)
- `c{motion}` - change: delete then insert (`cw`, `cc`, `C`)
- `y{motion}` - yank/copy (`yw`, `yy`, `Y`)
- `p` / `P` - paste after / before the cursor
- `x` - delete the character under the cursor **[custom: keeps your yank]**

### cw vs ciw
The single most common confusion in Vim.

```text
  before:   hel█lo world          █ = cursor

  cw   →    hel█ world            only "lo" went (cursor → word END)
  ciw  →    █ world               the whole word "hello" went
```

`cw` is really `ce` - it changes from the cursor to the end of the word,
ignoring anything before it. `ciw` ("change inner word") always takes the
whole word no matter where in it you are. `ciw` is almost always what you
actually want.

### Undo and redo
- `u` - undo
- `<C-r>` - redo
- `<lead>su` - browse the full undo tree · in it, `<C-y>` copies the lines
  that change added, `<C-S-y>` the lines it removed

The undo tree matters because Vim never throws branches away: undo, type
something else, and the old branch is still reachable through `<lead>su`.

### Repeat and small operators
- `.` - repeat the last change
- `J` - join this line with the one below
- `~` - toggle the case of a character
- `<C-a>` / `<C-x>` - increment / decrement a number - see "Increase or
  decrease numbers"

`.` is the highest-leverage key in Vim: `ciwnew<Esc>` then `n.` `n.` `n.`
replaces word after word.

### Increase or decrease numbers (increment / decrement)
- `<C-a>` / `<C-x>` - add / subtract 1: the number under the cursor, or
  the next one to its right on the line
- `10<C-a>` / `5<C-x>` - a count adds / subtracts that much
- `.` - repeat on the next number (`w.` or `n.`)
- visual `<C-a>` / `<C-x>` - change every number in the selection
- visual `g<C-a>` / `g<C-x>` - turn a column into a sequence counting up
  / down; `2g<C-a>` steps by 2

What you see:

```text
  port = 8080   <C-a>       →  port = 8081    cursor anywhere before it
  port = 8080   10<C-x>     →  port = 8070
  x = -3        5<C-a>      →  x = 2          the minus sign counts
  0x0f          <C-a>       →  0x10           hex stays hex
  0b101         <C-a>       →  0b110          binary too
  007           <C-a>       →  008            (Vim here: 010 - see below)
  1  1  1       V  <C-a>    →  2  2  2        (lines, selected with V)
  0  0  0       V  g<C-a>   →  1  2  3
  0  0  0       V  2g<C-a>  →  2  4  6
  0  0  0       V  g<C-x>   →  -1 -2 -3
```

Gotcha: a `-` touching the number is read as a minus sign, so `item-5`
with `<C-a>` gives `item-4`. Adding `blank` to `nrformats` fixes it:
then `-` is a minus sign only after a space, so `item-5` → `item-6` while
`x = -3` still works. (`unsigned` also fixes `item-5` but breaks real
negatives: `-3` + 5 → `-8`.)

Keys: nothing remapped - Vim's own, same in stock LazyVim. Plain Vim here
(`~/.vimrc`) also has `<lead>+` / `<lead>-` as aliases; Neovim doesn't,
since `<lead>-` is LazyVim's horizontal split.

Default: what counts as a number - `vim.opt.nrformats` in
`lua/config/options.lua` - any mix of `bin`, `hex`, `octal`, `alpha`
(single letters: `a` → `b`), `unsigned`, `blank` (now `bin,hex`, not set -
Neovim's default). Vim here has `bin,octal,hex`: a `~/.vimrc` stops Vim
loading `defaults.vim`, which is what normally drops `octal` - so `007`
counts in octal there (`007` → `010`).

Smarter version: LazyVim's `editor.dial` extra (off here - `:LazyExtras`)
takes over `<C-a>` / `<C-x>` / `g<C-a>` / `g<C-x>` to also cycle
`true`↔`false`, `&&`↔`||`, `and`↔`or`, `let`↔`const`, weekdays, months,
dates, hex colours, semver and markdown `[ ]`↔`[x]` / header levels.

### Indent and move lines
- `>>` / `<<` - indent / unindent the line
- Visual `>` / `<` - indent the selection (`gv` reselects it after)
- `<M-j>` / `<M-k>` - move the current line down / up
- `]<lead>` / `[<lead>` - add a blank line below / above, staying in normal mode

Indent width here is **4 spaces** (LazyVim's default is 2) **[custom]**.

Defaults - these lines are already in `lua/config/options.lua`, change the numbers:
- `vim.opt.shiftwidth = 4` / `vim.opt.tabstop = 4` - numbers (now `4`)
- `vim.opt.expandtab = true` - true/false: spaces instead of tabs (now
  `true`)
C/C++ formatting (`<lead>cf`) reads `IndentWidth: 4` in `~/.clang-format`
instead - change it there too.

### Replace mode and one-key edits
- `r{char}` - replace the character under the cursor (`3rx` = three x's)
- `R` - replace mode: typing overwrites; `<BS>` restores the old text
- `gR` - like `R`, but by screen width (tabs behave sensibly)
- `cl` - delete the character and insert · `cc` - clear the line (indent
  kept) and insert - Vim's `s` / `S`, which are Flash here
- `C` / `D` - change / delete to the end of the line
- `X` - delete the character **before** the cursor
- `<Insert>` in insert mode - switch between insert and replace

### Join, paste and case extras
- `gJ` - join lines **without** adding a space
- `gp` / `gP` - paste like `p` / `P`, leaving the cursor after the text
- `]p` / `[p` - paste after / before, re-indented to fit this line
- `g?{motion}` - ROT13 the text (`g??` for the line)
- `ga` - show the character's code (decimal, hex, octal) · `g8` - its
  UTF-8 bytes
- `g&` - repeat the last `:s` on **every** line
- `:retab` - turn tabs into spaces (using `tabstop` / `expandtab`)
- `g@{motion}` - run a custom operator (`operatorfunc`), for plugin authors

## Text objects

### Inside vs around
`i` = inside (contents only), `a` = around (contents plus delimiters).

```text
  foo("hello world")
        █

  di"  →  foo("")            inside the quotes
  da"  →  foo()              the quotes too
  ci(  →  foo(█)             inside parens, now inserting
```

Works with any operator: `d`, `c`, `y`, `v`.

### Common text objects
- `iw` / `aw` - word
- `i"`, `i'`, or i-then-backtick - quoted string
- `i(`/`ib`, `i[`, `i{`/`iB` - bracket contents
- `i<`, `i>` - angle bracket contents
- `ip` / `ap` - paragraph
- `it` / `at` - HTML/XML tag

The extra "smart" objects (`af` function, `ac` class, `au` call) came from
mini.ai, which is **disabled** in this setup.

### Around objects and sentences
- `a"` / `a'` / `a`+backtick - the string **with** its quotes (and the space
  after it)
- `ab` or `a(` - parentheses and contents · `aB` or `a{` - braces
- `a[` - square brackets · `a<` - angle brackets · `at` - a tag and its tags
- `is` / `as` - sentence (without / with the space after it)
- `iW` / `aW` - WORD (anything between spaces)
- A count reaches outward: `d2i(` empties the **second** enclosing `( )`

Quote objects work from anywhere on the line: with the cursor before a
string, `ci"` jumps into the next one.

## Surround

### Add quotes or brackets around text
- `gsa{motion}{char}` - wrap what the motion covers: `gsaiw"` wraps a word
- visual `gsa{char}` - wrap the selection
- `gsa_{char}` - wrap the whole line (from its first non-blank)
- `.` - repeat the last add somewhere else

What you see:

```text
  hello world    gsaiw"   →  "hello" world
  hello world    gsaiw)   →  (hello) world      closing half: tight
  hello world    gsaiw(   →  ( hello ) world    opening half: adds spaces
  x = 1 + 2      gsa$}    →  x = {1 + 2}        (cursor on the 1)
  hello          gsaiw*   →  *hello*            any other character works
  hello world    gsaiwf   →  asks "Function name", type print:
                             print(hello) world
  hello world    gsaiwt   →  asks "Tag name", type b:
                             <b>hello</b> world
```

`?` instead of a character asks for the left and right halves separately
(`<` then `>` gives `<hello>`). Same `)` vs `(` rule for `]`/`[` and
`}`/`{`.

These keys come from LazyVim's `coding.mini-surround` extra
**[custom]** - stock LazyVim has no surround. Other key sets and how to
change them: see "Surround keys: this setup vs defaults".

### Delete or change surrounding quotes and brackets
- `gsd{char}` - delete the pair around the cursor: `gsd"`
- `gsr{old}{new}` - replace one pair with another: `gsr"'`
- `b` = any bracket, `q` = any quote: `gsdb`, `gsrq"`
- `t` = an HTML/XML tag, `f` = a function call: `gsdt`, `gsdf`

What you see:

```text
  say "hi there" ok   gsd"   →  say hi there ok
  say "hi" ok         gsr"'  →  say 'hi' ok
  f(a)                gsr)]  →  f[a]
  f(a)                gsr({  →  f{ a }      opening half: adds spaces
  f( a )              gsd(   →  fa          opening half: drops them too
  f( a )              gsd)   →  f a         closing half: keeps them
  <b>hi</b>           gsdt   →  hi
  print(x)            gsdf   →  x
```

Works across lines: with the cursor anywhere inside a multi-line `( ... )`,
`gsd)` removes both halves.

### Surround the next or previous pair, find, highlight
The cursor normally has to be **inside** the pair. Add `n` (next) or `l`
(last = previous) after the key to reach one elsewhere:

- `gsdn"` / `gsdl"` - delete the next / previous `"..."` pair
- `gsrn)]` - replace the next `( )` with `[ ]`; the suffix also works with
  `gsf`, `gsF` and `gsh`
- `gsf{char}` / `gsF{char}` - move the cursor to the pair's next edge to
  the right / left
- `gsh{char}` - briefly highlight the pair around the cursor

```text
  x "a" y     cursor on x:   gsd"   →  nothing, not inside quotes
                             gsdn"  →  x a y
```

`gsn` shows up in which-key as "Update n_lines" but does nothing: LazyVim
still maps it, current mini.surround dropped that action.

Default: how many lines above/below to search - `opts = { n_lines = 20 }`
on the `nvim-mini/mini.surround` spec in a `lua/plugins/` file - a number
(now 20, not set). Highlight time for `gsh` is `highlight_duration`
(now 500 ms).

### Surround keys: this setup vs defaults
- `gsa` / `gsd` / `gsr` / `gsf` / `gsF` / `gsh` - **here**: LazyVim's keys
  for the `coding.mini-surround` extra **[custom]**
- `sa` / `sd` / `sr` / `sf` / `sF` / `sh` - mini.surround's own defaults;
  LazyVim moves them to `gs` because Flash owns `s`
- `ys{motion}` / `yss` / `ds` / `cs` / visual `S` - vim-surround's keys
  (the classic Vim plugin) - not used here
- stock Vim / Neovim: no surround at all. `gs` alone is Vim's "sleep one
  second" command, which this prefix takes over - nothing lost.

```text
  action        here           mini default   vim-surround
  add           gsa{m}{c}      sa{m}{c}       ys{m}{c}
  whole line    gsa_{c}        sa_{c}         yss{c}
  visual        gsa{c}         sa{c}          S{c}
  delete        gsd{c}         sd{c}          ds{c}
  replace       gsr{o}{n}      sr{o}{n}       cs{o}{n}
  find → / ←    gsf / gsF      sf / sF        -
  highlight     gsh            sh             -
```

vim-surround's keys were considered and left alone: `ys`/`ds`/`cs` would
lose "yank/delete/change up to a Flash jump" (`y`/`d`/`c` then `s`), and
visual `S` would have to choose between surround and Flash Treesitter.

Default: the keys - in a `lua/plugins/` file (now LazyVim's `gs` set,
nothing overridden; `""` disables one):

```lua
return {
  "nvim-mini/mini.surround",
  opts = {
    mappings = { add = "ys", delete = "ds", replace = "cs" },
  },
}
-- plus, for vim-surround's whole-line add:
-- vim.keymap.set("n", "yss", "ys_", { remap = true })
```

### Surround without the plugin
- `ciw"<C-r>""<Esc>` - wrap a word by hand: cut it, type `"`, paste it
  back (`<C-r>"`), type the closing `"`
- visual, then `c(<C-r>")<Esc>` - the same for a selection
- plain Vim (`~/.vimrc`) has no surround plugin, but its auto-pairs has
  **Fast Wrap**: type `(` right before a word, then `<M-e>` - gives
  `(word)`

Neovim's autopairs (mini.pairs) has no Fast Wrap - use `gsa` here.

## Registers & Clipboard

### How registers work
- `"{reg}y` - yank into a named register, e.g. `"ayy`
- `"{reg}p` - paste from it, e.g. `"ap`
- `<lead>s"` - browse all register contents

```text
  "0p     paste the last YANK    (survives deletes)
  ""p     paste the last DELETE
  "ayy    yank this line into register a
  "ap     paste register a back
```

Register `0` is the useful one: a normal delete overwrites the unnamed
register but never touches `"0`, so your last real copy is still there.

### Copy to the system clipboard
- `<lead>y` - yank selection/motion to the system clipboard **[custom]**
- `<lead>Y` - yank to end of line to the system clipboard **[custom]**

Locally you rarely need these: LazyVim sets `clipboard=unnamedplus`, so
**every** plain yank and delete (`y`, `yy`, `dd`, `cw` …) already lands in
the system clipboard - only `x` doesn't (see below). `<lead>y` is for
**SSH**, where that syncing is switched off: it sends the text through
OSC 52 to your **local** machine's clipboard, with no X or Wayland
forwarding.

Default: `vim.opt.clipboard = "unnamedplus"` in `lua/config/options.lua` - text in quotes;
`""` keeps plain yanks inside Neovim (now `"unnamedplus"`, or `""` over
SSH). A line in options.lua applies over SSH too.

### Delete without clobbering the clipboard
- `x` deletes into the black-hole register **[custom]**

```text
  yiw            copy the word "config"
  ...move...
  xxx            delete 3 characters
  p              stock Vim: pastes those deleted chars (copy lost)
                 here:      pastes "config"  ← still intact
```

### Every register
- `"a`–`"z` - named registers · `"A`–`"Z` **append** to them
- `"0` - last yank · `"1`–`"9` - last deletes of a line or more, newest first
- `"-` - last small (within-a-line) delete
- `".` - last inserted text · `":` - last command · `"/` - last search
- `"%` - current file name · `"#` - previous file name
- `"+` - system clipboard · `"*` - primary selection (middle-click)
- `"_` - black hole: delete without saving anything
- `"=` - expression: `"=6*7<CR>p` pastes 42
- `:reg` - list them all · `:reg a0` - just those

## Macros

### Record and replay
- `q{a-z}` - start recording into that register; `q` again to stop
- `@{a-z}` - replay
- `@@` - replay the last macro again
- `{n}@{a-z}` - replay n times

```text
  qa              start recording into register a
  I// <Esc>j      prefix the line with "// " and move down
  q               stop recording
  10@a            apply to the next 10 lines
```

Macros are just recorded keystrokes, so anything you can type you can
record - including `:` commands and searches.

### Edit, extend and reuse macros
- `qA` - record more onto the end of macro `a`
- `Q` - replay the last recorded macro
- `@:` - repeat the last `:` command (`@@` again after that)
- `:'<,'>norm @a` - run macro `a` on every selected line
- `"ap` - paste a macro as text, edit it, then `0"ay$` to store it back
- `:let @a = '...'` - write a macro directly

## Comments

### Toggle comments
- `gcc` - toggle the current line
- `gc{motion}` - toggle a motion (`gcap` = a paragraph); visual `gc`
- `<C-/>` (or `<C-_>`) - same as `gcc` / `gc`, VSCode-style **[custom]**

```text
  int x = 1;            →    // int x = 1;
  x = 1                 →    # x = 1          (python)
  <!-- markdown -->     →    correct per language, automatically
```

Comment syntax comes from Neovim itself (per-filetype `commentstring`), so
it's right in C, C++, Python, Markdown and so on with no extra config.

Stock LazyVim uses `<C-/>` to toggle a terminal; that moved aside - the
terminal is still on `<lead>ft`.

Default comment style for a language - add to `lua/config/autocmds.lua`
(text in quotes, `%s` is where the text goes; now `"// %s"` for C++):

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "cpp",
  callback = function()
    vim.bo.commentstring = "/* %s */"
  end,
})
```

### Add a comment line
- `gco` - add a comment on a new line below
- `gcO` - add one above

### Comment out many lines: matching a pattern, a range, a selection
- `:g/TODO/norm gcc` - comment every line containing `TODO`
- `:v/TODO/norm gcc` - comment every line **not** containing it
- `:5,20norm gcc` - lines 5 to 20 · visual `gc` - the selection
- `:g/TODO/norm I// ` - always **add** `// ` after the indentation
- `:g/TODO/s#^#// #` - add `// ` at column 0, before the indentation
- `:'<,'>s#^#// #` / `:'<,'>norm I// ` - same, on a visual selection
- `:%s#^\(\s*\)// #\1#` - remove `// ` from every line that starts with it

What you see:

```text
  int a = 1;                 :g/TODO/norm gcc       int a = 1;
    x = TODO();         →                     →       // x = TODO();
  int b = 2;                                        int b = 2;
      TODO;                                             // TODO;

  same lines,  :g/TODO/s#^#// #   →   //   x = TODO();   (column 0)
```

`gcc` picks the right comment style per language (`#` in Python), and
`:norm` runs it on each matched line. Use `:norm`, **not** `:norm!` - in
Neovim `gcc` is a built-in mapping, and `!` ignores mappings, so nothing
happens.

Gotcha: `gcc` **toggles**. A matching line that is already commented gets
uncommented - `// TODO a` turns into `TODO a`. When some matches may
already be comments, use `norm I// ` (always adds) instead.

`s#^#// #` uses `#` as the separator so the slashes need no escaping -
the same as `:g/TODO/s/^/\/\/ /`.

Keys: `gc` / `gcc` are Neovim's own (since 0.10), same as stock LazyVim;
the only custom one is `<C-/>`. Plain Vim (`~/.vimrc`) gets the same
`gc` / `gcc` from vim-commentary, so `:g/TODO/norm gcc` works there too.

## Autocomplete

### Using the completion menu
Autocomplete starts **off** in every session - `<lead>ac` turns it on, then
the menu appears by itself as you type. While it's off, Vim's built-in
completion still works on demand: `<C-n>` (see "Built-in completion").

What you see:

```text
  os.pa█
  ╭──────────────────────────────╮
  │ path              Module     │  ← selected
  │ pathsep           Variable   │
  │ pardir            Variable   │
  ╰──────────────────────────────╯
   <CR> or <C-y> accept · <C-n>/<C-p> move · <C-e> dismiss
```

Sources: LSP, snippets, file paths, and words from open buffers.

- `<CR>` / `<C-y>` - accept · `<C-e>` - close the menu
- `<C-n>` / `<C-p>` (or `<Up>` / `<Down>`) - move through the menu
- `<C-Space>` - open the menu by hand · `<C-b>` / `<C-f>` - scroll the docs
- `<Tab>` / `<S-Tab>` - jump between snippet placeholders (it does **not**
  accept a suggestion)

Default: `vim.g.blink_cmp_enabled = true` in `lua/config/keymaps.lua` -
true/false; `true` starts every session with autocomplete on (now
`false`).

### Turn autocomplete on or off
- `<lead>ac` - toggle the whole completion engine (starts **off** in every session) **[custom]**

Added because the menu gets in the way when writing prose or moving fast.
Shows an on/off notification and stays that way until you flip it back.

Default: `vim.g.blink_cmp_enabled = false` in `lua/config/keymaps.lua` -
true/false (now `false`).

### Inline "ghost text" is off
Stock LazyVim previews the top candidate as greyed-out text ahead of your
cursor (`ghost_text` follows `vim.g.ai_cmp`, on by default). Disabled here
**[custom]** - the dropdown still works normally.

```text
  stock:  os.pa|th          ← "th" shown ghosted ahead of the cursor
  here:   os.pa|            ← nothing until you pick from the menu
```

Default: `ghost_text = { enabled = false }` in `lua/plugins/completion.lua` -
true/false (now `false`).

## Autopairs

### How autopairs behaves
- Typing `(`, `[`, `{`, `"` or `'` inserts the closing half

```text
  type  (      →   (█)            cursor lands between
  type  "      →   "█"
  type  )  when the next char is already )  →  just steps over it
  foo█bar, type (  →  (  no auto-close: next char is a word character
```

Autopairs only acts as you type. To wrap text that already exists, use
`gsa` (see Surround): `gsaiw"` turns `word` into `"word"`.

### Turn it off
- `<lead>up` - toggle autopairs (a stock LazyVim toggle, not custom)

Default: `vim.g.minipairs_disable = true` in `lua/config/options.lua` - true/false; `true`
starts with autopairs off (now not set, so autopairs is on).

## Formatting

### Format the current file
- `<lead>cf` - format the whole buffer
- `<lead>cF` - format injected languages (e.g. code inside markdown)

```text
  before <lead>cf:            after:
    int main(){int x=1;         int main() {
    return x;}                      int x = 1;
                                    return x;
                                }
```

### Format on save
On by default. Toggles:
- `<lead>uf` - auto-format for this buffer
- `<lead>uF` - auto-format globally

Turn it off temporarily when touching a file whose existing style you don't
want to churn.

Default: `vim.g.autoformat = false` in `lua/config/options.lua` - true/false (now `true`).

### Which formatter runs
- C / C++ -> `clang-format` **[custom]** (already on the system via `clang`)
- Python -> `ruff format` **[custom]** (installed through Mason)
- Lua / fish / sh -> `stylua` / `fish_indent` / `shfmt` (LazyVim defaults)
- Markdown -> nothing, deliberately (prettier would pull in npm/Node)

Stock LazyVim configures **no** formatter for C, C++ or Python - those come
from language "extras" this setup skips - so `<lead>cf` silently did nothing
on those files until this was wired up.

### Formatter commands
- `:ConformInfo` - which formatters apply to this file, and whether they're
  installed
- `:LazyFormatInfo` - what `<lead>cf` and format-on-save will use here
- `:LazyFormat` - format now (same as `<lead>cf`)

## LSP (code intelligence)

### Go to things
- `gd` - go to definition (when the server supports it)
- `gD` - go to declaration
- `gr` - list references
- `gI` - go to implementation
- `gy` - go to type definition
- `gO` - document symbols
- `<C-o>` - jump back afterwards

### Hover documentation
- `K` - docs for the symbol under the cursor

What you see:

```text
  os.getcwd()
     █          press K

  ╭─────────────────────────────────────────╮
  │ getcwd() -> str                         │
  │                                         │
  │ Return a unicode string representing    │
  │ the current working directory.          │
  ╰─────────────────────────────────────────╯

  press K again to jump inside the popup · q closes it
```

### Function parameters (signature help)
- `<C-k>` - in insert mode, while typing a call: show the function's
  parameters, e.g. `max(const Tp &a, const Tp &b) -> const Tp &`
- `gK` - the same from normal mode, cursor inside the call's `( )`

It no longer pops up by itself when you type `(` or `,` - turned off in
`lua/plugins/noice.lua`. Ask for it when you need it.

Default: `auto_open = { enabled = false }` in `lua/plugins/noice.lua` -
true/false; `true` brings back the automatic popup (now `false`).

### Change code
- `<lead>ca` - code actions (quick fixes, refactors)
- `<lead>cA` - source-level actions
- `grn` - rename the symbol everywhere (Neovim native binding)
- `<lead>cl` - LSP info: which servers are attached here
- `<lead>cm` - open Mason to install/manage servers

`grn` renames across every reference the server knows about, not just this
file - safer than a find-and-replace for symbols.

### Symbols, references and calls
- `<lead>ss` - pick a symbol (function, class …) in this file ·
  `<lead>sS` - across the whole project
- `]]` / `[[` (or `<M-n>` / `<M-p>`) - next / previous reference to the
  symbol under the cursor; every reference is highlighted as you move
- `gai` / `gao` - incoming / outgoing calls: who calls this function, and
  what it calls
- `<lead>cr` - rename the symbol everywhere it's used
- `<C-]>` - also jumps to the definition: tag jumps are answered by the
  language server here, so no tags file is needed (`<C-t>` comes back)

### Language-server commands
- `:checkhealth vim.lsp` - which servers are attached, and their settings
- `:lsp restart` - restart them after they get confused · `:lsp stop` ·
  `:lsp enable {name}` / `:lsp disable {name}`
- `:LspInstall {server}` / `:LspUninstall {server}` - via Mason
- `:LspClangdShowSymbolInfo` - clangd's details for the symbol under the cursor
- `:LspClangdSwitchSourceHeader` - jump between `.cpp` and `.h` (`<lead>ch`)

### Neovim's built-in LSP keys
Neovim 0.11+ ships its own LSP bindings under `gr`, separate from LazyVim's.
Both sets are live here, so either works.

- `grn` - rename symbol
- `gra` - code action
- `grr` - list references
- `gri` - go to implementation
- `grt` - go to type definition
- `grx` - run codelens
- `gO` - document symbols
- `<C-w>d` (or `<C-w><C-d>`) - show the diagnostic under the cursor in a float

LazyVim's equivalents (`<lead>ca`, `gr`, `gI`, `gy`, `K`) are buffer-local
and only appear once a language server actually attaches.

### C and C++ language server (clangd)
`clangd` is set up **[custom]** and attaches automatically to `.c` / `.cpp`
files, so everything above works there: definitions, references, hover,
diagnostics and code actions.

- `<lead>ch` - switch between the source and its header **[custom]**
- `<lead>cl` - confirm clangd is attached to this buffer

It runs the system `clangd` (from the `clang` package, same one that gives
you `clang-format`) rather than a Mason-installed copy, with
`--clang-tidy` on, so you get clang-tidy lint warnings alongside compiler
errors.

**For accurate results in a real project**, clangd wants a
`compile_commands.json` so it knows your include paths and flags. CMake
emits one with `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`; symlink it into the
project root if it lands in a build directory. Without one, clangd falls
back to single-file analysis - still useful, but cross-file resolution and
includes will be weaker.

Python is covered separately by `ruff`, which also attaches automatically.

## Diagnostics

### Move between problems
- `]d` / `[d` - next / previous diagnostic
- `]e` / `[e` - errors only
- `]w` / `[w` - warnings only
- `]D` / `[D` - last / first in the file

What you see:

```text
   12   import os
   13   x = undefined_name
                          ■ undefined name `undefined_name`
        ▲
        a sign in the gutter marks the line, with the message inline
```

### See the details
- `<lead>cd` - diagnostic for the current line
- `<C-w>d` - diagnostic under the cursor, in a float
- `<lead>sd` - searchable list of all diagnostics
- `<lead>sD` - diagnostics for this buffer only
- `<lead>ud` - toggle diagnostics display on/off (starts **off** in every session)

Default: the line `vim.diagnostic.enable(false)` in `lua/config/options.lua` - change
`false` to `true`, or delete the line, to show them from the start (now
hidden).

## Git

### See changed lines in the gutter
Changed lines get a coloured bar in the left gutter as you type, before you
save anything.

```text
  ▎ 41   local timeout = 60      ▎ = changed / added
  ▎ 42   local retries = 3
        43   local host = "x"     (unchanged: no bar)
       delete marker sits between lines
```

- `<lead>gS` - git stash picker (`<CR>` applies the stash)
- `<lead>gs` - git status picker · in it, `<Tab>` stages / unstages the
  file and `<C-r>` restores it (throws its changes away)
- `<lead>gd` - diff of current hunks · `<Tab>` / `<C-r>` work here too
- `:lua Snacks.picker.git_branches()` - branches (no key bound):
  `<CR>` switch · `<C-a>` create · `<C-x>` delete
- `<lead>gD` - diff against origin
- `<lead>gl` / `<lead>gL` - git log (project / cwd)
- `<lead>gf` - history of just the current file

### Move between changed hunks
- `]h` / `[h` - next / previous changed hunk

### Stage or reset a hunk
- `<lead>ghs` - stage the hunk under the cursor
- `<lead>ghr` - reset (discard) that hunk
- `<lead>ghS` - stage the whole file
- `<lead>ghu` - undo the last stage
- `<lead>ghR` - reset the whole file

`<lead>ghs` on individual hunks is how you split one messy working tree
into several clean commits.

### Preview a hunk inline
- `<lead>ghp` - draws the diff into the buffer itself

What you see:

```text
   41   local timeout = 60
      - local timeout = 30          ← old version shown inline
   42   local retries = 3
```

Limits worth knowing: it **cannot wrap** long lines (Neovim's virtual-line
API only supports truncate or horizontal scroll, not wrapping), and it
disappears the moment the cursor moves. Wide or tall hunks are unreadable
this way - use the popup below instead.

### Preview a hunk in a popup
- `<lead>ghP` - floating popup, focused in one keypress **[custom]**

What you see:

```text
  ╭─ Hunk 1 of 3 ──────────────────────────────╮
  │ - local timeout = 30                       │
  │ + local timeout = 60                       │
  │   local retries = 3                        │
  ╰────────────────────────────────────────────╯

  j / k   scroll inside it
  q       close
```

The popup auto-widens to fit the longest line, and because this binding
calls the preview twice, your cursor lands **inside** the window - so `j`/`k`
scroll it instead of closing it. Stock LazyVim only binds the inline
version; this one is custom.

### Blame
- `<lead>ghb` - blame the current line (gitsigns)
- `<lead>gb` - blame line (Snacks)
- `<lead>ghB` - blame the whole file

```text
  ╭──────────────────────────────────────────────╮
  │ a1b2c3d  Jayavardhan  3 days ago             │
  │ Move the force-kill picker off SUPER+Escape  │
  ╰──────────────────────────────────────────────╯
```

Default: blame at the end of every line - `opts.current_line_blame = true`
inside the `opts = function(_, opts)` of `lua/plugins/gitsigns.lua` -
true/false (now `false`).

### GitHub
- `<lead>gi` / `<lead>gI` - open issues / all issues
- `<lead>gp` / `<lead>gP` - open pull requests / all
- `<lead>gB` - open the current file on GitHub in a browser
- `<lead>gY` - copy that link instead
- in the issue / PR lists: `<M-b>` open in the browser · `<C-y>` (or `y`
  in the list) copy its URL · in a PR's diff preview, `a` comments on the
  line and `<CR>` shows what else you can do

`<lead>gB` opens the exact line you're on, which makes it an easy way to
link a colleague to code.

### Gitsigns commands
`:Gitsigns` then `<Tab>` lists everything. Beyond the keys above:

- `:Gitsigns toggle_current_line_blame` - blame shown at the end of every line
- `:Gitsigns toggle_word_diff` - highlight exactly which words changed
- `:Gitsigns toggle_linehl` - tint whole changed lines
- `:Gitsigns diffthis` - side-by-side diff against the index
- `:Gitsigns setqflist` - every hunk in the quickfix list
- `:Gitsigns stage_buffer` / `reset_buffer` - the whole file at once

lazygit isn't installed, so LazyVim leaves out its full-screen git UI keys
(`<lead>gg` / `<lead>gG`). Install it (`sudo pacman -S lazygit`) and restart
Neovim to get them.

## Sessions

### Restore your layout
- `<lead>qs` - restore the session for this directory
- `<lead>ql` - restore the most recent session, any directory
- `<lead>qS` - pick from all saved sessions

Sessions store open buffers and window layout per project, saved
automatically when you quit. Reopen `nvim` in that directory and `<lead>qs`
puts the splits back exactly as they were.

### Skip saving
- `<lead>qd` - don't save this session on exit
- `<lead>qq` - quit everything

## Terminal

### Open a terminal
- `<lead>ft` - terminal at the project root
- `<lead>fT` - terminal at the current working directory

Opens as a floating window over the editor. `<C-/>` does this in stock
LazyVim, but that key is the comment toggle here **[custom]**.

### Vim's own terminal
- `:term` - a terminal in the current window · `:term {cmd}` - run a
  command in one
- `:vsp | term` / `:tab term` - in a vertical split / a new tab

`i` to type into it, `<C-\><C-n>` to get back to normal mode (see Terminal
mode).

## File explorer

### Browse files in a tree
- `<lead>e` - explorer from the project root
- `<lead>E` - explorer from the current working directory
- `<lead>fe` / `<lead>fE` - same pair, alternate keys

```text
  ╭─ Explorer ──────────────╮
  │  configs/               │
  │    neovim/              │
  │      cheatsheet.md      │
  │      lazyvim-migr.md    │
  │  ▸ cachyos/             │
  ╰─────────────────────────╯
```

Default: show hidden and ignored files without `H` / `I` - add
`explorer = { hidden = true, ignored = true }` next to `files` in the
`picker.sources` of `lua/plugins/snacks.lua` - true/false (now both
`false`).

### File operations in the explorer
With the cursor on a file or folder in `<lead>e`:

- `<CR>` or `l` - open the file / expand the folder · `h` - collapse
- `a` - add a file; end the name with `/` for a folder (`src/util/` makes
  both)
- `r` - rename · `d` - delete (asks first, then moves it to the trash)
- `c` - copy under a new name · `m` - move the marked files here (with
  nothing marked, it renames)
- `y` - copy the path(s) · `p` - paste files whose paths you copied
- `<Tab>` - mark several files first, then `d`, `c`, `m` or `y` act on all
- `o` - open with the system's default app · `u` - refresh the tree

### More explorer keys
- `[g` / `]g` - previous / next file with git changes
- `[d` / `]d`, `[e` / `]e`, `[w` / `]w` - files with diagnostics / errors /
  warnings
- `Z` - collapse every folder · `<BS>` - up to the parent folder
- `.` - make the folder under the cursor the explorer's root
- `<C-c>` - make it this tab's working directory · `<C-t>` - open a
  terminal there
- `t` - open the file in a new tab page (on a folder: expand / collapse)
  **[custom]** - stock Snacks has no explorer key for this; `<C-t>`, the
  pickers' new-tab key, is "terminal" in the explorer. Set in
  `lua/plugins/snacks.lua` (`picker.sources.explorer.win.list.keys`)
- `<lead>/` - grep inside that folder
- `H` / `I` / `P` - hidden files / ignored files / preview on-off

### Vim's built-in file browser
- `:Ex` / `:Sex` / `:Vex` / `:Tex` / `:Lex` - netrw: here / split / vsplit /
  tab / side drawer (full names `:Explore`, `:Sexplore`, `:Vexplore`,
  `:Texplore`, `:Lexplore`)
- `:e .` - opens the Snacks explorer here, which replaces netrw for
  directories
- `:Hexplore` - netrw in a split below · `:Nexplore` / `:Pexplore` - next /
  previous file in the listed directory · `:Ntree` - make a folder netrw's root
- `:Nread {url}` / `:Nwrite {url}` / `:Nsource {url}` - read / write / run
  a file over scp, ftp or http · `:NetUserPass` - set the login for it

## UI toggles

### Common toggles (`<lead>u` prefix)
- `<lead>uw` - wrap long lines
- `<lead>ul` - line numbers · `<lead>uL` - relative numbers
- `<lead>us` - spell check
- `<lead>ud` - diagnostics
- `<lead>uh` - inlay hints
- `<lead>uc` - conceal level
- `<lead>ug` - indent guides
- `<lead>uA` - the tab line (buffer tabs) · `<lead>uG` - git signs in the
  gutter
- `<lead>uz` - zen mode · `<lead>uZ` - zoom
- `<lead>ub` - dark/light background
- `<lead>uC` - pick a colorscheme
- `<lead>un` - dismiss all notifications
- `<lead>ua` animations · `<lead>uS` smooth scroll · `<lead>uD` dimming
- `<lead>ac` - autocomplete **[custom, deliberately not under `u`]**

Press `<lead>u` and pause to see the whole list with on/off state.

Defaults for these (what each starts as):
- numbers: `vim.opt.number = true` / `vim.opt.relativenumber = true` in
  `lua/config/options.lua` - true/false (now both `true`)
- spell: `vim.opt.spell = true` in `lua/config/options.lua` - true/false (now `false`;
  markdown and text turn it on regardless)
- diagnostics: the line `vim.diagnostic.enable(false)` in `lua/config/options.lua` -
  change `false` to `true`, or delete the line (now hidden)
- inlay hints: add `inlay_hints = { enabled = false },` inside `opts = {`
  in `lua/plugins/clangd.lua`, next to `servers` - true/false (now `true`)
- conceal: `vim.opt.conceallevel = 0` in `lua/config/options.lua` - a number 0-3; 0 shows
  markdown symbols as typed (now `2`)
- indent guides / smooth scroll: add `indent = { enabled = false }` and
  `scroll = { enabled = false }` to the `opts` in `lua/plugins/snacks.lua` -
  true/false (now both `true`)
- animations: `vim.g.snacks_animate = false` in `lua/config/options.lua` - true/false (now
  `true`)
- background: `vim.opt.background = "light"` in `lua/config/options.lua` - `"dark"` or
  `"light"` (now `"dark"`)
- colorscheme: `colorscheme = "kitty"` in `lua/plugins/disabled.lua` - text,
  the scheme's name (now `"kitty"`)
- tab line: create `lua/plugins/bufferline.lua` with `return { {`
  `"akinsho/bufferline.nvim", opts = { options = { always_show_bufferline`
  `= true } } } }` - true/false; `true` shows it even with one buffer (now
  `false`)
- autocomplete: see "Turn autocomplete on or off"
- zen, zoom, dimming and dismissing notifications are one-off actions -
  nothing to set

### Discover any keybinding
Press `<lead>` (or any prefix) and wait - which-key lists what's available.

```text
  ╭─────────────────────────────────────────╮
  │  b  +buffer        f  +file/find        │
  │  c  +code          g  +git              │
  │  s  +search        u  +ui               │
  │  q  +quit/session  x  +diagnostics      │
  ╰─────────────────────────────────────────╯
```

- `<lead>?` - buffer-local keymaps only (what's special where you are)
- `<lead>sk` - searchable list of every keymap

Defaults:
- which-key's popup delay: create `lua/plugins/which-key.lua` with
  `return { { "folke/which-key.nvim", opts = { delay = 500 } } }` - a number
  of milliseconds (now 200, and instant for plugin keys)
- `vim.opt.timeoutlen = 300` in `lua/config/options.lua` - milliseconds Vim
  waits for the rest of a multi-key shortcut (now `300`)

### Smarter `%` (matchit)
`%` also jumps between keyword pairs - `#if` / `#else` / `#endif`,
`if` / `else` / `end`, HTML tags - not just brackets.

- `:MatchDisable` / `:MatchEnable` - turn that off / on for this buffer ·
  `:MatchDebug` - show what it matches

### Things that happen by themselves
- **Start screen**: `f` find file · `n` new · `r` recent · `g` grep ·
  `p` projects · `s` restore session · `c` config · `l` Lazy · `x` extras ·
  `q` quit
- **Smooth scrolling** (`<lead>uS`), **indent guides** with the current scope
  highlighted (`<lead>ug`)
- **Reference highlighting**: other uses of the word under the cursor light up
- **Big files** (over 1.5 MB): LSP, treesitter and folds switch off so it
  stays fast
- **Notifications** pop up top-right; `<lead>n` shows the history
- `:NoMatchParen` / `:DoMatchParen` - stop / restart highlighting the
  matching bracket

Default for big files: `bigfile = { size = 3 * 1024 * 1024 }` in the
`opts` of `lua/plugins/snacks.lua` (see UI toggles) - a number of bytes
(now 1.5 MB). Smooth scroll and indent guides: see UI toggles.

### Reading the status line
Left to right:

- **Mode** (NORMAL, INSERT …) · **git branch**
- The project folder, diagnostic counts, the file icon and path
- Keys you've typed so far · `recording @q` while recording a macro
- Plugin updates waiting · git changes `+~-` for this file
- How far through the file (%) · `line:column` · the clock

Default: `vim.opt.laststatus = 3` in `lua/config/options.lua` - a number: `3` one line for
all windows, `2` one per window, `0` none (now `3`).

### Using the mouse
The mouse works everywhere (`mouse=a`).

- Click to move the cursor · drag to select · double-click a word
- Scroll wheel scrolls; with `<S-…>` a page at a time
- Right-click - a small menu (cut, copy, paste, go to definition …)
- `<C-LeftMouse>` - jump to the definition · `<C-RightMouse>` - back
- Middle-click - paste the primary selection
- Drag a window border or status line to resize

Hold `<S-…>` (Shift) while dragging to use kitty's own selection instead.

Default: `vim.opt.mouse = "a"` in `lua/config/options.lua` - text in quotes: `"a"`
everywhere, `"n"` normal mode only, `""` off (now `"a"`).

## Scratch buffers

### Quick throwaway notes
- `<lead>.` - toggle a scratch buffer
- `<lead>S` - pick from existing scratch buffers · in it, `<C-n>` makes a
  new one and `<C-x>` deletes the highlighted one

Scratch buffers persist per project - useful for notes or trying a snippet
without creating a file.

## Selection by code structure

### Expand or shrink a selection by syntax node
Grows the selection outward following the code's structure, not lines.

- `<C-Space>` - grow the selection to the next bigger node
- `<BS>` - shrink it back again (while selecting)
- `an` / `in` - select the parent (outer) / child (inner) node
- `]n` / `[n` - next / previous sibling node · `]N` / `[N` (visual) -
  select the next / previous sibling

What you see:

```text
  press <C-Space> repeatedly:

    compute(a, b)        1st →  a
                         2nd →  a, b
                         3rd →  (a, b)
                         4th →  compute(a, b)
```

Faster than counting brackets for `ci(`-style edits on nested code.

### Flash in operator-pending mode
- `r` - remote flash: run the pending operator somewhere else
- `R` - treesitter search

```text
  yr  then a label   →  yank that spot without moving the cursor
  dr  then a label   →  delete there, come straight back
```

## Tags & include search

### Tag jumps
- `<C-]>` - jump to the definition of the word under the cursor (answered by
  the language server here) · `<C-t>` - jump back
- `g]` / `g<C-]>` - choose when there are several matches
- `:tag {name}` / `:ts {name}` - jump / choose by name · `:tags` - the stack
- In help pages `<C-]>` follows a link and `<C-t>` goes back

### Search through `#include`d files
- `[i` / `]i` - show the first line (from the top / after the cursor) that
  uses the word under the cursor, searching included headers too
- `[I` / `]I` - list every such line
- `[<C-i>` / `]<C-i>` - jump to it
- `[<C-d>` / `]<C-d>` - jump to the `#define` of the word
- `:is /pat/` / `:il /pat/` / `:ij /pat/` / `:isp /pat/` - the same
  searches for any pattern: show / list / jump / split
- `:ds` / `:dli` / `:dj` / `:dsp` - the same for `#define`s

### More tag commands
- `:tn` / `:tp` / `:tf` / `:tl` - next / previous / first / last match of
  the last tag
- `:po` - back up the tag stack (like `<C-t>`)
- `:sta {name}` / `:stj` / `:sts` - the same in a new split
- `:lt {name}` - all matches into the location list
- `:pta {name}` / `:ptj` / `:pts` - show it in the preview window ·
  `:ped {file}` / `:pb {buf}` - preview a file / buffer ·
  `:pp` - back up the preview's tag stack · `:ptn` / `:ptp` / `:ptf` /
  `:ptl` - next / previous / first / last match in the preview


## Lists: quickfix & location

### Quickfix list
A global list of positions - grep results, diagnostics, compiler errors.

- `<lead>xq` - open the quickfix list
- `<lead>sq` - fuzzy-search its entries
- `]q` / `[q` - next / previous item
- `]Q` / `[Q` - last / first item

```text
  :grep timeout            fill it from a project search
  :cfdo s/old/new/g | update   run a command on every file in it
```

### Location list
Same idea as quickfix, but **per window** rather than global - so you can
keep one list per split.

- `<lead>xl` - open the location list
- `<lead>sl` - fuzzy-search it
- `]l` / `[l` - next / previous item
- `]L` / `[L` - last / first
- `]<C-l>` / `[<C-l>` - first item in the next / previous **file**
- `]<C-q>` / `[<C-q>` - same idea for the quickfix list

### Quickfix commands (built in)
- `:cope` / `:ccl` - open / close the list · `:cw` - open only if it has
  errors
- `:cn` / `:cp` - next / previous item · `:cfir` / `:cla` - first / last
- `:cc {n}` - item n · `:cnf` / `:cpf` - first item in the next / previous
  file
- `:cabo` / `:cbel` - the item above / below the cursor's line ·
  `:cbef` / `:caf` - before / after the cursor
- `:cl` - print the list · `:col` / `:cnew` - older / newer lists
  (Neovim keeps the last ten) · `:chi` - show that history
- `:cex {expr}` / `:cgete {expr}` / `:cadde {expr}` - fill from an
  expression (`:cex system('make')`) · `:cf {file}` / `:cb` - from a file /
  the current buffer · `:cg {file}` / `:cgetb` - load without jumping ·
  `:caddf {file}` / `:caddb` - add to the list
- `:cbo` - scroll the list window to the last entry
- `:cq` - quit Neovim with an error code (for scripts)

Every one of these has an `l…` twin for the location list: `:lop`, `:lne`,
`:ll {n}`, `:lvim`, `:lgr`, `:lmak`, `:lhi` …

### Jump between paired things
`[` and `]` are Vim's universal "previous / next" prefixes. In this setup:

```text
  b  buffer        d  diagnostic    e  error        w  warning
  q  quickfix      l  loclist       a  argument     t  todo comment
  h  git hunk      n  syntax node   T  tag stack

  ]x  next      [x  previous      ]X / [X  last / first
```

So `]d` is next diagnostic, `[h` is previous git hunk, and so on - one
pattern instead of a separate key per feature. The full set of targets:
`]b` `[b` buffers, `]d` `[d` diagnostics, `]e` `[e` errors, `]w` `[w`
warnings, `]q` `[q` quickfix, `]l` `[l` loclist, `]a` `[a` arguments,
`]t` `[t` todo comments, `]h` `[h` git hunks, `]n` `[n` syntax nodes, and
`]<C-t>` `[<C-t>` the tag stack. Capitals jump to the last / first:
`]A` `[A` argument-list file, `]T` `[T` tag match.

## Tools & meta

### Save the file
- `<C-s>` - save, from normal, insert **or** visual mode

Saves without making you leave insert mode first.

### Open a link or file under the cursor
- `gx` - open the URL or path under the cursor with the system handler

Opens a web link in your browser, a folder in your file manager - useful on
a plugin URL inside a config file.

### Look up the word under the cursor
- `<lead>K` - run `keywordprg` on the word (man page for shell, etc.)

Different from `K`, which is LSP hover documentation.

Default: `vim.opt.keywordprg = ":help"` in `lua/config/options.lua` - text in quotes: the
command `<lead>K` runs (now `":Man"`, man pages).

### Manage plugins and tools
- `<lead>l` - open Lazy: update, clean, profile startup, see what loaded
- `<lead>L` - LazyVim changelog
- `<lead>cm` - open Mason: install/remove LSP servers, formatters, linters

`<lead>cm` is where `ruff` was installed for Python formatting.

### Profile startup and performance
- `<lead>dpp` - toggle the profiler
- `<lead>dph` - toggle profiler highlights
- `<lead>dps` - open the profiler scratch buffer

Reach for these if Neovim starts feeling slow; Lazy (`<lead>l`) also shows
per-plugin startup time.

### Inspect highlights and syntax
- `<lead>ui` - inspect highlight groups under the cursor
- `<lead>uI` - open the treesitter tree inspector
- `<lead>uT` - toggle treesitter highlighting
- `<lead>sH` - search all highlight groups

The answer to "why is this word coloured like that?" - `<lead>ui` names the
exact highlight group in play.

Default for `<lead>uT` (treesitter colouring, now on) - to start with it
off, both:
- `opts.highlight = { enable = false }` inside the `opts = function(_, opts)`
  of `lua/plugins/languages.lua` - true/false
- `quickfile = { enabled = false }` in the `opts` of `lua/plugins/snacks.lua` (see UI toggles for creating it) - otherwise the file
  you name on the command line is coloured before your setting applies

### Browse icons
- `<lead>si` - search and insert nerd-font icons

### Noice message tools
- `<lead>sna` - all messages
- `<lead>snh` - message history
- `<lead>snl` - show the last message again
- `<lead>snd` - dismiss everything on screen
- `<lead>snt` - noice picker

### Snippets
- `<Tab>` / `<S-Tab>` - jump to the next / previous snippet placeholder

Snippets come from friendly-snippets through blink.cmp: accept one from the
completion menu, then `<Tab>` between the fields it leaves you.

### Vim defaults worth knowing
- `j` / `k` / `<Down>` / `<Up>` move by **screen** line, so they behave
  sensibly on wrapped text
- `&` - repeat the last `:s` substitution on this line
- `Y` - yank to end of line
- visual `@` - run a macro over every selected line
- visual `q` - see `:help v_Q-default`

## Visual & block editing

### The three visual modes
- `v` - character-wise
- `V` - line-wise
- `<C-v>` - **block** (column) selection
- `gv` - reselect whatever you selected last
- `o` - jump to the other end of the selection, to extend it the other way

### Edit many lines at once
Block selection plus `I` or `A` inserts the same text on every selected line.

```text
  <C-v>  then  jjj  to select a column, then  I  # <Esc>

    foo = 1            # foo = 1
    bar = 2      →     # bar = 2
    baz = 3            # baz = 3

  I  inserts before the block   ·   A  appends after it
  $  before A appends at each line's own end, however ragged
```

`c` on a block replaces the column on every line at once.

### Number a column automatically
- `g<C-a>` - in a visual selection, turn a column of numbers into an
  incrementing sequence (`g<C-x>` counts down; more in "Increase or
  decrease numbers")

```text
  select the zeros, press g<C-a>

    0. item        1. item
    0. item   →    2. item
    0. item        3. item
```

### Operators inside a selection
- `d` / `c` / `y` - delete, change, yank the selection
- `>` / `<` - indent; `gv` afterwards reselects so you can repeat
- `u` / `U` / `~` - lowercase / uppercase / toggle case
- `r{char}` - replace every selected character
- `J` - join the selected lines
- `gw` - reflow the selection as text (`gq` runs the code formatter here)
- `:` - starts an Ex command already scoped to the selection

### More in visual mode
- `g<C-x>` - like `g<C-a>`, but counts **down**
- `!{cmd}` - filter the selected lines through a shell command
- `aw`, `ip`, `i(` … - grow the selection by a text object
- `<C-c>` - leave visual mode
- `zy` - yank a block without the trailing spaces · `zp` / `zP` - paste a
  block without adding them

### Select mode
What snippets use: typing **replaces** the selection, like in other
editors.

`gV` - in a select-mode mapping, don't reselect the old area afterwards

- `gh` / `gH` / `g<C-h>` - start select mode by character / line / block
- `<C-g>` - switch between visual and select mode

## Ex command line & shell

### Ranges
Almost every `:` command takes a range in front of it.

```text
  :%s/…        whole file            :.s/…       current line
  :1,20s/…     lines 1-20            :.,+5s/…    this line + next 5
  :'<,'>s/…    the visual selection  :$s/…       last line
  :/foo/s/…    next line matching foo
  :'a,'bs/…    from mark a to mark b
```

### The command window
- `q:` - open your command history as an **editable buffer**
- `q/` - the same for search history
- `<C-f>` while typing a `:` command - switch into it mid-command

Edit any past command like normal text, press `<CR>` on a line to run it.
Far easier than arrowing through history for something long.

### Run shell commands
- `:!cmd` - run a shell command, show the output
- `:r !cmd` - read a command's output **into** the buffer
- `:w !cmd` - pipe the buffer into a command (without saving)
- `!{motion}cmd` - filter text **through** a command, replacing it

```text
  !ipsort<CR>        sort the current paragraph through `sort`
  :%!jq .            pretty-print the whole buffer as JSON
  :r !date           paste today's date on the next line
```

### Sort lines
- `:sort` - sort the whole file (or a range)
- `:sort!` - reverse
- `:sort u` - sort and remove duplicates
- `:sort n` - numeric sort (so 9 comes before 10)
- `:'<,'>sort` - sort just the selection

## Word wrap & long lines

### Turn wrap on or off
- `<lead>uw` - toggle wrap for this window
- `:set wrap` / `:set nowrap` - the same by command

Off by default for code, so long lines run off the right edge. Markdown,
text and git commit messages turn it **on** by themselves (along with spell
check). `linebreak` is on, so lines wrap between words, not mid-word.

This is soft wrap: only the display changes - the file still has one long
line. To actually split lines at a width, see "Hard wrap" below.

Default: `vim.opt.wrap = true` in `lua/config/options.lua` - true/false (now `false`).
Markdown, text and git commits turn it on regardless.

### Moving through wrapped lines
- `j` / `k` - move by **screen** line when a line wraps (LazyVim makes them
  `gj`/`gk`). With a count, `5j` still moves 5 real lines, so relative line
  numbers keep working
- `gj` / `gk` - always by screen line
- `g0` / `g$` - start / end of the screen line (`0` / `$` use the real line)
- `gm` - middle of the screen · `gM` - middle of the whole line
- `g^` - first non-blank on the screen line

### Nicer-looking wrapping
- `:setlocal breakindent` - wrapped parts keep the line's indentation
- `:set showbreak=↪\ ` - mark where a line continues with ↪

Defaults, in `lua/config/options.lua`:
- `vim.opt.breakindent = true` - true/false (now `false`)
- `vim.opt.showbreak = "↪ "` - text in quotes (now `""`, no marker)

### Long lines with wrap off
- `zl` / `zh` - scroll the view right / left one column (`10zl` for ten)
- `zL` / `zH` - half a screen right / left
- `zs` / `ze` - scroll so the cursor is at the left / right edge

The view also follows the cursor by itself, keeping 8 columns of context
on either side.

Default: `vim.opt.sidescrolloff = 8` in `lua/config/options.lua` - a number: columns kept
visible either side of the cursor (now `8`).

### Hard wrap: break lines at a width
- `:setlocal textwidth=80` - typing past column 80 starts a new line by
  itself, and `gw` reflows to 80
- `gwip` - reflow a paragraph to that width (see "Reflow paragraphs and
  comments")
- `:setlocal colorcolumn=80` - draw a guide line at column 80
- `:setlocal textwidth=0` - back to the default (no automatic breaking)

Defaults, in `lua/config/options.lua`:
- `vim.opt.textwidth = 80` - a number; `0` means no automatic breaking
  (now `0`)
- `vim.opt.colorcolumn = "80"` - text in quotes; `"80,120"` for two lines,
  `""` for none (now `""`)

## Folding

### How folding works here
Folds are worked out for you: by the language server in C/C++/Python files
(`foldmethod=expr`), by treesitter or indentation elsewhere. `foldlevel=99`
means everything starts **open** - you only see folds once you close them.

- `za` - toggle the fold under the cursor
- `zo` / `zc` - open / close it
- `zR` / `zM` - open **all** folds / close all folds
- `zj` / `zk` - move to the next / previous fold
- `zv` - open just enough to see the cursor line

```text
  zc on an indented block:

    def handler():              def handler():
        parse()            →    +---  3 lines ------
        run()
        log()
```

Default: `vim.opt.foldlevel = 99` in `lua/config/options.lua` - a number: folds nested
deeper than this start closed; `0` opens every file fully folded (now
`99`). How folds are found is picked per file automatically.

### More fold keys
- `zA` / `zO` / `zC` - toggle / open / close recursively (nested folds too)
- `zr` / `zm` - open / close one more level everywhere
- `zi` - folding on/off entirely · `zx` - reset to the calculated folds ·
  `zX` - the same without opening the fold you're in
- `zn` / `zN` - folding off / on (`zi` flips between them)
- `:foldo` / `:foldc` - open / close the folds in a range
- `:foldd {cmd}` - run a command on every line **not** inside a closed
  fold · `:folddoc {cmd}` - only on lines inside closed ones
- `[z` / `]z` - start / end of the open fold you're in

### Make folds by hand
The automatic folds here refuse `zf` (`E350`). Switch the window first:
`:setlocal foldmethod=manual` (or `marker` for `{{{` / `}}}` markers).

- `zf{motion}` - fold that text (`zfap` a paragraph, visual `zf` a selection)
- `zF` - fold n lines · `:{range}fo` - fold a range
- `zd` / `zD` - delete this fold / nested folds · `zE` - delete every fold

Default - to always fold by hand, all three (a plain `foldmethod` line on
its own is overridden when a language server attaches):
- `vim.opt.foldmethod = "manual"` in `lua/config/options.lua` - text in quotes
- `folds = { enabled = false },` inside `opts = {` in
  `lua/plugins/clangd.lua`, next to `servers` - true/false
- `opts.folds = { enable = false }` inside the `opts = function(_, opts)`
  of `lua/plugins/languages.lua` - true/false

## Insert-mode tricks

### Paste and delete without leaving insert
- `<C-r>{reg}` - insert a register's contents
- `<C-r>"` - the last yank · `<C-r>0` - the last explicit yank
- `<C-r>%` - the current filename
- `<C-w>` (or Ctrl+Backspace, which kitty sends as `<C-w>`) - delete the word before the cursor
- `<C-u>` - delete back to the start of the line
- `<C-o>` - run **one** normal-mode command, then return to insert
- `<C-t>` / `<C-d>` - indent / unindent the current line

`<C-o>` is the one to remember: `<C-o>A` jumps to end of line and keeps
typing, without an `<Esc>` round trip.

### Special characters
- `<C-k>` then two letters - insert a digraph, e.g. `<C-k>a:` gives ä -
  **only in files without a language server** (text, markdown). In code,
  `<C-k>` shows function parameters instead; use `<C-v>u00e4` there
- `:dig` - table of every digraph
- `<C-v>u00e9` - insert a character by unicode codepoint

### Built-in completion
Works even while autocomplete is off. The menu opens with **nothing
selected**: press `<C-n>` to move onto the first match, then `<C-y>`.

- `<C-n>` / `<C-p>` - words from open buffers (next / previous match)
- `<C-y>` - accept · `<C-e>` - cancel, restoring what you typed
- `<C-x><C-l>` - a whole line · `<C-x><C-f>` - a file path
- `<C-x><C-o>` - language-server suggestions (C++, Python)
- `<C-x><C-n>` - words from this file only
- `<C-x><C-i>` - words from this file and `#include`d files ·
  `<C-x><C-d>` - `#define` names
- `<C-x>s` (or `<C-x><C-s>`) - spelling suggestions · `<C-x><C-k>` -
  dictionary ·
  `<C-x><C-t>` - thesaurus
- `<C-x><C-v>` - Vim commands · `<C-x><C-]>` - tags ·
  `<C-x><C-u>` - custom (`completefunc`)
- `<C-x><C-e>` / `<C-x><C-y>` - scroll the window without leaving insert
- `<C-x><C-p>` - like `<C-x><C-n>`, searching backwards
- `<C-x><C-r>` - the contents of registers · `<C-x><C-z>` - stop, keeping
  what you typed

Default: `vim.opt.completeopt = "menu,menuone"` in `lua/config/options.lua` - text in
quotes; without `noselect` the first match is picked straight away (now
`"menu,menuone,noselect"`).

### More insert-mode keys
- `<C-a>` - type again whatever you typed last time · `<C-@>` - same, then
  leave insert
- `<C-y>` / `<C-e>` (no menu open) - copy the character from the line
  above / below
- `<C-g>u` - start a new undo step here, mid-typing · `<C-g>U` - don't
  start one on the next arrow-key move (for mappings)
- `<C-g>j` / `<C-g>k` - line down / up, back at the column you started at
- `0<C-d>` - remove all indent · `^<C-d>` - just for this line
- `<C-v>{key}` - insert a key literally, e.g. a real tab with `<C-v><Tab>`
- `<C-c>` - leave insert immediately (skips abbreviations and autocommands)
- `<C-]>` - expand an abbreviation without typing a space
- `<C-\><C-n>` / `<C-\><C-g>` - back to normal mode from **any** mode
  (insert, visual, the command line, a terminal)
- Arrow keys, `<Home>` / `<End>`, `<PageUp>` / `<PageDown>` and `<Del>`
  work as usual · `<C-Home>` / `<C-End>` - start / end of the file

## Command-line editing

### Pull text into the command line
- `<C-r><C-w>` - insert the word under the cursor
- `<C-r><C-a>` - the WORD under the cursor
- `<C-r>%` - the current filename
- `<C-r>{reg}` - any register

```text
  cursor on "timeout", then:   :%s/<C-r><C-w>/delay/g
  → the command line already reads  :%s/timeout/delay/g
```

### History and extras
- `<Up>` / `<Down>` - history **filtered by what you've typed so far**
- `q:` - full history as an editable buffer
- `<S-CR>` - redirect the command's output into a popup (noice)
- `<C-s>` - toggle flash search while typing a `/` search

Default for `<C-s>`: `opts = { modes = { search = { enabled = true } } },`
in the flash spec in `lua/plugins/flash.lua` - true/false; `true` shows
flash labels in every `/` search (now `false`).

### Moving and completing on the command line
- `<Tab>` / `<S-Tab>` - complete commands, files, options … ·
  `<C-n>` / `<C-p>` - next / previous in that list
- `<C-d>` - list everything that could complete here
- `<C-b>` / `<C-e>` (or `<Home>` / `<End>`) - start / end of the line
- `<S-Left>` / `<S-Right>` - a word left / right
- `<C-w>` / `<C-u>` - delete a word / everything before the cursor
- `<S-Up>` / `<S-Down>` - history **without** the "starts with" filter
- `<C-v>{key}` - insert a key literally
- `<C-c>` - abandon the command line

## Repeat a change across matches

### cgn: change next match, then repeat
`gn` selects the next match of the last search, so `cgn` changes it - and
then `.` repeats the whole find-and-change.

```text
  /timeout<CR>        search for it once
  cgn delay <Esc>     change this match
  .                   change the next one
  n .                 skip one, change the one after
```

The advantage over `:%s` is that you approve each change as you go, with a
single keystroke, and you can skip freely with `n`.

- `gn` / `gN` - select the next / previous match
- `dgn` - delete the next match
- `cgn` - change it

## More operators

### Change case with a motion
- `gU{motion}` - uppercase · `gu{motion}` - lowercase · `g~{motion}` - toggle
- `gUiw` - uppercase the word · `guu` / `gUU` - the whole line

### Re-indent code
- `={motion}` - re-indent by the language's rules
- `==` - the current line · `=G` - from here to end of file · `=ip` - paragraph

Uses the same treesitter-based indent logic as typing does.

### Reflow paragraphs and comments
**Use `gw`, not `gq`, in this setup.** LazyVim points `formatexpr` at its own
formatter, so `gq` runs conform/LSP **code formatting** over the range rather
than wrapping text. `gw` always uses Vim's internal formatter and ignores
`formatexpr`, so it is the one that actually reflows prose.

- `gw{motion}` - reflow text, e.g. `gwip` for a paragraph
- `gww` - the current line
- `gwap` - a paragraph including its blank line
- `gq{motion}` - runs the **code formatter** here (same as `<lead>cf` on a range)

Wrap width comes from `textwidth`, which is `0` by default here - with 0 it
falls back to 79 columns. Set `:setlocal textwidth=72` first if you want a
specific width. Verified: with `textwidth=60`, `gww` wraps at 60 while `gqq`
leaves the line untouched.

Default: `vim.opt.textwidth = 72` in `lua/config/options.lua` - a number; `0` falls back
to 79 for `gw` and never breaks lines as you type (now `0`).

## Diff mode

### Compare two files
- `nvim -d file1 file2` - open straight into a diff
- `:diffthis` in two windows - diff whatever is already open
- `:diffoff` - stop diffing · `:diffupdate` - recompute

### Move and apply changes
- `]c` / `[c` - next / previous difference
- `do` - "diff obtain": pull the other side's version into this buffer
- `dp` - "diff put": push this side's version to the other buffer

For git specifically, `<lead>ghd` (gitsigns) diffs the current file against
the index without setting this up manually.

### Diff commands
- `:diffs {file}` - split and diff against that file ·
  `:vert diffs {file}` - side by side
- `:diffg` / `:diffpu` - the `do` / `dp` commands, but they take a range
  (`:'<,'>diffg`) and a buffer name when three files are open
- `:diffp {patch}` - apply a patch file and show the result as a diff
- `:windo diffthis` - diff every window in the tab
- `:syncb` - line up windows that scroll together (`scrollbind`)

## Spell checking

### Turn it on and fix words
Spell checking is **off** in code, and turns **on** by itself in markdown,
text and git commit messages.

- `<lead>us` - toggle it on/off
- `]s` / `[s` - jump to the next / previous misspelling
- `z=` - suggest corrections for the word under the cursor
- `zg` - add the word to your dictionary ("good")
- `zw` - mark a word as wrong
- `zug` - undo a `zg`

```text
  z= on a misspelled word:

    Change "recieve" to:
      1  receive
      2  relieve
    Type number and <Enter>:
```

Defaults, in `lua/config/options.lua`:
- `vim.opt.spell = true` - true/false (now `false`; markdown and text are
  on regardless)
- `vim.opt.spelllang = "en,de"` - text in quotes, comma-separated
  languages (now `"en"`)

### More spelling keys and commands
- `zuw` - undo a `zw` · `zG` / `zW` - good / wrong for this session only ·
  `zuG` / `zuW` - undo those
- `:spellr` - after fixing one word with `z=`, fix every other copy of it
- `:spellgood {word}` / `:spellwrong {word}` / `:spellundo {word}` -
  the same as `zg` / `zw` / `zug`, typed · `:spellrare {word}` - mark rare
- `:setlocal spelllang=en,de` - check against several languages
- `:spellinfo` - which dictionaries are loaded · `:spelldump` - list every word
- `:mkspell {out} {wordlist}` - build a spell file from your own word list

Default: `vim.opt.spelllang = "en,de"` in `lua/config/options.lua` - text in quotes,
comma-separated (now `"en"`).

## Undo time travel

### Beyond plain undo
Undo in Vim is a **tree**, not a line, and this setup has `undofile` on -
so undo history survives closing and reopening the file.

- `u` / `<C-r>` - undo / redo
- `g-` / `g+` - move backwards / forwards through **every** state, including
  branches that plain `u` can't reach
- `:earlier 10m` / `:later 5m` - jump by time
- `:earlier 3f` / `:later 1f` - jump by file **writes**
- `<lead>su` - browse the whole tree visually

`:earlier 1f` is the "undo everything since my last save" button.

Default: `vim.opt.undofile = true` in `lua/config/options.lua` - true/false: keep undo
history after closing a file (now `true`).

### Undo commands
- `:u {n}` - jump to undo state n (numbers from `:undol`) · `:red` - redo
- `:undoj` - merge the next change into the previous undo step
- `:wundo {file}` / `:rundo {file}` - save / load the undo history
  (`undofile` already keeps it between sessions)

Defaults, in `lua/config/options.lua`:
- `vim.opt.undofile = true` - true/false: keep undo history after closing
  a file (now `true`)
- `vim.opt.undolevels = 10000` - a number: how many changes are kept (now
  `10000`)

### Crash recovery (swap files)
- `nvim -r {file}` or `:rec` - recover unsaved edits from a swap file
- `:pre` - write the swap file right now · `:sw` - show its path
- `nvim -r` - list every swap file that can be recovered

Default: `vim.opt.swapfile = false` in `lua/config/options.lua` - true/false (now `true`).
LeetCode sessions already turn it off.

## Terminal mode

### Working inside a terminal buffer
- `<lead>ft` / `<lead>fT` - open a terminal (root dir / cwd)
- `<C-\><C-n>` - leave terminal-insert mode, so you can scroll, search and
  yank the output like any buffer
- `i` or `a` - go back to typing in the shell
- `<C-/>` - closes the terminal from **inside** it

That last one is worth knowing: `<C-/>` is the comment toggle in normal and
visual mode here, but inside a terminal buffer it still toggles the terminal
away, which is exactly what you want.

## Ex commands reference

### Work on lines
- `:t {address}` (or `:co`) - copy lines: `:t.` duplicates this line,
  `:5t0` copies line 5 to the top
- `:m {address}` - move lines: `:m0` to the top, `:m$` to the bottom
- `:d` / `:y` - delete / yank lines: `:5,10d`, `:%y+` copies the whole file
- `:j` - join lines · `:>` / `:<` - indent / unindent (`:5,10>`)
- `:pu {reg}` - put a register on its own line (`:pu +` from the clipboard)
- `:norm {keys}` - run normal-mode keys on each line: `:%norm A;` puts a
  `;` at the end of every line
- `:ce` / `:ri` / `:le` - centre / right-align / left-align lines
- `:= {lua}` - evaluate Lua and print it, e.g. `:= vim.o.shiftwidth`
- `:uniq` - remove duplicate lines that are **next to each other**
  (`:sort u` if they're scattered)
- `:&` - repeat the last `:s` · `:&&` - with its flags too
- `:~` - repeat the last `:s`, but with the last **search** pattern
- `:*` - the last visual area as a range (same as `:'<,'>`)
- `:@{reg}` - run a register's text as a command · `:@@` - repeat that
- `:!!` - repeat the last shell command
- `:{n}` - go to line n · `:z` - print the lines around the cursor
- `:p` / `:nu` / `:l` - print lines · with numbers · showing tabs and line
  ends
- `:a` / `:i` / `:c` - type lines in after / before / in place of these
  (finish with a line holding just `.`)
- `:go {n}` (or `{n}go`) - jump to byte n of the file
- `gQ` - Ex mode: type `:` commands one after another (`:vi` leaves)

### Run a command in many places
- `:bufdo` / `:windo` / `:tabdo` - every buffer / window / tab
- `:cdo` / `:cfdo` - every quickfix entry / file · `:ldo` / `:lfdo` - the
  location list
- `:argdo` - every file in the argument list
- End with `| update` to save as you go: `:cfdo %s/old/new/g | update`

### The argument list
The files you opened Neovim with - a list you can edit and walk through.

- `:args` - show it · `:args *.cpp` - replace it
- `:arga {file}` - add · `:argd {pattern}` - remove · `:argded` - dedupe
- `:n` / `:N` (or `:prev`) - next / previous file · `:fir` / `:la` - first
  / last · `:wp` - save, then previous
- `:arge {file}` - add a file and edit it · `:argu {n}` - go to file n
- `:wn` / `:wN` - save, then next / previous file
- `:sn` / `:sa {n}` - the same moves, in a split · `:all` / `:sal` - a
  window for every file
- `:argl` / `:argg` - give this window its own list / go back to the
  shared one
- Naming patterns: an `s` in front usually means "in a split" (`:sbf`,
  `:sla`, `:sN`), and `…rewind` is the same as `…first` (`:rew`, `:brew`,
  `:cr`, `:tr`, `:tabr`)

### Look things up
- `:reg` · `:marks` · `:jumps` · `:changes` · `:undol` (undo branches)
- `:his` - command history (`:his /` for searches)
- `:mes` - past messages (`:mes clear` empties it) · `g<` - the last
  command's output again
- `:map` / `:nmap` / `:imap` … - list mappings; `:verbose nmap {key}` says
  where one was defined
- `:com` - user commands · `:au` - autocommands · `:hi` - highlight groups
- `:filter /{pat}/ {cmd}` - keep only matching lines of a command's
  output, e.g. `:filter /cpp/ oldfiles`, `:filter /Lsp/ command`
- `:scr` - loaded scripts · `:ve` - Neovim version
- `:set` - options you've changed · `:set all` - every option ·
  `:opt` - browse options in a window

### Change options on the fly
- `:set {opt}` / `:set no{opt}` / `:set {opt}!` - on / off / toggle
- `:set {opt}?` - show · `:set {opt}&` - back to default
- `:set {opt}+=x` / `-=x` - add to / remove from a list option
- `:setl` - this buffer or window only · `:setg` - the global value
- `:lua {code}` - run Lua · `:so %` - run the current file

Changes last until you quit; permanent ones go in `lua/config/options.lua`.

### Abbreviations and quick mappings
- `:iab {abbr} {text}` - expand as you type, e.g. `:iab teh the`
- `:ab` - list · `:una {abbr}` - remove · `:abc` - clear all ·
  `:norea {abbr} {text}` - one that isn't expanded any further ·
  `:ca` / `:cabc` - abbreviations for the command line
- `:nnoremap {key} {keys}` (also `inoremap`, `vnoremap` …) - a mapping
  for this session · `:unmap {key}` removes it · `:noremap` - all of
  normal, visual and operator-pending at once
- `:command {Name} {cmd}` - a user command for this session

Permanent mappings live in `lua/config/keymaps.lua`.

### Sessions, views and history
- `:mks {file}` - save windows, tabs and buffers · `:so {file}` - restore
  (persistence.nvim does this for you - see Sessions)
- `:mkview` / `:loadview` - save / restore one window's folds and cursor
- `:ol` - recently opened files · `:bro ol` - pick one
- `:wsh` / `:rsh` - write / read the ShaDa file (history, marks and
  registers kept across restarts)

### Build and grep with Vim's own tools
- `:make` - run `make` and load the errors into the quickfix list ·
  `:comp {name}` - switch compiler
- `:gr {pattern}` - ripgrep into the quickfix list
- `:vim /{pattern}/ **/*.cpp` - Vim's own (slower) grep, with Vim regex
- `:helpg {pattern}` - grep every help page
- `!!{cmd}` - replace this line with a command's output, e.g. `!!date`

### The help system
- `:h {topic}` - e.g. `:h ciw`, `:h 'wrap'` (options in quotes),
  `:h :sort` (commands), `:h i_CTRL-R` (insert-mode keys)
- `<C-]>` / `<C-t>` - follow a link / go back
- `:h index` - every built-in key and command, by mode
- `:Man {page}` - read a man page inside Neovim
- `<F1>` - open help · `:helpc` - close it · `:helpt {dir}` - build tags
  for a plugin's docs
- `:exu` / `:viu` - one-screen summaries of Ex / normal-mode commands ·
  `:intro` - the splash screen

### Rarely needed
- `:redir @a` … `:redir END` - capture command output into a register
- `gs` - pause for a second (Vim's "go to sleep"; `3gs` = three seconds)
- `:dl` - delete a line and print the next one (old line-editor habit)
- `:exe {string}` - run a command built from a string
- `:sil {cmd}` - run quietly · `:noa {cmd}` - without autocommands
- `:keepj` / `:lockm` - leave the jump list / marks untouched
- `:match` / `:2match` / `:3match` - extra highlight patterns
- `:sign` - gutter signs · `:syntime` / `:prof` - performance profiling
- `:breaka` / `:debug` - Vimscript debugging
- `:Open {path}` - open a path or URL with the system's default app
- `:UpdateRemotePlugins` - re-register Python/Node remote plugins
- The rest (GUI menus, `:lmap` keymaps for other languages …):
  `:h ex-cmd-index`

### Everything else, briefly
Mostly for scripts, old terminals or other setups:

- **Vimscript language**: `:let` `:const` `:unlet` `:lockvar` `:unlockvar`,
  `:if` `:elseif` `:else` `:endif`, `:for` `:while` `:break` `:continue`,
  `:function` `:return` `:call` `:delfunction`, `:try` `:catch` `:finally`
  `:throw`, `:eval` `:echo` `:echohl` `:finish` `:defer`
- **GUI menus**: `:menu` and its mode variants (`:amenu`, `:nmenu`,
  `:imenu`, `:vmenu` …, plus `unmenu` / `noremenu` forms), `:emenu`,
  `:popup` (the right-click menu is `PopUp`), `:tmenu`
- **GUI windows**: `:gui` / `:gvim`, `:winpos`, `:winsize`
- **Other languages**: `:python` / `:py3` / `:pyx`, `:perl`, `:ruby` and
  their `…do` / `…file` forms - they need that language's provider
  (`:checkhealth provider`)
- **Debugging**: `:breakdel`, `:breaklist`, `:debuggreedy`, `:profdel`
- **Legacy**: `:mkexrc` / `:mkvimrc` (write out settings), `:smagic` /
  `:snomagic`, `:language`, `:loadkeymap`, `:k` (= `:mark`), `:mode`,
  `:sleep`, `:unsilent`, `:redrawstatus`, `:cmapclear` and the other
  `…mapclear`s

## Config & health

### Inspect this setup
- `:checkhealth` - full diagnostic report (providers, LSP, plugins)
- `:set opt?` - show an option's current value, e.g. `:set shiftwidth?`
- `:verbose set opt?` - show its value **and which file last set it**
- `:setlocal` - change an option for this buffer/window only

`:verbose set shiftwidth?` is the fastest way to answer "why is this 4 and
where did that come from?".

### Manage the setup
- `:Lazy` (`<lead>l`) - plugins: update, clean, see startup times
- `:Mason` (`<lead>cm`) - language servers, formatters, linters
- `:LazyExtras` - LazyVim's optional add-ons: **language packs** (one
  wires up the LSP, formatter, treesitter parser and debugger for that
  language together) and **plugin extras** like surround - see "Turn
  LazyVim extras on and off"

`:LazyExtras` is LazyVim's route to language packs. The C/C++ server here
was set up directly instead (`lua/plugins/clangd.lua`) rather than through
the extra, to avoid pulling in `clangd_extensions.nvim` - see the clangd
entry under LSP.

### Turn LazyVim extras on and off
- `:LazyExtras` - opens the list; `x` on a line toggles that extra
- `●` = enabled, `○` = off. Sections: "Recommended Languages", "Enabled
  Plugins", "Enabled Languages", "Recommended Plugins", then all the rest
- restart Neovim, then `:Lazy clean` (or `X` inside `:Lazy`) - deletes
  the plugins a switched-off extra had downloaded

What you see:

```text
  LazyVim Extras
  Enabled Plugins: (4)
    ● coding.blink                  ← LazyVim's built-in defaults show
    ● coding.mini-surround          ← here too; mini-surround is ours
    ● editor.snacks_explorer           (x on its line turns it off)
    ● editor.snacks_picker
  Recommended Plugins: (2)
    ○ ai.copilot                    ← off
    ○ coding.yanky
  Plugins: (...)
    ○ ai.supermaven
    ○ coding.mini-comment
```

`x` acts instantly on the line under the cursor, so scrolling while
pressing `x` switches on extras by accident - check "Enabled Plugins"
before closing. The list is saved in `~/.config/nvim/lazyvim.json`
(`"extras": [...]`), which can also be edited by hand.

`:Lazy clean` removes plugin folders only. Some extras also leave files
elsewhere - Supermaven, for example, creates `~/.supermaven`.

Default: stock LazyVim enables no extras (`"extras": []`); now only
`lazyvim.plugins.extras.coding.mini-surround` **[custom]**.

Switched on by mistake once and removed again: `ai.supermaven`,
`ai.tabnine` (AI completion), `coding.luasnip`, `coding.mini-snippets`
(snippets already come from blink.cmp) and `coding.mini-comment` (Neovim's
own `gc` does commenting).

### Plugin manager windows
Inside `:Lazy` (`<lead>l`):

- `S` - sync (install, clean, update) · `I` - install · `U` - update ·
  `X` - clean out removed plugins
- `C` - check for updates · `L` - log · `R` - restore to the lockfile
- `P` - profile startup · `D` - debug · `H` - home · `?` - help
- `<CR>` - details · `d` - diff · `K` - hover docs · `]]` / `[[` - next /
  previous plugin · `q` - close

Inside `:Mason` (`<lead>cm`):

- `i` - install · `u` - update · `U` - update all · `X` - uninstall
- `c` / `C` - check this / all for newer versions
- `<CR>` - expand details · `<C-f>` - filter by language · `g?` - help

### More setup commands
- `:LazyHealth` - LazyVim's health check · `:LazyRoot` - how the project
  root was detected
- `:MasonUpdate` - refresh Mason's package list · `:MasonLog` ·
  `:MasonUninstallAll`
- `:MasonUninstall {pkg}` - remove one package
- `:BlinkCmp status` - which completion sources are active ·
  `:BlinkCmp build` / `build-log` - rebuild its fast matcher
- `:NoiceAll` - every message, including hidden ones · `:NoiceHistory` -
  same as `:Noice` · `:NoicePick` / `:NoiceSnacks` - history in a picker ·
  `:NoiceLog` · `:NoiceStats` · `:NoiceConfig` · `:NoiceRoutes` ·
  `:NoiceViewstats` · `:NoiceDebug` (`:NoiceFzf` / `:NoiceTelescope` need
  plugins that aren't installed)
- `:TSInstallFromGrammar {lang}` - build a parser from source
- `:PlenaryBustedFile {file}` / `:PlenaryBustedDirectory {dir}` - run Lua
  tests (for plugin development)
- `:TSInstall {lang}` / `:TSUpdate` / `:TSUninstall {lang}` - treesitter
  parsers · `:TSLog`
- `:InspectTree` - the syntax tree of this file · `:Inspect` - highlight
  groups under the cursor · `:EditQuery` - try treesitter queries live
- `:Noice` - message history · `:NoiceLast` · `:NoiceErrors` ·
  `:NoiceDismiss` · `:NoiceDisable` / `:NoiceEnable`
- `:WhichKey` - every mapping · `:WhichKey <lead>g` - one group

### Scripting and runtime commands
- `:ru {file}` - source a file from the runtime path · `:pa {pack}` - load
  an optional package · `:packl` - load all of them
- `:colo {name}` - switch colour scheme · `:sy on` / `:sy off` - syntax
  highlighting
- `:filet` - filetype detection status · `:setf {ft}` - set a filetype
  unless one is already set
- `:luaf {file}` - run a Lua file · `:luado {code}` - run Lua on each line
  (`:luado return line:upper()`)
- `:aug {name}` / `:do {event}` / `:doautoa {event}` - autocommand groups,
  and firing events by hand
- `:delc {Name}` / `:comc` - remove one / all user commands ·
  `:mapc` / `:nmapc` … - remove all mappings of a mode
- `:conf {cmd}` - ask instead of failing, e.g. `:conf q` offers to save
- `:kee {cmd}` / `:keepa {cmd}` / `:keepp {cmd}` - leave marks / the
  alternate file / the search pattern alone
- `:sandbox {cmd}` - run a command with side effects blocked
- `:star` / `:stopi` / `:startr` - enter insert / leave it / enter replace,
  from a script
- `:trust` - allow a project's `.nvim.lua` / `.exrc` to run
- `:restart` (or `ZR`) - restart Neovim and restore the session ·
  `:restart!` - without restoring
- `:detach` - leave Neovim running in the background; reattach later
- `:qa` = `:quita` · `:st` = `<C-z>` · `:asc` = `ga` · `:di` = `:reg`

### Where the config lives
```text
  ~/.config/nvim/
    lua/config/options.lua     editor options
    lua/config/keymaps.lua     custom keybindings
    lua/config/autocmds.lua    automatic behaviour
    lua/plugins/*.lua          one file per plugin override
    cheatsheet.md              this document (the original)
    cheatsheet.user.md         your edited copy, once you edit
    lua/cheatsheet.lua         the picker that shows it
```

Anything in `lua/plugins/` is merged over LazyVim's defaults, so a file
there only needs the parts you want to change.

## Regex & patterns

### Which regex flavour applies where
This matters constantly and trips people up - the same pattern does not work
everywhere in this setup.

- `/pattern`, `?pattern`, `:s`, `:g`, `:v` - **Vim regex**
- `<lead>sg` / `<lead>/` grep, and `<lead>sr` grug-far - **ripgrep** (Rust
  regex, essentially PCRE-style)

```text
  find "foo(" or "bar("      Vim:      /\v(foo|bar)\(
                             ripgrep:  (foo|bar)\(
```

Rule of thumb: in ripgrep `+ ? ( ) { } |` work bare; in Vim they need
backslashes unless you turn on very-magic mode with `\v`.

### Magic levels: \v \m \M \V
Vim has four levels controlling how many characters are "special".

```text
  \v  very magic    all of + ? ( ) { } | < > work bare, like PCRE
  \m  magic         DEFAULT: . * [] work bare; + ? ( ) | need a backslash
  \M  nomagic       only . and * lose their meaning too
  \V  very nomagic  literally everything except \ is a plain character
```

`\v` vs `\V` is a classic trap:
- `\v` (lowercase) = **very magic** (turns ON regex metacharacters).
- `\V` (uppercase) = **very nomagic** (turns OFF regex, matches literal verbatim text).

`\V` is the one to reach for when searching text full of punctuation or exact code -
`/\Vhttp://x.com` or `:%s/\Vv[i-k]/el/g` needs no escaping at all.

### Very magic mode: \v
Put `\v` at the start and Vim's regex behaves the way you expect from other
languages.

```text
  without \v :   /\(foo\|bar\)\+\d\{2,3}
  with    \v :   /\v(foo|bar)+\d{2,3}
```

Worth making a habit - nearly every non-trivial Vim pattern is shorter and
more readable with `\v`.

**The bracket / array gotcha:** In `\v`, square brackets `[...]` are STILL
character classes, NOT literal brackets!
```text
  \vv[i-k]       matches "vi", "vj", "vk" (class [i-k], brackets are consumed)
  \vv\[[i-k]\]   matches "v[i]", "v[j]", "v[k]" (escaped brackets around class)
  \Vv[i-k]       matches literal "v[i-k]" (uppercase \V = verbatim search)
```

### Character classes
- `.` - any character except a newline
- `\d` / `\D` - digit / non-digit
- `\w` / `\W` - word character `[0-9A-Za-z_]` / non-word
- `\s` / `\S` - whitespace / non-whitespace
- `\a` - alphabetic, `\l` - lowercase letter, `\u` - uppercase letter
- `\x` - hex digit
- `[abc]` / `[^abc]` - any of / none of
- `[a-z0-9_]` - ranges, as usual
- `\[` / `\]` - literal square brackets (must escape to match array indices like `arr\[\d\+\]`)

Careful: in a **replacement** `\u` and `\l` mean something completely
different (see "case tricks" below).

### Quantifiers and repeats
```text
  magic (default)        very magic (\v)      meaning
  *                      *                    0 or more
  \+                     +                    1 or more
  \?  or  \=             ?                    0 or 1
  \{2,5}                 {2,5}                between 2 and 5
  \{3}                   {3}                  exactly 3
  \{-}                   {-}                  0 or more, NON-greedy
  \{-1,}                 {-1,}                1 or more, non-greedy
```

`\{-}` is Vim's equivalent of PCRE's `*?` - it matches as little as
possible, which is what you want for things like `\v".{-}"`.

### Anchors and word boundaries
- `^` - start of line, `$` - end of line
- `\<` / `\>` - start / end of a word (in `\v`: `<` and `>`)
- `\%^` / `\%$` - start / end of the **file**
- `\%V` - restrict the match to the visual selection

```text
  /\<log\>      matches "log" but not "login" or "catalog"
  /\vlog>       same thing in very-magic mode
```

### Match start and end: \zs and \ze
Vim-specific and genuinely useful: they move where the *match* begins and
ends, so you can require context without consuming it.

```text
  /foo\zsbar        matches "bar", but only when preceded by "foo"
  /foo\zebar        matches "foo", but only when followed by "bar"

  :%s/version: \zs\d\+/99/     changes only the number, keeps the label
```

Replaces the need for lookahead/lookbehind in most practical cases.

### Groups, alternation and backreferences
- `\(...\)` - a group (in `\v`: `(...)` )
- `\%(...\)` - a group that does **not** capture
- `\|` - alternation (in `\v`: `|` )
- `\1` … `\9` - backreference to a captured group

```text
  find a doubled word:
    /\v<(\w+)\s+\1>

  swap two comma-separated fields:
    :%s/\v(\w+), (\w+)/\2, \1/
```

### The replacement side
The right-hand side of `:s` has its own small language.

- `&` or `\0` - the whole match
- `\1` … `\9` - captured groups
- `~` - the previous replacement string
- `\u` / `\l` - upper/lowercase the **next character**
- `\U` / `\L` - upper/lowercase until `\E`
- `\E` - end a `\U` or `\L` run
- `\=` - evaluate the rest as a Vimscript **expression**

```text
  :%s/\w\+/"&"/g              wrap every word in quotes
  :%s/\v_(\w)/\u\1/g          snake_case  →  camelCase
  :%s/\v(\l)(\u)/\1_\l\2/g    camelCase   →  snake_case
  :%s/\d\+/\=submatch(0)+1/g  increment every number by 1
```

### Newlines: the classic gotcha
`\n` does **not** mean the same thing on both sides of a `:s`.

```text
  searching:     \n  matches a line ending          ✔
  replacing:     \n  inserts a NUL byte (shows as ^@)   ✘
  replacing:     \r  inserts a real newline          ✔

  join every pair of lines:   :%s/\n//
  split on every comma:       :%s/,/\r/g
```

Matching across line breaks:
- `\_s` - whitespace **including** newline
- `\_.` - any character **including** newline (multi-line / dotall match)

```text
  /\vfunc\_s+main        matches even if "main" is wrapped onto the next line
  /\v/\*\_.*\*/          matches multi-line C-style /* comments */
```

### Case sensitivity
This setup has `ignorecase` **on** with `smartcase` **on** (verified).

```text
  /timeout      matches Timeout, TIMEOUT, timeout   (all lowercase → loose)
  /Timeout      matches Timeout only        (a capital → case-sensitive)
  /timeout\c    force case-INsensitive, whatever the options say
  /Timeout\C    force case-sensitive
```

`\c` and `\C` work anywhere in the pattern, not just at the start.

Defaults, in `lua/config/options.lua`:
- `vim.opt.ignorecase = true` / `vim.opt.smartcase = true` - true/false
  (now both `true`)

### Live preview while substituting
`inccommand` is set to `nosplit`, so as you type a `:%s/.../.../` command the
matches highlight and the replacement is previewed **in the buffer**, before
you press Enter.

```text
  :%s/timeout/delay/g
     ▲ every match already shows as "delay" while you type;
       press <Esc> and nothing was ever changed
```

Default: `vim.opt.inccommand = "nosplit"` in `lua/config/options.lua` - text in quotes:
`"nosplit"` previews in place, `"split"` adds a window listing every
change, `""` turns it off (now `"nosplit"`).

### Limit a substitution to part of the file
```text
  :%s/a/b/g        whole file
  :s/a/b/g         current line only
  :.,+5s/a/b/g     this line and the next 5
  :1,20s/a/b/g     lines 1 to 20
  :'<,'>s/a/b/g    the visual selection (Vim fills this in for you)
  :%s/\%Va/b/g     only inside the selection, anywhere in the file
```

Without the `g` flag only the **first** match on each line is replaced
(`gdefault` is off here, which is the standard behaviour).

Default: `vim.opt.gdefault = true` in `lua/config/options.lua` - true/false; `true` makes
every `:s` replace all matches on a line without `/g` (now `false`).

### Run a command on every matching line: :g and :v
`:g` is one of the most powerful things in Vim and has no keybinding - it
runs an Ex command on every line matching a pattern.

```text
  :g/TODO/d            delete every line containing TODO
  :v/TODO/d            delete every line NOT containing it (also :g!)
  :g/^$/d              delete all blank lines
  :g/TODO/t$           copy matching lines to the end of the file
  :g/TODO/m0           move them to the top (reverses their order)
  :g/^/m0              reverse the whole file
  :g/pat/normal A;     append a ";" to every matching line
  :g/pat/norm gcc      comment out every matching line (see Comments)
```

`:v` is just "inverse `:g`". Combining `:g` with `normal` lets you run any
normal-mode keystrokes on every matching line.

More of these, by task: the "Batch edits on many lines" category.

### Practical recipes
```text
  strip trailing whitespace     :%s/\s\+$//e
  blank runs → one blank line   :%s/\n\{3,}/\r\r/g
  delete blank runs entirely    :g/^$/,/./-1d
  remove adjacent duplicates    :g/^\(.*\)$\n\1$/d
  quote every line              :%s/^.*$/"&"/
  numbers → +1                  :%s/\d\+/\=submatch(0)+1/g
  replace array indices         :%s/\vv\[([i-k])\]/el[\1]/g
  literal punctuation replace   :%s/\Vv[i-k]/el/g
  custom delimiter (paths/URLs) :%s#/var/log#/tmp#g
  keep only matching lines      :v/pattern/d
  count matches                 :%s/pattern//gn
```

The trailing `e` flag in the first one means "don't error if nothing
matched", which keeps it safe inside mappings and macros. The `n` flag in
the last one **counts** without changing anything.

## Batch edits on many lines

### Prefix or append text on many lines (start or end)
- `:%norm A;` - append `;` to every line · `:5,20norm A,` - lines 5-20
- `:'<,'>norm A,` - every line of a visual selection (`:` in visual
  mode fills in the `'<,'>`)
- `:%s/$/,/` - the same with a substitute
- `:g/TODO/norm I- ` - prefix matching lines, after their indentation
- `:5,20s/^/    /` - add 4 spaces at column 0 of lines 5-20
- block `<C-v>`, then `$A;` - append to ragged line ends (see "Edit many
  lines at once")

```text
  a              :%norm A;        a;
  b        →                  →   b;
```

`norm` runs the keys as if typed on each line, so `A` / `I` keep their
usual meaning: end of line / after the indentation.

Stock Vim - nothing configured. Same in stock LazyVim and in Vim.

### Change only the lines that match a pattern
- `:g/TODO/s/old/new/g` - substitute, but only on lines containing `TODO`
- `:g/TODO/norm gUU` - uppercase those lines
- `:g/TODO/>` / `:g/TODO/<` - indent / unindent them one level
- `:g/TODO/norm @q` - run macro `q` on each of them
- `:g/v/exe "norm \<C-a>"` - add 1 to the first number on each
- `:v/TODO/...` - any of the above on lines **not** matching

```text
    TODO one             :g/TODO/norm gUU         TODO ONE
  banana           →                       →    banana
    TODO two                                      TODO TWO
```

`<C-a>` can't be typed straight into `:norm`, so the `exe "norm
\<C-a>"` form spells the key out (`:norm` then `<C-v><C-a>` also works).

Stock Vim - nothing configured. Same in stock LazyVim and in Vim.

### Copy, collect, duplicate or space out lines
- `:call setreg('a', []) | g/TODO/y A` - collect every matching line
  into register `a` (then `"ap` pastes them all)
- `:let @+ = @a` - copy that collection to the system clipboard
- `:g/TODO/t$` / `:g/TODO/m0` - copy them to the end / move to the top
- `:g/^/t.` - duplicate every line
- `:g/TODO/put _` - a blank line after each match · `:g/^/put _` -
  double-space the file

```text
  :call setreg('a', []) | g/TODO/y A
     register a  →  "  TODO one\n  TODO two\n"
```

Upper-case `A` **appends** to register `a`, which is why it starts empty.
The common `qaq` trick to empty it leaves a stray blank first line -
`setreg('a', [])` doesn't.

Stock Vim - nothing configured. Same in stock LazyVim and in Vim.

### Join lines in bulk
- `:g/key/j` - join every line containing `key` with the line below
- `:g/^/j` - join lines in pairs (1+2, 3+4, ...)
- `:'<,'>j` - join a selection into one line · `:'<,'>j!` - without
  adding spaces

```text
  key:                      key: value
    value      :g/key/j     other
  other           →         key: v2
  key:
    v2
```

Stock Vim - nothing configured. Same in stock LazyVim and in Vim.

### Number, de-duplicate, sort and align lines
- `:%s/^/\=line('.') .. '. '/` - number every line `1. 2. 3.`
- `:'<,'>s/^/\=(line('.') - line("'<") + 1) .. '. '/` - number a
  selection starting from 1
- `:%!awk '\!seen[$0]++'` - drop duplicate lines, keeping the original
  order (the `\!` stops Vim reading `!` as "previous command")
- `:sort u` - sort and drop duplicates · `:sort n` - numeric sort
- `:'<,'>!column -t` - line text up in columns

```text
  a = 1                          a       =  1
  longer = 22   :%!column -t     longer  =  22
  x = 3              →           x       =  3
```

`:%!cmd` sends lines through a shell command and replaces them with its
output - `awk` and `column` are ordinary system tools.

Stock Vim - nothing configured. Same in stock LazyVim and in Vim.

### Delete part of every line
- `:%s/\s*#.*//e` - remove `#` comments from the end of every line
- `:%s/^\s\+//` - remove all indentation
- `:%norm dw` - delete the first word of every line
- `:%norm f#D` - delete from the first `#` to the end (leaves the space
  before it - the `:s` version above doesn't)
- `:%s/\v(\w+), (\w+)/\2, \1/` - swap two fields: `doe, john` →
  `john, doe`

Stock Vim - nothing configured. Same in stock LazyVim and in Vim.

## GhostText & buffer language

### Edit browser text in Neovim (GhostText)
Click the GhostText browser extension on any text box and it opens here in
a new tab; every edit syncs back to the page live. Close the tab (or the
page) to end it.

- `leetcode.com` opens straight into **C++** **[custom]** - clangd,
  clang-format and C++ indentation, all attached automatically
- any other site opens as plain text - use `<lead>cL` to pick a language

For LeetCode itself, `nvim leetcode.nvim` is the better route - see the
LeetCode section.

What you see:

```text
  tab title:   leetcode.com-2.cpp
  :set ft?     filetype=cpp
  <lead>cl     clangd attached
```

Why it needed work: ghost buffers are unnamed scratch buffers, and Neovim
refuses to attach a language server to those. This setup names the buffer
with the right extension (under `~/.cache/nvim/nvim-ghost/`) and starts the
matching servers itself. Nothing is ever written to disk.

### Set the language of any buffer
- `<lead>cL` - pick a filetype for the current buffer **[custom]**

Your languages are listed first; every other filetype is one fuzzy search
away. Works in any buffer - including plain `:enew` scratch buffers, which
otherwise have no language at all, so indentation, autopairs and formatting
behave oddly in them.

```text
  ╭─ Language for this buffer ───────╮
  │ > py                             │
  │   python                         │
  │   pyrex                          │
  ╰──────────────────────────────────╯
```

In a GhostText buffer, switching language also swaps the language server
(e.g. cpp -> python detaches clangd and attaches ruff).

### Formatting in a ghost buffer
- `<lead>cf` - format it

Format-on-save never fires for ghost buffers (they're never saved - the
text syncs to the browser instead), so format manually before you submit.

## LeetCode

### Solve LeetCode inside Neovim
Replaces the browser tab: browse problems, write, run, test and submit
without leaving Neovim.

- `nvim leetcode.nvim` - launch a dedicated LeetCode session **[custom]**
- `:Leet` - open the menu (problems, daily, random, lists)

Solutions are real `.cpp` files, so clangd, clang-format and format-on-save
all work normally - better than the GhostText route for LeetCode.
LeetCode compiles C++ with `bits/stdc++.h` and `using namespace std`
implicitly; the plugin adds those two lines to each solution (folded out of
the way) so clangd doesn't flag every `vector` as undeclared, and strips
them again before anything is sent.

Default: `lang = "cpp"` in `lua/plugins/leetcode.lua` - text in quotes,
e.g. `"python3"`, `"java"` (now `"cpp"`).

### Log in (first time only)
- `:Leet cookie update`, or the "Sign in" button on the start screen

It asks in two boxes **[custom]**:
1. `csrftoken` - the value of the csrftoken cookie
2. `LEETCODE_SESSION` - the value of the LEETCODE_SESSION cookie

Where to find them: log in to leetcode.com, open dev tools -> Network,
click a request to leetcode.com itself (not assets.leetcode.com), open its
Cookies tab and copy each value. Pasting them with their names
(`csrftoken=...`) works too, and stray spaces are trimmed.

Shortcut: paste the whole Request Headers -> `Cookie` value into the first
box and it skips the second.

Stock leetcode.nvim has a single box that needs the whole Cookie header;
pasting just one value there fails with "Bad csrf token format".

Treat both values like a password - together they are your logged-in
session.

### Run, test and submit
- `<C-'>` - run against the example test cases **[custom]**
- `<C-CR>` (Ctrl+Enter) - submit for judging **[custom]**

The same keys as on leetcode.com, in normal and insert mode. Both exist
only inside a LeetCode solution file, so they can't clash with anything
else. The plugin itself ships no
keys for these. There's no separate test key: `:Leet test` and `:Leet run`
send your code to the same place.

The same actions as commands:
- `:Leet run` / `:Leet test` - run against the example test cases
- `:Leet submit` - submit for judging
- `:Leet console` - show / hide the docked console
- `:Leet desc` - toggle the problem description
- `:Leet lang` - switch language for this problem
- `:Leet reset` - reset the code to the starting template
- `:Leet last_submit` - restore your last submission
- `:Leet open` - open the problem in the browser
- `:Leet yank` - copy just the solution code

### More keys in a solution file
All **[custom]**, only inside LeetCode solution files (`\` = local leader):

- `\e` - show / hide the description (side panel - `e` like the explorer)
- `\c` - show / hide the docked console
- `\h` - hints
- `\i` - info (stats, topics)
- `\t` - jump to another open question
- `\o` - open the problem in the browser
- `\y` - yank just the solution code
- `\R` - reset the code to the starting template (`u` undoes)
- `\L` - restore your last submission (`u` undoes)

Capitals are the two that replace your code.

### Layout: test cases and results docked at the bottom
Every question opens as **[custom]**:

```text
  ┌─ description ─┬───── code ─────┐
  │               │                │
  ├── testcases ──┴──── result ────┤
  └────────────────────────────────┘
```

- the console stays open while you edit - compare output with code
  side by side
- `<C-'>` / `<C-CR>` keep you in the code; the result fills in below
- real splits: resize with `<C-w>+` / `<C-w>-` / `<C-w><` / `<C-w>>`
  or by dragging with the mouse, move with `<C-w>h/j/k/l`
- the result pane's title turns green / red with the verdict
- `q` in the console hides it, `:Leet console` brings it back

Stock leetcode.nvim shows the console as a floating box over the code
that closes as soon as you leave it, and that ignores window commands.

### Console and test case keys
Inside the results console:

- `q` - close / toggle the console
- `<CR>` - confirm
- `r` - reset test cases
- `U` - use a test case
- `H` - focus the test cases pane
- `L` - focus the results pane
- `1`, `2`, ... - switch between test cases

### Find problems
- `:Leet list` - browse and filter all problems
- `:Leet daily` - today's daily problem
- `:Leet random` - a random problem
- `:Leet menu` - back to the menu
- `:Leet exit` - close the session

### A question won't open (swap file warning)
Symptom: opening a problem you've done before shows Neovim's "Found a swap
file" warning, and after Recover or Delete the question never appears.

Cause: that solution file is already open in another Neovim - usually a
second `nvim leetcode.nvim` running at the same time. Neovim's warning
turns into an error in the way the plugin loads solutions, so it gives up.

- Fixed **[custom]**: LeetCode sessions no longer create swap files, so this
  can't happen from a new session. A session already running from before
  the change still has them - restart it once.
- Still worth running only one LeetCode session at a time: two sessions
  editing the same problem would overwrite each other's saves.
- `:Leet tabs` - find a problem that's already open in another tab

Tradeoff: with no swap file, a crash loses edits since your last `:w`.
The saved file and your LeetCode submissions are unaffected.

### When it says your cookie expired
The message "Your cookie may have expired, or LeetCode has temporarily
restricted API access" is a **catch-all**: the plugin shows it for *any*
rejected request (a 401 or 403), so it can't tell you why. Three different
causes sit behind it, and each has a different fix:

```text
  cause                     how to tell                        fix
  cookie really expired     haven't pasted one in a while      :Leet cookie update
  LeetCode throttling       during contests; site slow too     wait; turn off VPN
  Cloudflare bot check      a FRESH cookie still fails at      curl-impersonate
                            once, site fine in the browser     (see below)
```

What to do, in order:
1. `:Leet cookie update` with a fresh cookie - fixes it most of the time
2. still failing immediately, and not contest time -> almost certainly
   Cloudflare: use the fix below
3. contest time -> wait it out; nothing on your side fixes throttling

To check when your current cookie expires: browser dev tools ->
Application (Storage in Firefox) -> Cookies -> leetcode.com -> the Expires
column for `LEETCODE_SESSION`.

### Fix Cloudflare blocking (curl-impersonate)
Only for the Cloudflare case above - it does nothing for an expired cookie
or for throttling.

- `sudo pacman -S curl-impersonate` - official repos, no AUR needed
- then in `lua/config/options.lua`:
  `vim.g.plenary_curl_bin_path = "curl_chrome136"`
- restart Neovim

Why it works: every request goes through the ordinary `curl` program.
The plugin already sends a browser User-Agent, but Cloudflare recognises
curl anyway from *how it opens the secure connection*, which differs from
a real browser. curl-impersonate is a curl build that opens connections
exactly like Chrome, so it gets let through. The setting just tells plenary
which curl program to run (plenary reads it in `plenary/curl.lua`).

`curl_chrome136` is the profile users confirmed working. The package also
ships newer ones (`curl_chrome150`, and Firefox profiles such as
`curl_firefox147`) if 136 ever stops passing.

### What plenary is
`plenary.nvim` is a general-purpose Lua toolkit that plugins build on -
HTTP requests, file paths, async jobs, test tooling. leetcode.nvim uses
two parts: `plenary.curl` for every request to LeetCode (which is why the
Cloudflare fix is a plenary setting), and `plenary.path` for where your
solutions are stored. LazyVim itself and todo-comments also depend on it,
so it stays installed regardless.

Its maintainers have announced it's ending *active* maintenance: no new
features and slower fixes, but existing code keeps working. It only
becomes a problem if a future Neovim change breaks it and nobody patches
it.

## Customizations: default vs current

### Keys changed from stock LazyVim
```text
  <C-/>        terminal            →  toggle comment  (terminal: <lead>ft)
  x            deletes into "" reg →  black hole (your yank survives)
  <lead>st/sT  Telescope todo      →  Snacks grep (no Telescope here)
  <lead>xt/xT  Trouble todo        →  removed (Trouble disabled)

  new  gsa gsd gsr gsf gsF gsh   surround (coding.mini-surround extra;
                                 replaces Vim's gs = sleep)
  new  t (explorer)  open the file in a new tab page
  new  <lead>ac    toggle autocomplete
  new  <lead>ghP   focused hunk popup
  new  <lead>y/Y   clipboard yank (OSC 52 over SSH)
  new  <lead>h     this cheatsheet
  new  <lead>ch    switch C/C++ source <-> header (clangd)
  new  <lead>cL    set the language of the current buffer
  new  dm{mark}     delete a mark (dm- = all lowercase marks)
  new  \r / \s     LeetCode run / submit (solution files only)
  new  <C-e> <C-x> <C-o>   in this cheatsheet: edit / restore / edit original
```

### Options changed
```text
  shiftwidth   2  →  4
  tabstop      2  →  4
  expandtab    true (unchanged - spaces, not tabs)
  diagnostics  shown  →  hidden at start   (<lead>ud shows them)
  autocomplete on     →  off at start      (<lead>ac turns it on)
  signature    pops up by itself → only on <C-k> (insert) / gK
  clang-format 2-space LLVM → 4-space (~/.clang-format)
```

Indent *logic* was already treesitter-based; only the width changed.

### Plugins disabled
```text
  nvim-treesitter-textobjects   ]f/[f structural jumps - unused
  mini.ai                       af/if smart text objects - unused
  nvim-lint                     no linters configured; ruff LSP covers Python
  trouble.nvim                  diagnostics panel - unused
  tokyonight / catppuccin       colours come from colors/kitty.lua
  nvim-ts-autotag               HTML/JSX only
  ts-comments.nvim              HTML/JSX only
  lazydev.nvim                  Lua-config editing helper
```

### Plugins added
- `scope.nvim` - each tab page lists only its own buffers (default: all
  buffers in every tab) - `lua/plugins/scope.lua`, see "What a tab is
  here"
- `mini.surround` - add / delete / replace quotes and brackets (`gsa`,
  `gsd`, `gsr`), via LazyVim's `coding.mini-surround` extra - the only
  extra enabled (default: none). See Surround.
- `nvim-ghost.nvim` - edit browser textareas in Neovim (with per-site
  languages and LSP support - see the GhostText entry)
- `leetcode.nvim` - solve LeetCode problems in Neovim (also brought the
  `html` treesitter parser back, which it uses for problem descriptions)

### Language servers
- Python - `ruff` (installed via Mason, also does the formatting)
- C / C++ - `clangd` **[custom]**, system package, configured in
  `lua/plugins/clangd.lua` without LazyVim's full extra

### Formatters added
- `clang-format` for C/C++ (system package, ships with `clang`)
- `ruff format` for Python (Mason)

On a fresh machine only ruff needs installing: `:MasonInstall ruff`.

### Colorscheme
Not a plugin theme - `colors/kitty.lua` reads kitty's live theme file and
matches it, so Neovim tracks your terminal colours automatically.

Popups and sidebars are see-through like the editor **[custom]**: they use
the editor's background colour, which kitty renders at its
`background_opacity`. Covers the file explorer, the LeetCode description
panel, hover docs, which-key and Lazy. The completion menu stays solid so
the selected item is easy to spot. (Before: solid grey boxes.)

## This cheatsheet

### How to use it
- `<lead>h` - open it

`<lead>h` was chosen because it is genuinely unclaimed - no custom mapping,
nothing nested under it, and no native Vim command displaced. Bare `?`
stays as backward-search, and `<lead>?` is LazyVim's buffer-local keymaps
popup, so neither was taken.
- Type to fuzzy-search entry titles; the right pane previews the selection
- `<CR>` - open that one entry on its own
- `<Esc>` - close · `<BS>` from a single entry goes back to the list
- `<C-e>` - edit the selected entry · `e` does the same from a single entry
- `<C-x>` - restore the original cheatsheet (asks first)
- `<C-o>` - edit the selected entry in the original

### How to edit it
Edit one entry at a time, never the whole file:

- `<C-e>` in the list (or `e` while reading an entry) - opens just that
  entry in a small window. Change it, then `:w` to save only that entry.
- `q` - close the edit window (warns if unsaved) · `:q!` - close, discard
- `:q` with unsaved changes keeps them - reopen the entry to get them back
- Delete everything and `:w` - removes the entry (asks first)
- Add a new `### Title` line inside the window - saves as an extra entry
- Keep the first line as the `### Title` heading - saving is refused
  without it. Changing the title text itself is fine.

Your edits go into your own copy, `~/.config/nvim/cheatsheet.user.md`,
made from the original the first time you edit. The picker title says
"(your copy)" once it exists.

### Restore the original
- `<C-x>` in the list - asks, then deletes your copy. You're back on the
  original, however old the edits were. There's no undo.
- The original is `~/.config/nvim/cheatsheet.md`. Nothing you do with
  `<C-e>` ever changes it.

New entries added to the original later don't reach your copy by
themselves - a restore picks them up, but loses your edits.

### Edit the original itself
- `<C-o>` in the list - edit the selected entry in the original, same
  window and `:w` as `<C-e>`. This changes what a restore brings back.

While you have your own copy, the picker shows the copy, so a change to
the original only shows up after a restore.

### File format
`## Category`, then `### Entry title` followed by body lines. The file is
re-read every time the cheatsheet opens, so changes show immediately, no
restart. Headings inside fenced code blocks are ignored by the parser, so
examples containing `#` are safe.
