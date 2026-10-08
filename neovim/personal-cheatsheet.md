# Personal cheatsheet (`<leader>h`)

**Category:** neovim
**Files touched:** `cheatsheet.md`, `lua/cheatsheet.lua`, `lua/config/keymaps.lua` (all under `~/.config/nvim/`; copies in [`files/`](files/))

<!-- graph:begin -->
**Graph:** [[Neovim]]
<!-- graph:end -->

History of the searchable in-editor cheatsheet: why it's custom, the three UI rewrites, content audits, and the keybinding it ended up on. Part of the LazyVim setup - see [[lazyvim-migration]] for the migration itself and the index of all topic files.

Entries are in the order they happened. They were split out of `lazyvim-migration.md` on 2026-09-23 without rewording, so "above" and "previous follow-up" refer to entries in this file unless a link says otherwise.

## Follow-up: personal cheatsheet on g? (2026-09-22/23)

**What**: built a searchable personal cheatsheet - `g?` opens `~/.config/nvim/
cheatsheet.md` in a centered floating window and immediately launches a live
fuzzy-search-with-preview over its lines, so typing e.g. "buffer" filters straight to
the relevant section.

**Why not an existing plugin**: researched `cheatsheet.nvim` and `legendary.nvim` first
rather than assuming nothing existed. Neither actually fit: `cheatsheet.nvim`'s
no-Telescope fallback just dumps every bundled sheet concatenated into one static
floating window with no live fuzzy filter (this setup uses Snacks, not Telescope), and
its bundled content wouldn't cover this setup's own customizations (grug-far, the
`gs`/`gS` rebind, `<leader>ghP`, etc.) regardless. `legendary.nvim`/`which-key.nvim`
(already installed) surface keymap -> one-line-description pairs, not the prose
"how does `:%s` relate to grug-far" explanations actually being asked for. That gap
needed real curated content either way, so built it directly on what's already
installed (`Snacks.picker.lines()`) instead of adding a new dependency for a UI shell
that wouldn't add anything Snacks doesn't already do here.

**Also compared Telescope vs Snacks broadly** before settling on Snacks (the user asked
directly) - Snacks is confirmed to be LazyVim's own current default (its internal
`checks.picker` order is `snacks -> fzf -> telescope`), everything built this session
already assumes it, and it already has the frecency/live-search capability needed here
built in. Telescope's edge is a larger/older extension ecosystem, not a fit for this
specific need.

