# Personal cheatsheet (`<leader>h`)

**Category:** neovim
**Files touched:** `cheatsheet.md`, `lua/cheatsheet.lua`, `lua/config/keymaps.lua` (all under `~/.config/nvim/`; copies in [`files/`](files/))

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

## Catch-up: in-picker editing with a separate user copy (found 2026-10-04)

The stored `lua/cheatsheet.lua` was ~380 lines behind the live file: an earlier, unrecorded session added **editing from the picker**. `<C-e>` (or `e` in an entry) edits one entry in a float, saved with `:w`. The first edit copies `cheatsheet.md` to `cheatsheet.user.md`, which the picker then shows. `<C-x>` deletes the copy (after asking) to restore the original, and `<C-o>` edits the original itself. Entries are matched by category + title + occurrence, not by line number. The behaviour is documented in the cheatsheet's own "This cheatsheet" category; the stored copy is current now.

Consequence worth knowing (bit us on 2026-10-04): a change made only to `cheatsheet.md` is invisible in the picker while `cheatsheet.user.md` exists. A 2026-10-02 session updated the Ctrl+Backspace line in the original only, so the copy kept describing a `<C-BS>` mapping that `keymaps.lua` no longer has. Fixed by syncing the copy from the original (the only difference). **Edit both files, or the copy, from now on.**
- 2026-10-04: buffer entries updated for per-tab buffers - "Switch between buffers" says `H`/`L`/`<leader>,` cover only the current tab page and `<leader>fB` opens a pick in the current tab (no jump); "List buffers" adds `:ls!` for all tabs. Also synced `cheatsheet.user.md` from `cheatsheet.md` (see the catch-up entry above), so both are identical again.

- 2026-10-04: tab entry notes the custom new-tab action (picker `<C-t>`, explorer `t`) and how to drop a stray file from one tab (`:setlocal nobuflisted`); picker keys entry marks `<C-t>` as custom.