**Keybinding decision** (3 rounds of live-checking before landing on one - worth
recording since it's a good example of why "verify live, not by assumption" matters):
1. Bare `?` considered first - rejected without discussion needed, it's native
   backward-search, used constantly, no simple substitute the way `s`/`S` had `cl`/`cc`.
2. `<leader>?` recommended next, assumed free by analogy to the earlier `<leader>a`
   check - **wrong**, confirmed live it's already LazyVim's "Buffer Keymaps (which-key)"
   binding, a genuinely useful existing feature (shows buffer-local keymaps for
   whatever you're currently in). Caught only because the user pointed at checking
   before proceeding, not because it was checked proactively first this time - a real
   process miss.
3. `<F1>` and `g?` both confirmed free via `nvim_get_keymap`. `<F1>` was the first
   instinct (universal "help" convention), but user raised that a terminal emulator or
   window manager could intercept a function key before Neovim ever sees it - checked
   `~/.config/kitty/kitty.conf` and `~/.config/hypr/` directly, no F1 binding at either
   layer *today*, but function keys are structurally the class most likely to get
   grabbed by a lower layer, a risk plain letter-combos like `g?` don't have at all.
   Landed on **`g?`** - native `g?` is ROT13-encode-a-motion, essentially unused, and it
   keeps a `?` in the key, closest to the original ask.

**Change** - `~/.config/nvim/cheatsheet.md` (new, ~150 lines): topic sections covering
Buffers, Tabs, Windows/Splits, Search & Replace (both `:%s` and grug-far, as asked),
Git, Comments, Flash navigation, Autocomplete, Formatting, Autopairs, Snacks
find/search, LSP (including the still-open C++-has-no-LSP gap), Sessions, and
Discoverability - each entry covers the actual keys wired up in *this* setup, not
generic Vim defaults.

`~/.config/nvim/lua/config/keymaps.lua`, appended:
```lua
vim.keymap.set("n", "g?", function()
  local path = vim.fn.stdpath("config") .. "/cheatsheet.md"
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " Cheatsheet ",
  })
  vim.wo[win].wrap = true
  vim.wo[win].conceallevel = 2
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  Snacks.picker.lines({ buf = buf })
end, { desc = "Cheatsheet" })
```

**Verified live**: headless Neovim. `g?` registers with `desc = "Cheatsheet"`.
Simulated the actual keypress: window count jumps from 1 to 6 (base + centered floating
cheatsheet window with a title + Snacks picker's own input/list/preview windows),
confirmed the cheatsheet buffer loaded with all 150 lines. Full close lifecycle also
verified: `<Esc>` drops back to 2 windows (picker closes, cheatsheet stays open), `q`
drops back to 1 (cheatsheet closes cleanly too).

## Follow-up: cheatsheet UX rewrite - dropped the double-window, made confirm just close (2026-09-23)

**What**: real usability problems with the first cut, reported directly: "both line
search and entire file are opening" (the separate pre-opened floating window plus the
picker's own UI showing at once was visually cluttered) and selecting a result "directed
[to] the complete buffer at that line" (jarring - dumped into a raw scrollable file
instead of just answering the lookup), making it barely better than just using `:help`.

**Fix**: removed the separate `nvim_open_win` floating window entirely - the picker's
own preview pane already renders the matched section with context, so pre-opening a
second window showing the same file was pure duplication. Overrode the default
`confirm` action (which is `jump` - Snacks' own source confirms this at
`snacks/picker/actions.lua:197`) to `"close"` (a built-in action, confirmed present in
the same file) instead, since this is a reference lookup, not somewhere to go edit -
selecting a result now just closes the picker and returns you to whatever you were
doing, rather than navigating anywhere.

**Change** - `~/.config/nvim/lua/config/keymaps.lua`, `g?` handler simplified to:
```lua
vim.keymap.set("n", "g?", function()
  local path = vim.fn.stdpath("config") .. "/cheatsheet.md"
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  Snacks.picker.lines({
    buf = buf,
    confirm = "close",
  })
end, { desc = "Cheatsheet" })
```

**Verified live**: tested against a throwaway copy of the file (a live interactive
`nvim --embed` session had the real `cheatsheet.md` open with a swap lock at the time -
correctly left that alone rather than touching its swap file, tested against a copy
instead). Confirmed: opening the picker now shows exactly 5 windows (base + Snacks'
input/list/preview - no extra duplicate floating window), stays at 5 while typing a
filter, and drops straight back to 1 window on `<CR>` (picker closes cleanly, no jump).
Also confirmed the preview pane genuinely renders matching content live - filtering for
"grug" surfaced the actual grug-far section text in one of the picker's windows, not a
blank/broken preview.

## Follow-up: cheatsheet rebuilt as a clean floating window instead of a picker (2026-09-23)

**What**: asked to make it "look similar to noice" after the Snacks-picker rewrite still
wasn't good. Spent real effort trying to reshape `Snacks.picker.lines()`'s layout first
- tried the `vscode` and `select` layout presets (both are single-box designs, closer to
noice's aesthetic than the default `ivy` 3-pane bottom dock), and tried forcing
`preview = "preview"` to get an embedded preview pane. Neither held up: the `lines`
source ties its preview to the "main" window in a way that doesn't cleanly relocate into
a custom layout's preview slot, and after reshaping, filtering for "grug" no longer
reliably surfaced matching content anywhere on screen (verified live, confirmed
empty/not-found rather than assuming). Rather than keep fighting an opaque layout
system, dropped Snacks' picker entirely for this and built a fully self-contained
floating window instead.

**New design**: a single centered floating window with a rounded border and a
" Cheatsheet " title - the same visual recipe noice.nvim itself uses for its own popups
(confirmed via `nvim_win_get_config`: real border table, correct title, 70%-of-screen
sizing). `filetype = "markdown"` for real syntax highlighting of the content. Search is
native Vim `/` (real incremental search + match-count indicator, e.g. `[1/2]`) rather
than a picker - `/` is fed automatically the moment it opens, so you can start typing a
search term immediately. `q` and `<Esc>` both close it.

**Change** - `~/.config/nvim/lua/config/keymaps.lua`, `g?` handler replaced:
```lua
vim.keymap.set("n", "g?", function()
  local path = vim.fn.stdpath("config") .. "/cheatsheet.md"
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  local width = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.7)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " Cheatsheet ",
    title_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].conceallevel = 2
  vim.wo[win].cursorline = true
  vim.bo[buf].filetype = "markdown"
  local close_opts = { buffer = buf, silent = true }
  vim.keymap.set("n", "q", "<cmd>close<cr>", close_opts)
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", close_opts)
  vim.api.nvim_feedkeys("/", "n", false)
end, { desc = "Cheatsheet" })
```

**Verified live**: tested against a throwaway copy again (the real file still had a live
`nvim --embed` session's swap lock). Confirmed the floating window has a real border
table, title text " Cheatsheet ", and correct dimensions. Confirmed real `/grug<CR>`
search jumps straight to the actual line mentioning grug-far, with Neovim's native
`[1/2]` match-count indicator showing - genuine incremental search, not a simulation.
`q` closes back to a single window cleanly.

**Lesson for later**: two failed iterations before this (the pre-opened-window-plus-
picker version, then the bare `Snacks.picker.lines()` version) both under-verified the
*visual/UX* result even though the underlying mechanics were confirmed working -
"the keymap registers and doesn't error" isn't the same bar as "the actual on-screen
result is good," and this one needed direct user feedback twice to get right.

## Follow-up: cheatsheet rebuilt as a section picker (2026-09-23)

**What**: third and final shape for this. Previous versions searched *lines* of one
markdown file, which meant results were fragments and selecting one dumped you into the
raw document. Rebuilt around **entries**: the markdown is parsed into one entry per
`### Title` block (grouped by the `## Category` above it), the picker fuzzy-matches
entry titles + category, the right pane previews the selected entry, and `<CR>` opens
**only that entry** in its own centered float.

This is what was actually asked for: typing `find` yields "Find text in the current
line" / "Find text in the current file" / "Find text across the whole project" /
"Find files by name" etc. as distinct selectable sections, rather than raw line hits.

**Content**: rewritten and expanded from ~150 lines to **525 lines / 80 entries**
covering find, replace, buffers, windows, tabs, motions, editing, text objects,
registers/clipboard, macros, comments, autocomplete, autopairs, formatting, LSP,
diagnostics, git, sessions, terminal, explorer, UI toggles, scratch buffers - plus a
dedicated "Customizations: default vs current" category listing every key changed from
stock LazyVim, options changed (`shiftwidth`/`tabstop` 2 -> 4), plugins disabled,
plugins added and formatters wired up. Entries that differ from stock LazyVim are
tagged **[custom]** with the default called out.

Content was grounded in a **full dump of the live keymap table** (`nvim_get_keymap` for
global maps, `nvim_buf_get_keymap` in an LSP-attached Python buffer for buffer-local
ones) rather than written from memory - which caught that this setup uses Neovim 0.11+
native LSP bindings (`grn`, `gra`, `grr`, `gri`, `grt`, `gO`, `<C-w>d`) alongside
LazyVim's buffer-local `K`/`gr`/`gD`/`gI`/`gy`, not the older `gd`/`gr`/`K` trio I'd
otherwise have written down.

**Why a custom Snacks source this time**: the two earlier attempts used
`Snacks.picker.lines()`, a built-in source whose preview is wired to the "main" window
and which fought every attempt to reshape its layout. A *custom* source sidesteps all
of that - `Snacks.picker({ items = ..., preview = "preview", format = ... })` takes
arbitrary items, and each item carries its own `preview = { text = ..., ft = ... }`
which the generic `"preview"` previewer renders directly
(`snacks/picker/preview.lua:57`). Layout is the stock `default` preset: centered,
two-pane, list left / preview right.

**Change** - `~/.config/nvim/lua/cheatsheet.lua` (new, 136 lines): markdown parser
(`M.entries()`), single-entry float (`M.show()`), picker (`M.open()`).
`~/.config/nvim/cheatsheet.md` rewritten (525 lines).
`~/.config/nvim/lua/config/keymaps.lua`: `g?` now just calls
`require("cheatsheet").open()`.

In the single-entry float: `q` / `<Esc>` close, `<BS>` goes back to the search list.

**Verified live**: parser yields 80 entries with correct category grouping. Fuzzy
matching verified by driving the picker's `pattern` field programmatically (feedkeys
does **not** reach the picker's floating input in headless mode - an earlier check
showing "80 items, unfiltered" was a test-harness artifact, not a real filtering
failure, and was re-tested properly rather than assumed): `"clipboard"` -> 3 matches
(all genuinely clipboard-related), `"find"` -> 15, `"replace"` -> 5 (exactly the five
Replace entries). Picker opens with a 7-window two-pane layout and the preview pane was
confirmed to render the selected entry's **body** (matched on distinctive content,
`f{char}`, not just the title). `<CR>` confirmed to close the picker and open a single
float titled with the entry name, sized to content (`w=64 h=9`), containing only that
entry's text.

## Follow-up: cheatsheet polish - no backdrop dimming, wrapped preview (2026-09-23)

**What**: reported that "the entire theme is changing" when the cheatsheet opens. Root
cause: Snacks' `default` layout preset doesn't disable the **backdrop** - a full-screen
overlay window at 60% opacity black (`snacks/win.lua:108`, `bg = "#000000"`) drawn
behind the picker, which dims the whole editor and reads as a theme change. Several
other presets (`sidebar`, `vertical`, `select`, `vscode`) set `backdrop = false`
explicitly; `default` doesn't.

Also fixed while in there: the preview pane had `wrap = false` (Snacks' default, which
suits code previews), so prose body lines longer than the pane were cut off at the edge.

**Change** - `~/.config/nvim/lua/cheatsheet.lua`:
```lua
layout = {
  preset = "default",
  layout = { backdrop = false },
},
win = {
  preview = { wo = { wrap = true, linebreak = true } },
},
```
The override survives preset resolution because Snacks only skips preset merging when
your layout already defines a positional box (`layout.layout[1]`), which this doesn't -
so the preset is merged first and these overrides land on top
(`snacks/picker/config/init.lua:225-240`).

**Verified live**: window count dropped 7 -> 6 and the full-screen `rel=editor w=80
h=24` overlay is gone (explicit check for fullscreen editor-relative windows now
returns 0). Preview window confirmed `wrap=true linebreak=true`. Borders were already
rounded (`╭`) so they already matched the single-entry float - no change needed there,
confirmed rather than assumed.

## Follow-up: cheatsheet content deepened, with UI sketches (2026-09-23)

**What**: content expanded 525 -> **949 lines, 85 entries across 24 categories**. Every
entry that produces visible UI now carries a "What you see" sketch - what the screen
actually looks like when you press the key - rather than just naming the binding.
Examples: the `<lead>ghP` hunk popup (with its real `Hunk 1 of 3` header, taken from
gitsigns' own format string rather than invented), flash labels appearing over matches
for `gs`, the grep picker's two-pane layout, the completion menu, the bufferline, split
layouts, `:%s///gc`'s confirm prompt with what each key does, grug-far's before/after
list, gutter signs, `K` hover docs, which-key's popup, and before/after pairs for
`cw` vs `ciw`, autopairs, comments, formatting and `<C-a>`.

Sketches are labelled in the file header as representative, not pixel-exact, so nothing
here overclaims to be a literal screenshot.

**Parser hardening**: bodies now contain many fenced code blocks, and a `#` at the start
of a line inside one would previously have been parsed as a heading, silently splitting
or swallowing entries. The parser now tracks fence state and ignores headings inside
fenced blocks.

**Search quality fix (found by testing, not assumed)**: matching ran against
`title .. category` only, so searching **"hunk" returned zero results** - the git entries
were titled "Preview a change - popup", "Move between changes" etc. and never contained
the word. Tried including the whole body in the match text: that fixed "hunk" but
wrecked "find" (69 hits, wrong entry ranked first). Landed on matching
`title + category + the backtick-quoted key/command spans from the body` - keys become
searchable without dragging in prose noise - **and** renamed the vague git/autopairs
titles to contain the nouns people actually search for.

Measured before vs after:
```text
  query        before            after
  "hunk"       0 matches         6, top = Preview a hunk inline
  "ghP"        0 matches         1, exactly the right entry
  "gutter"     (n/a)             5, top = See changed lines in the gutter
  "ciw"        -                 12, top = cw vs ciw
  "replace"    5                 8, all Replace entries
  "find"       15                23, still all Find-ish at the top
```

**Change** - `~/.config/nvim/cheatsheet.md` rewritten;
`~/.config/nvim/lua/cheatsheet.lua` gains fence-aware parsing and a `key_terms()`
helper that extracts backtick spans for the match text.

**Verified live**: 85 entries / 24 categories parse correctly with the fenced blocks
intact (spot-checked the `<lead>ghP` entry's body end-to-end - mockup preserved
verbatim). Preview pane confirmed to render the sketch content. Backdrop still absent
(0 fullscreen windows) and preview wrap still on - checked for regressions rather than
assuming the earlier fixes survived the rewrite.

## Follow-up: cheatsheet completeness audited to 279/283 keymaps (2026-09-23)

**What**: asked whether the cheatsheet really covers everything. Rather than assert it
did, wrote a **coverage audit**: extract every backtick-quoted key from the doc, dump
every described keymap from the live editor (`nvim_get_keymap` across normal, visual,
insert and operator-pending), and diff them. Result went **205 -> 279 of 283** described
keymaps documented (98.6%) after filling the gaps it found.

**Two real bugs the audit exposed** (both were shipping, not just audit-side):

1. **Backtick-span extraction was corrupt.** Pairing backticks left-to-right breaks on
   any odd-count construct. The file has 70 ```` ``` ```` fence lines plus four
   double-backtick spans (used to write a literal backtick, e.g. the leader-backtick
   buffer switch). Each one shifts the pairing of every span after it - so
   `documented["<lead>bd"]` came back nil despite being in the file twice. The same
   flaw was in the shipped `key_terms()` in `cheatsheet.lua`, meaning the picker's
   search keywords were partly garbage. Fixed by stripping fenced blocks before
   extraction, and rewriting the four nested-backtick constructs to avoid nesting.
2. **Keys buried in fenced blocks aren't searchable.** A fenced ASCII table of
   `grn / gra / grr / ...` looks fine to a reader but is invisible to `key_terms()`, so
   typing `grr` found nothing. Converted those to inline bullet spans. Same treatment
   for the `[`/`]` bracket-pair targets.

**Content gaps it found and filled** (whole feature areas that were simply absent):
quickfix list, location list, the `[`/`]` paired-jump convention, treesitter
incremental selection (`<C-Space>`, `an`/`in`, `]n`/`[n`), flash in operator-pending
mode (`r`/`R`), `<C-s>` save, `gx` open-link-under-cursor, `<lead>K` keywordprg,
Lazy/Mason (`<lead>l`, `<lead>L`, `<lead>cm`), the profiler (`<lead>dp*`), highlight and
treesitter inspectors (`<lead>ui`, `<lead>uI`, `<lead>uT`, `<lead>sH`), the icons picker,
the full noice group, snippet jumping (`<Tab>`/`<S-Tab>`), Neovim 0.11+'s native LSP
family (`grn`/`gra`/`grr`/`gri`/`grt`/`grx`/`gO`), and the Vim defaults LazyVim keeps
(screen-line `j`/`k`, `&`, `Y`, visual `@`).

Content is now **1108 lines / 101 entries / 27 categories**.

**The 4 remaining are not real gaps**:
- `)` and a backtick in insert mode - mini.pairs' internal open/close actions, not keys
  you press deliberately; the Autopairs entry covers the behaviour
- `<lead>sn` - a which-key *group prefix* ("+noice"), not a command
- leader-then-backtick (Switch to Other Buffer) - documented in prose, but a key
  containing a literal backtick can't be written as a backtick span, so the audit can
  never match it

**Audit method, for repeating it later**: strip fenced blocks from the doc (fences
break span pairing), collect `` `spans` `` into a set, then for each described keymap
try several normalisations of its lhs - literal spaces are the leader, and the leader
can appear leading *or trailing* (`<C-W><space>` is the window hydra, `[<space>` adds a
blank line). Skipping the trailing case is what made the first run falsely report
`<C-w>`, `[`, `]` and `<lead><lead>` as undocumented.

## Follow-up: regex section added to the cheatsheet (2026-09-23)

**What**: added a **Regex & patterns** category (16 entries) - Vim's regex flavour
differs enough from PCRE to be worth real coverage. Content now **1259 lines / 116
entries / 28 categories**.

Covers: which flavour applies where, the four magic levels, very-magic `\v`, character
classes, quantifiers (including Vim's non-greedy `\{-}`), anchors and word boundaries,
`\zs` / `\ze` (Vim's answer to lookaround), groups/alternation/backreferences, the
replacement-side mini-language (`&`, `\1`, `\u`/`\U`/`\L`, `\=` expressions), the
`\n`-vs-`\r` newline gotcha, case sensitivity, live substitute preview, range limiting,
`:g` and `:v`, and a set of practical recipes.

**A genuinely setup-specific point worth recording**: patterns are *not* portable
between the two search paths here. `/`, `:s`, `:g` use **Vim regex**, while `<lead>sg`
grep and `<lead>sr` grug-far both shell out to **ripgrep** (Rust regex, PCRE-ish), where
`+ ? ( ) { } |` work bare. Verified from Snacks' own source
(`snacks/picker/source/grep.lua` builds an `rg` command).

**Every recipe was executed, not just written**: wrote a harness that runs each pattern
on a scratch buffer and asserts the resulting text. 20/20 passed - snake/camel case
conversion both directions, `\=submatch(0)+1` arithmetic, `\zs`, `\r` vs `\n`, non-greedy
`\{-}`, word boundaries, doubled-word detection, `\V`, `:g`/`:v`, `:g/^/m0`,
`:g/pat/normal`, `:g/pat/t$`, ranges.

**This caught a real error in my own text**: the recipe labelled "squeeze blank lines"
(`:g/^$/,/./-1d`) does not squeeze - it deletes blank runs **entirely**
(`a,'','','',b` -> `a,b`). The actual squeeze-to-one idiom is
`:%s/\n\{3,}/\r\r/g` (verified: -> `a,'',b`). Both are now listed with accurate labels.
Options documented in the case-sensitivity entry (`ignorecase`, `smartcase`,
`inccommand=nosplit`) were read from the live config rather than assumed.

Keymap coverage re-checked after the addition: still 279/283, no regression.

## Follow-up: 12 more cheatsheet categories, and a real gq/gw discovery (2026-09-23)

**What**: asked whether other whole categories were missing the way regex had been. The
keymap audit couldn't answer that - it only checks keys, and a category like regex is
mostly `:` commands and syntax. Reviewed the surface area by hand and found twelve
genuine gaps, all now added. Content is **1554 lines / 141 entries / 40 categories**.

Added: visual & block editing (`<C-v>` column edits, `g<C-a>` numbering), the Ex command
line & shell (ranges, `q:`, `:!`, `!{motion}` filters, `:sort`), folding, insert-mode
tricks (`<C-r>{reg}`, `<C-o>`, digraphs), command-line editing (`<C-r><C-w>`), `gn`/`cgn`
repeatable changes, the remaining operators (`gU`/`gu`/`g~`, `=`, reflow), diff mode,
spell checking, undo time travel (`:earlier`, `g-`), terminal mode, and config/health
(`:checkhealth`, `:verbose set opt?`, `:LazyExtras`, where each config file lives).

**Auditing the modes I'd skipped also paid off**: the original coverage audit only
looked at normal/visual/insert/operator-pending. Checking terminal and command-line
modes surfaced that `<C-/>` is still bound **inside** a terminal buffer (it closes the
terminal) even though we took that key for comments in normal/visual mode - a genuinely
useful detail, now documented.

**A real behavioural discovery, found by testing rather than assuming**: `gq` does
**not** reflow text in this setup. LazyVim sets `formatexpr` globally to
`v:lua.LazyVim.format.formatexpr()`, so `gq` delegates to conform/LSP **code
formatting** instead of wrapping paragraphs. Measured with `textwidth=60` on a 150-char
line:

```text
  gqq  ->  1 line, 150 chars   (unchanged - ran the code formatter)
  gww  ->  3 lines, 59 wide    (actual reflow)
```

`gw` always uses Vim's internal formatter and ignores `formatexpr`, so **`gw` is the
one to use here**. With `formatexpr` cleared, `gq` wraps at 79 with `textwidth=0` as
vanilla Vim would - confirming the cause rather than guessing. My first draft of that
entry recommended `gq`, which would have been wrong; the entry now leads with `gw` and
explains why.

**Everything testable was executed**: `:sort` / `sort u` / `sort n` / `sort!`, `%!sort`
shell filtering, `:r !cmd`, `gUiw` / `guu` / `g~~`, `cgn` followed by `.`, visual-block
`I` insert, `g<C-a>` column numbering, `zc` folding with `foldmethod=indent`, and `=G`
re-indent (checked on a real `.cpp` buffer in the full config, since a bare `-u NONE`
session has no indent plugins and would have shown a false negative).

Keymap coverage re-checked afterwards: still 279/283, no regression.

## Follow-up: cheatsheet moved from `g?` to `<leader>h` (2026-09-23)

**What**: asked to move the cheatsheet off `g?`. Tried `??` first; reported as not
working - `?` still opened backward-search instantly. No mechanism for that was ever
found (`?` has no competing mapping, `timeout` is on, `timeoutlen` is 300ms, and the
`??` mapping registered correctly), and the symptom matches Neovim not having reloaded
the config, since keymap changes need a restart. Moved to **`<leader>h`** instead.

**A probe bug worth recording, because it produced a confidently wrong answer**: several
of these availability checks used `nvim_replace_termcodes("<lead>...")`. **`<lead>` is
not a real keycode** - it passes through as the literal string `"<lead>h"`, so *every*
leader key it tested came back "free", including ones that are definitely taken. That is
what made `<leader>?` appear unclaimed on a re-check and briefly contradict the earlier,
correct finding that it is LazyVim's "Buffer Keymaps (which-key)" binding. The correct
spelling is `<leader>`, which resolves to a literal space:

```text
  nvim_replace_termcodes("<lead>h")   ->  "<lead>h"   (unresolved, useless)
  nvim_replace_termcodes("<leader>h") ->  " h"        (correct)
```

Re-verified with the right spelling: `<leader>?` is **taken** (Buffer Keymaps),
`<leader>h` is **free**, and nothing is nested under `<leader>h`. Also grepped LazyVim's
source directly rather than relying on the runtime probe alone: core binds nothing under
`<leader>h`; only the `harpoon2` **extra** uses it, and that extra is not enabled here.
Noted in the keymap comment as the one thing that would force a move later.

**Change** - `~/.config/nvim/lua/config/keymaps.lua`: `g?` -> `<leader>h`. The comment
now records the full key history (why not `?`, `<leader>?`, `g?`, `??`) so this doesn't
get relitigated. Cheatsheet content updated in both places it named the key.

**Verified live**: `<leader>h` resolves to `desc = "Cheatsheet"`, feeding the keys opens
the picker (5 floating windows), and `g?` / `??` are both released - `g?` is back to
native ROT13. 142 entries still parse.

## Follow-up: edit entries in place, restore the original (2026-09-24)

**What**: the cheatsheet can now be edited from the picker, one entry at a time, and
restored to the original at any point, discarding every edit however old.
- `<C-e>` (picker) / `e` (single-entry view): edit the selected entry in a small float;
  `:w` writes only that entry back.
- `<C-x>` (picker): asks, then deletes the user's copy - back to the original.
- `<C-o>` (picker): edit the selected entry in the original itself (changes what a
  restore brings back).

**Why**: asked for an edit option plus a restore-to-default that survives months/years
of edits; then refined to "edit just that part, no need of opening the entire file"
(e.g. search `ciw`, fix the `cib`/`ciB` lines in that entry only).

**Decisions** (asked): user copy lives at `~/.config/nvim/cheatsheet.user.md`, next to
the original, so it can be backed up here too; keys `<C-e>`/`<C-x>`/`<C-o>` (all free in
Snacks' picker - checked against its default `win.input/list` keys; `<a-r>` was
initially offered and turned out to be taken).

**Design**:
- `cheatsheet.md` is the original and `<C-e>` never touches it. The first `<C-e>` copies
  it to `cheatsheet.user.md`; the picker shows the copy whenever it exists (title
  "Cheatsheet (your copy)").
- The parser now records each entry's line range (`###` heading to last non-blank line)
  and identity (category + title + occurrence number for duplicates). Saving re-reads
  the file and re-finds the entry by identity, not by stored line numbers, so edits
  elsewhere in between can't cause the wrong lines to be replaced.
- Edit buffer is `buftype=acwrite` with a `BufWriteCmd` that splices the lines in.
  First line must stay a `### ` heading (else refused); renaming the title is fine; an
  emptied buffer deletes the entry after a confirm; extra `###` lines become new entries.

**Bug caught in testing**: first version used `bufhidden=wipe`. With `'hidden'` on
(Neovim's default), a plain `:q` on an edited-but-unsaved window closed it and wiped
the buffer - edits silently lost. Switched to `bufhidden=hide` (verified: `:q` keeps the
edits hidden, `:q!` unloads/discards) plus one deterministically-named buffer per entry,
so reopening an entry brings unsaved edits back; unmodified buffers are deleted on
`BufHidden`. Handlers are registered only when the buffer is created, else a reopened
buffer would save twice per `:w`.

**Change**: `~/.config/nvim/lua/cheatsheet.lua` (rewritten; copy in
[`files/`](files/.config/nvim/lua/cheatsheet.lua)). `~/.config/nvim/cheatsheet.md`: "This
cheatsheet" category now has How to use it (new keys), How to edit it, Restore the
original, Edit the original itself, File format; "Where the config lives" lists
`cheatsheet.user.md`.

**Verified live** (headless, forced `VeryLazy`, real files backed up and restored
afterwards, no test copy left behind): the three keys are bound in the picker input;
first edit creates the copy and the original's checksum is unchanged; `diff` original vs
copy shows only the added line; `:q` with unsaved edits leaves the file untouched and
reopening restores them; one `:w` writes once; title rename + a second save land on the
renamed entry; heading removal is refused; emptying + `:w` deletes the entry; `e` from
the entry view opens the editor; `<C-o>` edits land in the original only; `<C-x>`
removes the copy and the title reverts to "Cheatsheet"; unmodified edit buffers are
cleaned up after `q`. 157 entries parse.

**Notes**:
- New entries added to the original later don't propagate into an existing copy - a
  restore picks them up but loses the edits.
- `cheatsheet.user.md` doesn't exist yet. Once it does, it's a real dotfile worth storing
  in `files/` alongside the original (rule 7) - copy it whenever a session touches nvim.

## Follow-up: user's copy now exists and is stored here (2026-09-25)

`~/.config/nvim/cheatsheet.user.md` was created by the user on 2026-09-24 (first `<C-e>`
edit). Their one edit so far: the bracket text-objects line in "Text objects" now reads
`` `i(`/`ib`, `i[`, `i{`/`iB` `` plus a new `` `i<`, `i>` `` line. Stored in
[`files/`](files/.config/nvim/cheatsheet.user.md) from now on - re-copy whenever it
changes.

**Adding new entries while a copy exists**: the picker reads the copy, so a new entry
added only to the original is invisible (the tradeoff noted above). First real case: the
signature-help entry (see [[languages-and-lsp]]). Handled by inserting the identical
entry into the copy at the same spot - purely additive, the user's own edit untouched;
`diff` original vs copy afterwards shows only the user's edit. Do the same for future
entries rather than asking the user to restore (which would discard their edits).

## Follow-up: "Word wrap & long lines" category (2026-09-25)

**What**: user pointed out the cheatsheet should cover Vim features generally, and word
wrap was missing - only a one-line `<lead>uw` toggle and the `gw` hard-reflow entry
existed. Audit found none of `gj`/`gk`/`g0`/`g$`/`gm`, `linebreak`/`breakindent`/
`showbreak`/`colorcolumn`, or `zh`/`zl`/`zs`/`ze` anywhere. Added a category (5 entries,
placed before "Folding"): turn wrap on/off, moving through wrapped lines, nicer-looking
wrapping, long lines with wrap off, hard wrap at a width. Inserted identically into the
original and the user's copy (additive; user's edit untouched). 163 entries now.

**Facts checked live before writing** (not from memory): LazyVim sets `wrap=false`,
`linebreak=true`, `sidescrolloff=8`; its `wrap_spell` autocmd turns wrap+spell on for
text/plaintex/typst/gitcommit/markdown (confirmed on a `.txt`: `wrap=true spell=true`);
`j`/`k` are mapped to `v:count == 0 ? 'gj' : 'j'`; `<leader>uw` is "Toggle Wrap";
`formatoptions=jcroqlnt` includes `t`, and with `textwidth=20` typing a long sentence
broke it at 20; `gM` lands mid-line.

**Not done**: a full coverage audit against all of Vim's features - offered.

## Follow-up: full coverage audit against Neovim + every plugin (2026-09-26)

**What**: asked for the cheatsheet to cover everything Neovim and the installed plugins
offer, not just what came up in conversation. Previous audits only compared keymaps
that carry a description (279/283) plus a hand review of categories - which is how
basics like marks, `ZZ`, `ge`, `gf` and the whole `<C-w>` family were never noticed.
Now **2714 lines / 227 entries / 46 categories** (was ~1940 / 163).

**Method** - [`cheatsheet-audit.lua`](cheatsheet-audit.lua) (kept, re-runnable) diffs
the doc's backtick spans (fences stripped) against:
1. Neovim's own `$VIMRUNTIME/doc/index.txt` - every built-in key and Ex command, by mode
   (aliases described as "same as …" skipped)
2. every described keymap live in a `.cpp` buffer, global and buffer-local, all modes
3. every user command (`nvim_get_commands`, global + buffer)
4. keys *inside* plugin windows: Snacks picker input/list, the explorer, blink's preset,
   grug-far's keymaps, the Lazy UI

**Before → after** (built-in index items not mentioned): insert 50 → 9, normal 47 → 24,
window 43 → 7, `[`/`]` 28 → 2, `g` 25 → 1, `z` 20 → 2, visual 17 → 4, cmdline 17 → 4,
Ex commands 456 → ~100. Plugin commands ~90 → 16, in-window keys ~70 → 14. Everything
left was checked by hand and is a matcher artefact, not a gap: keys containing a
backtick (can't be written as a span), punctuation commands (`:!` `:&` `:<`), commands
written as abbreviations or shorthand (`:Ex`, `BufferLineCloseLeft` / `Right`), grug-far
keys written `\r` rather than `<localleader>r`, and families covered by a stated rule
(every `:c…` quickfix command has an `:l…` twin; `s…` = in a split; `…rewind` = `…first`;
menu/Vimscript/provider commands named in "Everything else, briefly").

**Added**: new categories *Saving & quitting*, *Tags & include search*, *Ex commands
reference* (lines, many-places, arglist, lookups, options, abbreviations/mappings,
sessions, build/grep, help, rarely needed, everything else); plus entries across
existing ones - `<C-w>` keys, more motions/marks/change list, replace mode, around
objects, every register, macro extras, select mode, manual folds, built-in insert
completion, cmdline editing, spell/diff/quickfix/undo/recovery/terminal commands, picker
and explorer keys, grug-far keys, gitsigns/noice/mason/lazy/treesitter/blink/matchit/
netrw commands, status line, mouse, start screen, Snacks' automatic behaviours.

**Errors in the existing content, found by checking the live setup** (all fixed):
- Clipboard entry said plain `y` stays internal - false: LazyVim sets
  `clipboard=unnamedplus` locally, so every yank/delete (except the custom `x`) reaches
  the system clipboard; `<lead>y` only matters over SSH.
- Digraph entry (`<C-k>a:`) only works without an LSP: in code, insert `<C-k>` is
  LazyVim's Signature Help. Verified both ways.
- Folding entry said `foldmethod=indent`; C++ buffers actually use
  `expr` + `vim.lsp.foldexpr()`, and `zf` there fails with E350 (documented the
  `:setlocal foldmethod=manual` workaround).
- Autocomplete entry said the menu appears automatically (off by default since
  2026-09-23) and that `<Tab>` accepts (blink's `enter` preset: `<Tab>` is snippet-jump;
  accept is `<CR>` / `<C-y>`).
- Visual `gq` listed as reflow - it runs the code formatter here (`gw` reflows).
- Spell said "off by default" - LazyVim's `wrap_spell` autocmd turns it on for
  markdown/text/gitcommit.
- Customizations summary was missing this week's changes (`<C-BS>`, diagnostics /
  autocomplete / signature defaults, `~/.clang-format`, cheatsheet edit keys).

**Setup-specific facts checked before writing, not assumed**: `H`/`L` are buffer
switching (only `M` is native); `[[`/`]]` are LSP references in code buffers;
`<C-]>` goes through `tagfunc=vim.lsp.tagfunc`; `lazygit` isn't installed so LazyVim
never maps `<lead>gg`/`gG`; `tohtml` is disabled in `lazy.lua` (so no `:TOhtml`);
Neovim 0.12 replaced `:LspInfo`/`:LspRestart` with `:lsp restart|stop|enable|disable`
and `:checkhealth vim.lsp`; `:Nex` resolves to built-in `:Next`, not `:Nexplore`;
Snacks explorer has `replace_netrw` on (`:e .` opens it); bigfile threshold 1.5 MB;
`completeopt` has `noselect`, so built-in completion needs `<C-n>` before `<C-y>`.

**Verified**: every `:command` named in the final doc exists (`exists()`; 477 checked,
abbreviations resolved with `nvim_parse_cmd`); 30 key sequences executed with asserted
results (`:t.`, `:m0`, `:%norm`, `gJ`, `]p`, `g??`, `Q`, `d2i(`, `ci"` from outside,
`/foo/e`, `/foo/+2`, `[(`, `]}`, `g;`, `gF` with `:line`, insert `<C-a>`/`<C-y>`,
`<C-x><C-l><C-n><C-y>`, manual `zf`, `:=`, `<C-w>s`/`<C-w>o`, visual `g<C-x>`, `:uniq`,
`:~`, `!!`, `:filter`, `:foldd`, `:folddoc`, `zy`/`zp`); picker search text contains the
new keys. Edits went into both the original and the user's copy through anchored,
all-or-nothing scripts; `diff` afterwards still shows only the user's own edit.

## Follow-up: audit made exact - 0 real gaps (2026-09-26)

**What**: user questioned the "after" numbers (insert 9, normal 24, Ex ~100 …) - were
that many things still missing? Hand-classified every remaining item: ~20 were real
(all obscure) and the rest were matcher blind spots. Added the real ones and rewrote
[`cheatsheet-audit.lua`](cheatsheet-audit.lua) so its count means what it says.

**Real gaps added**: `z+` / `z^`, `?` then `<CR>`, `[`/`]` + backtick (in words),
`<C-\><C-n>` / `<C-\><C-g>` from any mode, `<C-x><C-s>` spelled out, `:norea`, `:ca` /
`:cabc`, `:ptn`/`:ptp`/`:ptf`/`:ptl`, `:dl`, `:gvim`, `:prev` / `:wp`, the long names
`:chdir`/`:lchdir`/`:tchdir`, full names of every `:BufferLine…` command
(Cycle/Move/Group/Close/SortBy…), netrw's full names (`:Explore` …), and `<CR>` in
grug-far's history window.

**Matcher fixes** (each was producing false "missing" lines):
- Ex commands resolved with `vim.fn.fullcommand()` (falls back to `nvim_parse_cmd`) -
  handles abbreviations like `:Ex` and command **modifiers** (`:abo`, `:vert`, `:sil`,
  `:noa`, `:keepj`), which `nvim_parse_cmd` rejects without a following command.
- Punctuation commands (`:!` `:&` `:<` `:@` `:~` `:2match`) matched literally.
- Families the doc covers by a stated rule: `:l…` twins of documented `:c…`, `…N` =
  `…previous`, `s…` split forms, `…rewind` = `…first`, `:pt…` preview twins, menus,
  `…mapclear`, Vimscript `end…`, provider `…do` / `…file`.
- Plugin notation: `<localleader>` → `\`, `<Space>` → leader, `<enter>` → `<CR>`;
  which-key group prefixes (`+noice`) skipped.
- An explicit **ALLOW** table for what can only be written in words (keys containing a
  backtick - can't be a span) or shorthand (`<C-w>h` `j` `k` `l`), each with where it's
  covered. The script prints this list separately (49 items) - nothing hidden silently.
- `CHEATSHEET=path` env var to audit any file (defaults to the user's copy).

**Result**: 0 missing in every area - built-in index (all modes + Ex), described
keymaps, user commands, in-window plugin keys. **Negative test** (so 0 isn't just a
lenient matcher): with the "Saving & quitting" category deleted from a scratch copy,
the audit flagged 16 of its items (`ZQ`, `g<C-g>`, `:wa`, `:sav`, `:up`, `:x`, `:wq`,
`:wqa`, `:checktime`, `:pwd`, `:cd`/`:lcd`/`:tcd` and long forms, `:f`); the rest
(`ZZ`, `:qa` …) are also documented elsewhere. Now 2735 lines.

## Follow-up: user's bracket edit adopted into the original (2026-09-26)

The user's own edit (made 2026-09-24 in `cheatsheet.user.md`) is now in the original
`cheatsheet.md` too, on request - it's clearer: the old line listed `i(` `i[` `i{` and
then "(also `ib` / `iB`)", leaving unclear which two of the three the aliases belong
to. Now:
```text
- `i(`/`ib`, `i[`, `i{`/`iB` - bracket contents
- `i<`, `i>` - angle bracket contents
```
After this, `diff` shows the original and the user's copy identical.

## Follow-up: "Default:" lines - how to make each setting permanent (2026-09-26)

**What**: asked whether the cheatsheet says, per setting, which line to change/add to
change its default, and whether the value is a number or boolean. It didn't (only
general "put it in options.lua" pointers). Offered three layouts - a separate
"Changing defaults" category, a line inside each entry, or both - and the user chose
**inside each entry**: that's where they'd look, and a separate category would
compete with the real entry in every search.

**Change**: 24 entries (both files) end with a `Default:` line giving the exact line,
the file, the value type (true/false, a number, text in quotes, with what the values
mean) and the current value. Covered: wrap, breakindent/showbreak, sidescrolloff,
textwidth/colorcolumn, every `<lead>u` toggle (numbers, spell, diagnostics, inlay
hints, conceal, indent guides, smooth scroll, animations, background, colorscheme;
zen/zoom/dim/notifications noted as one-off actions), autocomplete, ghost text,
signature popup, autopairs, format on save, ignorecase/smartcase, inccommand,
clipboard, foldlevel, spell/spelllang, mouse, scrolloff, indent width/expandtab
(+ `~/.clang-format`), splitbelow/splitright, undofile/undolevels, swapfile,
timeoutlen, laststatus, bigfile size.

**How each is stored was read from source, not assumed**: LazyVim's `<lead>u` toggles
are mostly plain options, but autoformat and animations are `vim.g.autoformat` /
`vim.g.snacks_animate`, autopairs is `vim.g.minipairs_disable`, inlay hints are the
nvim-lspconfig `opts.inlay_hints.enabled`, indent guides / smooth scroll / bigfile are
Snacks opts (a new `lua/plugins/snacks.lua`, following the one-file-per-plugin
convention).

**Verified**: copied the whole config to a scratch `XDG_CONFIG_HOME`, wrote every
proposed line there with a non-default value, and started Neovim on a `.cpp` file with
clangd: **41/41 checks passed** - every option read back as set, `LazyVim.format.
enabled()` false, blink/ghost-text/noice/inlay/Snacks states flipped, typing `(` no
longer auto-closed with autopairs disabled. Confirmed LazyVim's `wrap_spell` autocmd
still forces wrap+spell on in markdown/text regardless (said so in those entries).
Real config untouched by the test. 227 entries parse; coverage audit still 0 missing.

## Follow-up: "Only 24?" - Default lines made complete, audit case bug (2026-09-26)

**What**: user questioned whether 24 entries with a `Default:` line was really all.
It wasn't - the 24 had been picked by reading, not by a systematic check. Now **43**
entries have one, and the audit checks it.

**Found by a systematic pass** (every entry that uses a real option name as a setting,
a `<lead>u…` toggle, or says "by default"; noise hand-classified): diagnostics (in the
Diagnostics category), treesitter colouring (`<lead>uT`), `textwidth` in the reflow
entry, `spelllang`, case sensitivity (regex), `gdefault`, manual folds, `undofile`,
`completeopt`, autocomplete in the menu entry, per-language `commentstring`,
`keywordprg`, `hlsearch`, `path` (for `:find`). Plugin settings (patterns can't see
them - they're described in words): picker + explorer hidden/ignored files, gitsigns
line blame, flash in `/` search, bufferline always shown, which-key delay, LeetCode
language.

**A wrong line of mine, corrected**: "Discover any keybinding" said `timeoutlen`
controls when the key list appears. which-key v3 has its own `opts.delay`
(`ctx.plugin and 0 or 200`); `timeoutlen` only governs how long Vim waits for the
rest of a multi-key mapping. Entry now gives both.

**Two defaults need more than one line (found by testing, not assumed)**:
- `vim.opt.foldmethod = "manual"` alone is overridden when clangd attaches - LazyVim
  sets LSP (and treesitter) folds. Needs `folds = { enabled = false }` in the
  nvim-lspconfig opts (clangd.lua) and `opts.folds = { enable = false }` in the
  treesitter opts function (languages.lua) as well.
- Treesitter highlighting off (`opts.highlight = { enable = false }`) works for files
  opened later, but Snacks **quickfile** colours the file named on the command line
  before plugins load - also needs `quickfile = { enabled = false }`.

**Audit bug found and fixed**: `norm()` lowercased whole keys, so `<lead>uA` counted as
`<lead>ua`, `gV` as `gv`, `zX` as `zx`, etc. Now only text inside `<…>` is
case-folded. That exposed real gaps, all added: `<lead>uA` (tab line), `<lead>uG`
(git signs), `<lead>fB`, `<lead>sR`, `[A`/`]A`, `[T`/`]T`, visual `[N`/`]N`,
`<C-w>F`/`<C-w>gF`/`<C-w>P`, `gV`, `gQ`, `{n}go`, `zX`, `zuW`/`zuG`, insert `<C-g>U`.

**Audit section 5** (new): entries that describe a setting without a `Default:` line.
Pattern detection (full option names used as settings, `<lead>u` toggles, "by
default" / "starts **off**") plus an `EXPECT_DEFAULT` list of the 43 titles that have
one - plugin settings are written in words the patterns can't match, so a lost line
is caught by name. `ALLOW_ENTRIES` covers entries that only mention an option as an
example. **Negative test**: removing the wrap and signature-help Default lines from a
scratch copy is flagged for both (pattern-only detection had caught just wrap).
New entries about a plugin setting still need judgment when written.

**Verified**: every new default line tested in a scratch `XDG_CONFIG_HOME` copy on a
`.cpp` file with clangd (11 + fold/highlight combos + `path`), all passing. Real file:
0 in every audit section; 227 entries parse; both cheatsheet files identical.

## Follow-up: per-picker keys and explorer file operations were missing (2026-09-28)

**How they were missed**: audit section 4 only read keys **shared** by every picker
(plus the explorer), and matched them against spans anywhere in the doc. Keys defined
on one picker (the marks picker's `<C-x>`) were never read, and single-letter or
common keys (`a` `d` `r` `c` `m` `y` in the explorer, `<C-x>`) were "found" in
unrelated entries (`<C-x>` = decrement / restore). The explorer entry had **no file
operations at all** as a result.

**Added** (both files): marks picker `<C-x>`, `dm{mark}` / `dm-` [custom], `:delm`,
and that marks show left of the line number; buffers `<C-x>` / `dd`; git status and
git diff `<Tab>` stage / `<C-r>` restore; git branches (no key: `:lua
Snacks.picker.git_branches()`, `<C-a>` / `<C-x>`); keymaps `<M-g>` / `<M-b>`; undo
`<C-y>` / `<C-S-y>`; scratch `<C-n>` / `<C-x>`; projects `<C-f>` `<C-g>` `<C-r>` `<C-e>`
`<C-w>` `<C-t>`; GitHub lists `<M-b>` / `<C-y>` / `y` and PR diff `a` / `<CR>`; new
entry "File operations in the explorer" (`<CR>`/`l`, `h`, `a` with `/` for folders,
`r`, `d` → trash via `gio` after a confirm, `c`, `m` (moves marked, else renames),
`y`, `p`, `<Tab>` multi-mark, `o`, `u`) - behaviour read from Snacks' action source.

**Audit section 6** (new): every Snacks source's own keys (`win.input/list/preview`)
must appear as a span **inside the entry for that picker** (mapped in `PICKER_MARK`);
a source with keys but no mapped entry is reported. **Negative test**: against the
cheatsheet from before this fix it flags 40 keys, including marks `<C-x>` and all
explorer operations; the current file reports 0 in all six sections.

## Follow-up: exact-key search - typing `s` finds the `s` entry first (2026-09-28)

**What**: user couldn't find `s` / `S` after flash moved back. The entry existed, but:
- searching `flash` didn't match it at all - the picker searches title + category +
  key spans, and "Flash" was in none of them (title was "Jump to any visible spot
  on screen");
- searching `s` ranked it **74th** - a one-letter fuzzy query matches ~220 entries,
  and any short key (`x`, `u`, `gd`) has the same problem.

**Change** - `lua/cheatsheet.lua` (copy in [`files/`](files/.config/nvim/lua/cheatsheet.lua)):
each item carries `keys`, the exact set of its key spans (plus leader keys without
the leader, `<lead>sm` → `sm`, and spelled `<leader>sm`); a custom `sort` puts items
whose `keys` contain the query **exactly** first (case-sensitive, so `s` ≠ `S`), then
the normal fuzzy score, then file order. `key_terms()` now returns a list. The entry
is retitled "Jump anywhere on screen - Flash (s / S)" (both files).

**Verified** in the real picker (`input:set()` + `find()`; feedkeys don't reach a
headless picker mid-script): `s`, `S`, `flash` → the Flash entry first (was 74th /
not found); `sm` → marks; `dm` → Marks; `x` → "Delete, change, yank"; `gd` → "Go to
things"; `wrap` → the wrap entries.

## Follow-up: Surround category, LazyExtras entry, current-vs-default notes (2026-09-28)

**What**: added a **Surround** category (5 entries) for the `coding.mini-surround` extra enabled in [[keybindings-and-editing]], plus a new "Turn LazyVim extras on and off" entry, and notes in the Flash, Autopairs, `:LazyExtras` and Customizations entries. Asked for: every surround key mentioned, and for each one both this setup and the defaults. Now **234 entries**.

- *Add / Delete or change / Next-previous-find-highlight*: `gsa`, `gsd`, `gsr`, `gsf`/`gsF`, `gsh`, the `n`/`l` suffixes, `b`/`q`/`t`/`f`/`?` targets, `.` repeat, the `)`-tight vs `(`-spaced rule. Every example was run live in headless Neovim before writing it down (results pasted as the "What you see" boxes).
- *Surround keys: this setup vs defaults*: here (`gs*`, LazyVim) vs mini.surround's own `sa`/`sd`/`sr`/... vs vim-surround's `ys`/`yss`/`ds`/`cs`/visual `S` vs stock Vim (none; `gs` = sleep), why vim-surround keys weren't adopted, and the `opts.mappings` snippet to switch.
- *Surround without the plugin*: `ciw"<C-r>""<Esc>` by hand; Vim's auto-pairs Fast Wrap (`<M-e>`).
- *Turn LazyVim extras on and off*: `:LazyExtras` + `x`, `●`/`○`, section order, `lazyvim.json`, `:Lazy clean` not removing out-of-tree leftovers (`~/.supermaven`), default (no extras) vs now (mini-surround only), and the five extras once enabled by mistake.

**Found while testing**: `gsn` ("Update n_lines") is still mapped by LazyVim's extra spec but current mini.surround dropped the action - pressing it does nothing. Documented rather than worked around; `n_lines` stays at its default 20.

Both `cheatsheet.md` and `cheatsheet.user.md` got identical edits (they were identical before). The stored [`files/`](files/.config/nvim/cheatsheet.md) copy was re-synced - it had been ~1,300 lines behind from earlier unrecorded cheatsheet edits, so that sync pulls those in too.

## Follow-up: numbers entry, and why it couldn't be found (2026-09-30)

**What**: asked why increment/decrement wasn't in the cheatsheet. It was - `<C-a>`/`<C-x>` as one bullet in "Repeat and small operators", `g<C-a>`/`g<C-x>` split over two visual-mode entries - but the picker only searches **titles, categories and backtick keys**, never body prose (by design, see the 2026-09-23 search follow-ups), and no title said "number"/"increase"/"increment". `<C-a>` itself is in 8 entries. Added **Editing > "Increase or decrease numbers (increment / decrement)"**; the old bullet now points to it, and "Number a column automatically" links it. Now **235 entries**; "increase", "increment", "decrease" each hit only the new entry.

**Content** (every example run live first): counts, `.` repeat, visual `<C-a>`, `g<C-a>`/`2g<C-a>`/`g<C-x>` sequences, hex/binary, and current-vs-default for everything:
- keys: not remapped in Neovim (stock); `~/.vimrc` adds `<leader>+`/`<leader>-` aliases (not in Neovim - `<leader>-` is LazyVim's split).
- `nrformats`: Neovim `bin,hex` (default, not set). Vim with this `.vimrc` is `bin,octal,hex` - a vimrc stops `defaults.vim` loading, which is what normally drops `octal` - so `007` → `010` in Vim vs `008` in Neovim.
- `item-5` → `item-4` gotcha: `blank` in `nrformats` fixes it and keeps `x = -3` working; `unsigned` fixes it but breaks real negatives (`-3` + 5 → `-8`). Documented only, not enabled.
- LazyVim `editor.dial` extra (off) as the smarter option: booleans, `&&`/`||`, dates, weekdays, hex colours, semver, markdown checkboxes.

## Follow-up: commenting many lines at once (2026-10-04)

**What**: asked whether the cheatsheet covers commenting every line that matches a pattern / prefixing lines with `//`. Only fragments existed (a macro doing `I// `, block-insert `I # `, `:g/pat/normal A;`) - nothing findable. Added **Comments > "Comment out many lines: matching a pattern, a range, a selection"** and a `:g/pat/norm gcc` line in the `:g`/`:v` recipes. Now **236 entries**.

All tested live in a C++ buffer first: `:g/TODO/norm gcc`, `:v/TODO/norm gcc`, `:5,20norm gcc`, `norm I// ` (after indent) vs `s#^#// #` (column 0), visual-range forms, and the `:%s#^\(\s*\)// #\1#` uncomment. Two gotchas documented: `:norm!` does nothing (in Neovim `gcc` is a built-in *mapping*; `!` skips mappings), and `gcc` toggles, so already-commented matches get uncommented - use `norm I// ` then. Current vs default: `gc`/`gcc` are Neovim's own (0.10+), same as stock LazyVim; Vim gets them from vim-commentary.

**Note**: `cheatsheet.md` and `cheatsheet.user.md` differ by one pre-existing edit (a 2026-10-02 session changed the Ctrl+Backspace line in the original only). The picker shows the user copy, so that change isn't visible there. Left as-is; the new entry went into both identically.

## Follow-up: "Batch edits on many lines" category (2026-10-04)

**What**: asked for more recipes like the comment-many-lines one. Added a **Batch edits on many lines** category (6 entries, after Regex & patterns) for the gaps not already in "Practical recipes" / the `:g` entry, which now points to it. Now **242 entries**.

- *Prefix or append text on many lines*: `:%norm A;`, `:'<,'>norm A,`, `:%s/$/,/`, `:g/pat/norm I- `, `:5,20s/^/    /`, pointer to block `$A`.
- *Change only the lines that match*: `:g/pat/s/old/new/g`, `norm gUU`, `:g/pat/>` / `<`, `norm @q`, `exe "norm \<C-a>"`.
- *Copy, collect, duplicate, space out*: `call setreg('a', []) | g/pat/y A` (the usual `qaq` leaves a stray leading blank line - tested), `:let @+ = @a`, `t$`/`m0`, `:g/^/t.`, `put _`.
- *Join in bulk*: `:g/pat/j`, `:g/^/j` (pairs), `:'<,'>j!`.
- *Number, de-duplicate, sort, align*: `\=line('.')` numbering (whole file and selection-relative), `:%!awk '\!seen[$0]++'` (order-keeping dedupe; `\!` needed or Vim expands `!` to the previous command), `:sort u`/`n`, `:'<,'>!column -t`.
- *Delete part of every line*: `:%s/\s*#.*//e`, `:%s/^\s\+//`, `:%norm dw`, `:%norm f#D`, `\v` field swap.

Every recipe run live in headless Neovim first. All stock Vim - each entry says so (same in stock LazyVim and Vim). First title "Add text to ..." found nothing for "append", so it was renamed "Prefix or append text on many lines (start or end)".

## Follow-up: tab-page numbers explained (2026-10-04)

**What**: asked what the numbers at the top right are. They are bufferline's tab-page indicators (stock LazyVim, `show_tab_indicators`), shown once 2+ tab pages exist; the left part is buffers. Retitled the entry "What a tab is here (the numbers at the top right)" and added a sketch, `gt`/`gT`/`2gt`, closing tab pages, and the stock-vs-current note (unchanged; `<leader>uA` toggles the bar).
- 2026-10-04: "Create, close, switch tabs" now also lists every way to open one (`:tabe`, picker `<C-t>`, `<C-w>T`, `:tab {cmd}`) - they were spread over four entries.
- 2026-10-04: tab entry explains why a new tab page shows its `[No Name]` buffer in every tab (buffers are global; bufferline lists all of them) - tested: `:e` reuses the empty buffer, `:tabe {file}` never creates it.
- 2026-10-04: tab entry rewritten for per-tab buffers (scope.nvim, see [[keybindings-and-editing]]); "Plugins added" lists it.
- 2026-10-04: explorer entry gets `t` (new tab page); the three "create `lua/plugins/snacks.lua`" hints now say "add to" since the file exists.

