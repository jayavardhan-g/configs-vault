# Keybindings and editing behaviour

**Category:** neovim
**Files touched:** `lua/config/keymaps.lua`, `lua/config/options.lua`, `lua/plugins/completion.lua`, `lua/plugins/noice.lua`, `lua/plugins/scope.lua`, `lua/plugins/snacks.lua`, `lazyvim.json` (all under `~/.config/nvim/`; copies in [`files/`](files/))

Key remaps and editing defaults layered on top of LazyVim: the old-vs-LazyVim key comparison, OSC 52 clipboard yank, VSCode-style comment toggle, 4-space indent, the autocomplete toggle, the mini.surround extra, per-tab buffers (scope.nvim), and the explorer's `t` new-tab key. Part of the LazyVim setup - see [[lazyvim-migration]] for the migration itself and the index of all topic files.

Entries are in the order they happened. They were split out of `lazyvim-migration.md` on 2026-09-23 without rewording, so "above" and "previous follow-up" refer to entries in this file unless a link says otherwise.

## Follow-up: comparing old keybinds against LazyVim's, adding back what's missing (2026-09-15)

**What**: the old hand-rolled `lua/config/keymaps.lua` (see [[vim-neovim-parity-pass]] and
[[neovim-minimal-ssh-friendly-setup]]) wasn't ported over at all - diffed it directly
against LazyVim's actual default keymaps
(`~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/config/keymaps.lua`) to see what's really
gone versus just remapped to a different key. Findings:
- Same key survived by coincidence: `<C-s>` save, `<C-h/j/k/l>` window nav, `[d`/`]d`.
- Same idea under a different LazyVim key: buffer cycle (`<S-h>`/`<S-l>` not
  `<Tab>`/`<S-Tab>`), splits (`<leader>\|`/`<leader>-` not `<leader>v`/`<leader>h`),
  resize (`<C-arrows>` not bare arrows), tabs (`<leader><tab>` prefix), wrap toggle
  (`<leader>uw`), close window (`<leader>wd`), line diagnostics (`<leader>cd`).
- **`<leader>bd` (LazyVim default) already does exactly what `mini.bufremove` was
  installed for** - delete a buffer without closing its window. That whole plugin
  install (see the "leader-x was collapsing the file window" follow-up in
  [[vim-neovim-parity-pass]]) turned out to duplicate something LazyVim ships natively,
  just under a different key than the old `<leader>x`.
- Gone entirely, no LazyVim equivalent: `jk`/`kj` to exit insert, OSC52 clipboard yank,
  the custom multi-file "smart quit" (Skip option), `<leader>sn`, `x` deleting into the
  unnamed register (see below), `<C-d>`/`<C-u>` scroll-and-center, visual-paste-without-
  clobbering-register.

**Change** - added the one thing asked for so far, `~/.config/nvim/lua/config/keymaps.lua`
(LazyVim's documented user-keymap extension point, auto-loaded after its own defaults):
```lua
-- Delete a character without yanking it (plain x overwrites the unnamed
-- register, clobbering whatever you last copied with y)
vim.keymap.set("n", "x", '"_x', { noremap = true, silent = true })
```
**Verified live**: yanked a word (`yiw`), pressed `x` elsewhere, pasted (`p`) - the
yanked word came back intact rather than the deleted character, confirming `x` no longer
clobbers the unnamed register.

**Not yet added, offered but no decision made**: `jk`/`kj` to exit insert mode - flagged
as a loss with no LazyVim substitute; add if/when asked.

## Follow-up: OSC52 clipboard yank, SSH-only (2026-09-15)

**What LazyVim actually does by default** (checked its source before changing anything,
per the request to explain the default first): `lazyvim/config/options.lua` sets
`opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"` - locally, *every* yank
already syncs to the system clipboard automatically via Neovim's built-in provider
auto-detection (confirmed `wl-copy`/`wl-paste` installed and used) - broader than the old
`<leader>y`-only design. Over SSH, clipboard is deliberately left empty - nothing syncs
anywhere, no OSC52 fallback is actually wired up despite the comment implying room for it.

**A real bug caught before it shipped**: the first attempt registered `vim.g.clipboard` as
an OSC52 provider unconditionally. Since local `unnamedplus` routes through the `"+"`
register, this would have made OSC52 fire on *every* local yank too, replacing the
already-working `wl-copy` path with terminal escape codes even when sitting at the
machine directly - not just "adding" SSH support, actively regressing the local case.
Caught by explaining the default behavior back before implementing, per request - fixed
by gating the whole block on `vim.env.SSH_CONNECTION`, mirroring LazyVim's own conditional
exactly.

**Change** - `~/.config/nvim/lua/config/options.lua`:
```lua
if vim.env.SSH_CONNECTION then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end
```
`~/.config/nvim/lua/config/keymaps.lua` - same scoped-to-`<leader>y` design as the
pre-LazyVim setup (plain `y`/`yy` untouched):
```lua
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', yank_opts)
vim.keymap.set("n", "<leader>Y", '"+y$', yank_opts)
```
No plugin needed - Neovim 0.10+ ships this OSC52 provider built in
(`vim.ui.clipboard.osc52`), unlike the old setup's `ojroques/vim-oscyank`.

**Verified live, both branches**: with `SSH_CONNECTION` unset, `<leader>yiw` produced no
OSC52 escape sequence and `wl-paste` confirmed the word actually landed in the real
Wayland clipboard (untouched local path). With `SSH_CONNECTION` set, the same command
correctly emitted `\x1b]52;c;aGVsbG8=` (`hello`, base64-encoded) instead.

## Follow-up: `Ctrl+/` toggles comment, VSCode-style (2026-09-22)

**What**: `Ctrl+/` was opening a terminal (LazyVim default) instead of toggling a
comment, which is the muscle memory carried over from VSCode. Remapped it to comment
toggle; terminal access is unaffected since it was never *only* on this key.

**Why**: LazyVim binds `<c-/>` and `<c-_>` (terminal emulators send one or the other for
the same physical key depending on keyboard protocol support - see Notes) to
`Snacks.terminal.focus(...)` (root-dir terminal), per
`~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/config/keymaps.lua`. That's a duplicate of
`<leader>ft` (same action, "Terminal (Root Dir)") and `<leader>fT` ("Terminal (cwd)"),
both of which stay untouched - so reclaiming `<c-/>`/`<c-_>` loses no functionality, just
a faster alias for something still reachable via leader.

Comment toggling itself (`gcc`/`gc`) is Neovim's own built-in feature (native since 0.10,
confirmed present as core Lua-backed keymaps independent of any plugin - not from the
disabled `ts-comments.nvim`), and already produces the correct `commentstring` per
filetype (`// %s` for C/C++/JS, `# %s` for Python/sh, `<!-- %s -->` for Markdown, `-- %s`
for Lua) via Neovim's built-in ftplugin system - verified directly with a headless
`:set filetype=X` + print `commentstring` check across all languages this setup uses.

**Change** - `~/.config/nvim/lua/config/keymaps.lua`, appended:
```lua
-- VSCode-style comment toggle. Overrides LazyVim's default terminal-toggle
-- binding on this key (<leader>ft/<leader>fT still open a terminal).
-- remap=true is required: "gcc"/"gc" are themselves keymaps (Neovim's
-- built-in comment support, not a raw command), so noremap would try to
-- interpret g/c/c literally instead of dispatching through them.
local comment_opts = { remap = true, silent = true, desc = "Toggle comment" }
vim.keymap.set("n", "<C-/>", "gcc", comment_opts)
vim.keymap.set("n", "<C-_>", "gcc", comment_opts)
vim.keymap.set("v", "<C-/>", "gc", comment_opts)
vim.keymap.set("v", "<C-_>", "gc", comment_opts)
```

**Verified live**: headless Neovim, forced `VeryLazy` to fire (needed in headless mode -
LazyVim's own `<c-/>` binding and this override both live in `config/keymaps.lua` files
that only load on that event, which never fires without a real UI attaching). Confirmed
via `nvim_get_keymap` that both `<C-/>`/`<C-_>` now resolve to `desc = "Toggle comment"`
(not "Terminal (Root Dir)") in both normal and visual mode. End-to-end keypress
simulation on a `.cpp` file: normal-mode `Ctrl+/` on `int main() {` produced
`// int main() {`; visual-mode `Ctrl+/` over the whole 3-line file commented every line
with `//`, confirming both the line-toggle and selection-toggle paths work correctly.

**Notes**:
- Both `<C-/>` and `<C-_>` are mapped (not just `<C-/>`) because terminal keyboard
  encoding for this physical key isn't uniform: legacy encoding sends the literal control
  byte `0x1f` (`<C-_>`), while terminals supporting the newer Kitty keyboard protocol
  (kitty itself, this setup's terminal, included) can send `<C-/>` as a distinct code.
  Mapping only one would leave the binding flaky depending on which code Neovim's TUI
  actually receives - this mirrors LazyVim's own default, which maps both for the same
  reason.
- `<leader>ft` (Terminal, Root Dir) and `<leader>fT` (Terminal, cwd) remain the way to
  open a terminal - nothing was moved to replace the reclaimed key, since these already
  existed and cover the same use case.

## Follow-up: 4-space indent everywhere, disabled completion ghost text (2026-09-22)

**What**: two separate complaints about editing feel - "auto brackets and indentation
... very bad" and, later, "the autofill suggestions ... distracting". Addressed the parts
that were unambiguous; autopairs (`mini.pairs`) specifics were never pinned down (asked
for a concrete example, none given yet) so left untouched pending that.

**Why**:
- **Indentation**: LazyVim sets a **global** `shiftwidth=2`/`tabstop=2` for every
  filetype - confirmed no per-language override existed anywhere in this config. Asked
  directly what width was wanted (options: 4 for C-family only, 4 everywhere, tabs for
  C-family, or custom) - answer was **4 everywhere**. Note this only changes indent
  *width*; the indent *logic* was already treesitter-based
  (`indentexpr = v:lua.LazyVim.treesitter.indentexpr()`, wired automatically whenever a
  parser is installed - confirmed in `lazyvim/plugins/treesitter.lua`), not the naive
  `smartindent` fallback, so no separate fix was needed there.
- **Ghost text**: "autofill suggestions" is blink.cmp's `ghost_text` - the greyed-out
  inline preview of the top completion candidate shown ahead of the cursor as you type,
  distinct from the dropdown completion menu itself (which was not reported as a problem
  and stays on). Confirmed via `lazyvim/plugins/extras/coding/blink.lua`:
  `ghost_text.enabled = vim.g.ai_cmp`, and `vim.g.ai_cmp = true` by default - so it was on
  by default with no explicit user opt-in.

**Change** - `~/.config/nvim/lua/config/options.lua`, appended:
```lua
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
```
`~/.config/nvim/lua/plugins/completion.lua` (new - LazyVim plugin-spec override, same
pattern as `languages.lua`/`disabled.lua`):
```lua
return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        ghost_text = { enabled = false },
      },
    },
  },
}
```

**Verified live**: headless Neovim, forced `VeryLazy`. `.cpp` and `.py` buffers both
report `shiftwidth=4 tabstop=4 expandtab=true` (was 2/2 before). For ghost text,
`require('blink.cmp.config').completion.ghost_text.enabled` is a function (blink.cmp
normalizes bool opts into closures internally) - called it directly, returns `false`
(was `true`/on before the override).

**Not yet done**: autopairs (`mini.pairs`) behavior - user's original complaint bundled
"auto brackets ... very bad" with indentation, but never specified what's actually wrong
(not closing when expected? closing when not wanted? bad interaction on Enter inside
`{}`?). Revisit once a concrete repro is given - LazyVim's current `mini.pairs` defaults
are documented in `lazyvim/plugins/coding.lua` (`skip_next`, `skip_ts = {"string"}`,
`skip_unbalanced`) as the starting point.

## Follow-up: root-caused indent/autopairs complaint, added an autocomplete toggle (2026-09-22)

**What**:
1. The original "auto brackets and indentation ... very bad" turned out to be **unnamed
   buffers only** (`:enew`/no file opened) - no filetype means no filetype-specific
   `commentstring`/indent/treesitter-parser context. `.cpp`/`.py` files were already fine.
   No fix needed - behavior is correct, just hadn't been noticed that the bad case never
   happened on a real file.
2. Autocomplete (blink.cmp) "gets in my way" - added a runtime on/off toggle rather than
   disabling anything permanently.

**Why**: (1) is standard Neovim behavior, not a bug - flagging it here mainly so a future
session doesn't re-investigate the same non-issue. (2) - a full toggle (not just muting
ghost text, already handled in the previous follow-up) covers wanting the LSP dropdown
gone entirely sometimes (e.g. fast typing in prose-like contexts) while keeping it
available on demand elsewhere, without editing config every time.

**Change** - `~/.config/nvim/lua/config/keymaps.lua`, appended:
```lua
vim.g.blink_cmp_enabled = true
Snacks.toggle({
  name = "Autocomplete",
  get = function() return vim.g.blink_cmp_enabled ~= false end,
  set = function(state)
    vim.g.blink_cmp_enabled = state
    if not state then
      pcall(function() require("blink.cmp").hide() end)
    end
  end,
}):map("<leader>uo")
```
`~/.config/nvim/lua/plugins/completion.lua` - added alongside the existing `ghost_text`
override:
```lua
enabled = function()
  return vim.g.blink_cmp_enabled ~= false
end,
```

**A real gotcha hit while building this**: first attempt bound the toggle to
`<leader>uC` - looked free from grepping `lazyvim/config/keymaps.lua` alone, but that
file doesn't contain every default keymap. `<leader>uC` was already LazyVim's
colorscheme-picker keymap, registered elsewhere (plugin `keys` spec, not the imperative
keymaps.lua file) - `vim.keymap.set` silently overwrites on collision, no error, so this
only surfaced by checking the **live**, fully-merged keymap table
(`nvim_get_keymap`) rather than trusting a static grep. Moved to `<leader>uo`, confirmed
free the same way. General lesson: always verify a new leader-key binding against
`nvim_get_keymap('n')` after `VeryLazy`, not just against `keymaps.lua`'s own contents.

**Also discovered while auditing `<leader>u*`**: `<leader>up` is already a LazyVim
built-in - "Toggle Mini Pairs" (autopairs on/off). Relevant if the still-open autopairs
complaint above turns out to just be "I want it off sometimes" rather than a real
misbehavior - that's already one keypress away, no config change needed.

**Verified live**: headless Neovim, forced `VeryLazy`. Confirmed `<leader>uo` registers
with `desc = "Toggle Autocomplete"` (not colliding with anything, per the live keymap
dump). Simulated the keypress: `require('blink.cmp.config').enabled()` flips `true` ->
`false`, notification `Disabled **Autocomplete**` fires, `vim.g.blink_cmp_enabled`
matches. Re-pressing flips it back to `true`.

**Moved to `<leader>ac` (2026-09-22)**: user asked for a say in the actual key rather
than have one picked unilaterally - fair, a keybinding is a pure preference call, not
something to decide alone. Proposed `<leader>ac` ("autocomplete"); confirmed live that
nothing at all is bound under `<leader>a`, so no collision risk. Re-verified the same way
as the original binding - registers correctly, toggle behavior unchanged.

## Follow-up: mini.surround extra on, five accidental extras removed (2026-09-28)

**What**: enabled LazyVim's `coding.mini-surround` extra (wrap/unwrap/replace text in `"`, `'`, `(`, `[`, `{`). While browsing `:LazyExtras`, five more extras got switched on unintentionally - `ai.supermaven`, `ai.tabnine`, `coding.luasnip`, `coding.mini-comment`, `coding.mini-snippets` - and were removed again. The extra list lives in `~/.config/nvim/lazyvim.json` (now stored in [`files/`](files/.config/nvim/lazyvim.json)).

**Why**: surround editing isn't built into Vim/Neovim. The removed ones were never wanted: two AI completion services, two competing snippet engines (LazyVim's blink.cmp already uses Neovim's built-in snippets + `friendly-snippets`), and mini.comment, which duplicates Neovim's native `gc` (and the `Ctrl+/` toggle above).

**Change** - `~/.config/nvim/lazyvim.json` extras block, final state:
```json
"extras": [
  "lazyvim.plugins.extras.coding.mini-surround"
],
```
Cleanup after editing the file by hand (removes plugin dirs and lockfile entries nothing references any more):
```bash
nvim --headless "+Lazy! clean" +qa
rm -r ~/.supermaven   # supermaven-nvim leaves a device-id/link-id config here; the plugin dir alone isn't everything
```
Plugins it removed: `supermaven-nvim`, `cmp-tabnine`, `blink.compat` (tabnine's nvim-cmp bridge), `mini.snippets`, `mini.comment`, `nvim-ts-context-commentstring`. `luasnip` hadn't been downloaded yet.

**Keys**: LazyVim's defaults, kept deliberately - `gsa` add, `gsd` delete, `gsr` replace, `gsf`/`gsF` find, `gsh` highlight. `)`/`]`/`}` wrap tight, `(`/`[`/`{` add inner spaces.

**Notes**:
- vim-surround-style keys (`ys`/`ds`/`cs`/`yss`) were considered and declined: kept LazyVim's `gs` defaults so nothing else loses a key. LazyVim puts surround on `gs` because Flash owns `s`/`S` (see [`flash.lua`](files/.config/nvim/lua/plugins/flash.lua)); remapping would have cost "operate up to a Flash jump target" (`ys`/`ds`/`cs`) and either visual-mode surround or visual-mode Flash Treesitter (`S`).
- Moving Flash jump to `f` was asked about and advised against: Flash already enhances `f`/`F`/`t`/`T` (char mode), and taking `f` would lose single-char line motions like `df,`.
- Plain Vim has no surround plugin; `auto-pairs` there has Fast Wrap (type `(` then `Alt-e` wraps the next word).

## Follow-up: per-tab buffer lists with scope.nvim (2026-10-04)

**What**: added `tiagovla/scope.nvim` so each tab page lists only the buffers opened in it - bufferline, `H`/`L` (`:bnext`/`:bprev`) and the `<leader>,` buffer picker all follow the current tab. New file `~/.config/nvim/lua/plugins/scope.lua` (copy in [`files/`](files/.config/nvim/lua/plugins/scope.lua)).

**Why**: asked after `:tabnew`'s `[No Name]` buffer showed up in every tab. Vim buffers are global and bufferline (stock LazyVim, `mode = "buffers"`) lists all of them in every tab; there's no built-in per-tab scoping and no LazyVim extra for it.

**Change** - `~/.config/nvim/lua/plugins/scope.lua`:
```lua
return {
  {
    "tiagovla/scope.nvim",
    event = "VeryLazy",
    opts = {},
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceSavePre",
        callback = function()
          pcall(vim.cmd.ScopeSaveState)
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceLoadPost",
        callback = function()
          pcall(vim.cmd.ScopeLoadState)
        end,
      })
    end,
  },
}
```
First launch installs it (lazy.nvim); it is pinned in `lazy-lock.json`.

**Notes**:
- Session hooks are needed because persistence.nvim (LazyVim's sessions) would otherwise restore every buffer into every tab. scope stores its state in a global, which LazyVim's `sessionoptions` already includes (`globals`).
- Verified headless (with `VeryLazy` forced - it never fires without a UI): tab 1 lists `a, c`, tab 2 only `b`; `:bnext` stays inside the tab; a file opened in two tabs is listed in both; save + restore keeps the split. Snacks' buffer picker filters on `buflisted`, so it follows the tab too.
- `:ScopeMoveBuf {n}` moves the current buffer to tab `n`.
- Undo: delete `scope.lua` and run `:Lazy clean`.
- `<leader>fB` (Snacks "Buffers (all)", `hidden = true`) still lists every tab's buffers, but picking one opens it in the **current** tab (it then joins this tab's list) - Snacks' `drop` action only finds buffers *visible* in another tab's window. **Shelved (future work)**: a custom confirm on `<leader>fB` that looks the buffer up in `require("scope.core").cache` (refreshed only on TabLeave, so use live `buflisted` for the current tab), switches to that tab page and `:buffer`s it, else opens here. A separate tab-page picker was offered and declined ("searching through all buffers is enough").
- Recommendation given when asked "global or per-tab?": keep per-tab - with one tab nothing changes, and it gives extra tabs a purpose; switch back only if tabs are used as alternate layouts of the *same* files.


## Follow-up: kitty tab keys moved off Ctrl+T / Ctrl+W (2026-10-04)

**What**: kitty's new-tab / close-tab shortcuts moved from bare `ctrl+t` / `ctrl+w` to `ctrl+shift+t` / `ctrl+shift+w` (kitty's own default modifier). Also dropped a dead duplicate `map ctrl+shift+tab next_tab` (the `previous_tab` line after it always won). File: `~/.config/kitty/kitty.conf` (copy in [`files/`](files/.config/kitty/kitty.conf)).

**Why**: kitty resolves its maps before the program inside sees the key, so with bare Ctrl+T/Ctrl+W mapped, Neovim never received `<C-t>` (picker open-in-new-tab, tag/help jump back, previous match while searching, explorer terminal, insert-mode indent) or `<C-w>` (every window command - pressing it in Neovim closed the kitty tab). Found while documenting tab pages / scope.nvim above. Options offered: Ctrl+Shift (chosen), kitty `--when-focus-on` maps that pass the keys to Neovim, or leave as-is.

**Change** - `~/.config/kitty/kitty.conf`, tab block:
```conf
# Ctrl+Backspace deletes the previous word in every program (sends Ctrl+W)
map ctrl+backspace send_text all \x17
map ctrl+tab next_tab
map ctrl+shift+tab previous_tab
# New/close tab on Ctrl+Shift, not bare Ctrl+T / Ctrl+W: kitty catches its
# maps before the program inside, and Neovim needs <C-t> (picker: open in
# new tab, tag/help jump back) and <C-w> (every window command).
map ctrl+shift+t new_tab
map ctrl+shift+w close_tab
```
Applied to running kitty with `pkill -USR1 -x kitty` (config reload).

**Notes**:
- Verified with kitty's own config parser: ctrl+shift+t → `new_tab`, ctrl+shift+w → `close_tab` (overrides kitty's default `close_window` there - same thing with one window per tab), no bare ctrl+t / ctrl+w maps left.
- The Ctrl+Backspace line is unaffected: `send_text` types `\x17` straight to the program, it never went through the old `ctrl+w` map.
- The stored `kitty.conf` copy had been missing this whole tab/backspace block (added after the last copy); it's current now.

## Follow-up: `t` in the explorer opens the file in a new tab page (2026-10-04)

**What**: in the Snacks file explorer, `t` opens the file under the cursor in a new tab page; on a folder it expands/collapses it (same as `l`/`<CR>`). New file `~/.config/nvim/lua/plugins/snacks.lua` (copy in [`files/`](files/.config/nvim/lua/plugins/snacks.lua)) - the first Snacks override in this setup, so it is also where the cheatsheet's "Default:" notes for Snacks options now point.

**Why**: the explorer had no new-tab key. Pickers use `<C-t>` ("tab"), but Snacks' own explorer source rebinds `<C-t>` to "terminal" (`snacks/picker/config/sources.lua`) - stock behaviour, never changed by LazyVim or this config (checked when asked). Offered `t`, `T`, or taking over `<C-t>`; `t` chosen. `t`/`T` were unbound in both the explorer and the picker list defaults.

**Change** - `~/.config/nvim/lua/plugins/snacks.lua`:
```lua
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  ["t"] = "tab",
                },
              },
            },
          },
        },
      },
    },
  },
}
```

**Notes**:
- No custom action needed: Snacks' `tab` action is `{ action = "confirm", cmd = "tab" }`, and the explorer's `confirm` toggles folders and only calls `jump` (here `tab sbuffer`) for files.
- Verified headless (explorer opened, `VeryLazy` forced, key fed into the list window): `t` on a folder expanded it with no new tab; `t` on a file opened tab 2 with just that file and moved there; the explorer stayed in tab 1. With scope.nvim the new tab's buffer list starts with only that file.

## Catch-up: changes made in earlier sessions but never recorded (found 2026-10-04)

Found while auditing stored copies against the live files on 2026-10-04. Dates unknown (between 2026-09-23 and 2026-10-02); the reasons below come from the comments in the live files. Copies in [`files/`](files/) are now current.

**`dm{mark}` deletes a mark** - `lua/config/keymaps.lua`, appended:
```lua
vim.keymap.set("n", "dm", function()
  local char = vim.fn.getcharstr()
  if char == "-" then
    vim.cmd("delmarks!")
  elseif char:match("^[%a%d]$") then
    pcall(vim.cmd.delmarks, char)
  end
end, { desc = "Delete mark (dm{mark}, dm- = all in buffer)" })
```
The mirror of `m{mark}` (a mark-plugin convention; Vim only has `:delmarks`). `dm` was free: `m` isn't a motion, and no other mapping starts with `d`, so `dd`/`dw` stay instant.

**Autocomplete starts off** - `lua/config/keymaps.lua`: `vim.g.blink_cmp_enabled = false` (was `true` when the `<leader>ac` toggle was added - see the 2026-09-22 follow-up above). It stays out of the way until `<leader>ac` turns it on for the session.

**Diagnostics hidden at startup** - `lua/config/options.lua`, appended: `vim.diagnostic.enable(false)`. LSP errors/warnings were distracting while typing; `<leader>ud` (stock LazyVim toggle) shows them. The LSP still computes them, so they appear instantly when toggled on.

**Signature help no longer pops up by itself** - new `lua/plugins/noice.lua`:
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
noice opened the function signature on every `(` / `,`. `<C-k>` (insert) / `gK` (normal) still show it on demand.

The cheatsheet already covered all four ("Customizations: default vs current"); only this log and the stored copies were behind.

## Follow-up: fixed files leaking into the old tab's buffer list (2026-10-04)

**What**: replaced Snacks' `tab` action (pickers' `<C-t>`, the explorer's `t`) with a custom one in `lua/plugins/snacks.lua` that runs `:tabedit` (copy in [`files/`](files/.config/nvim/lua/plugins/snacks.lua)). Supersedes the plain `["t"] = "tab"` setup above: the key binding is unchanged, but `tab` now resolves to the custom function.

**Why**: reported as "all buffers appear in the first tab". Reproduced: after explorer `t` on `b.txt`, tab 1 listed `afile.txt, b.txt`, and tab 2 listed `afile.txt` (wrong file). Snacks' `jump` does `bufadd()` + `buflisted = true` in the **current** tab, then `:tab sbuffer`. scope.nvim snapshots the old tab's listed buffers on `TabLeave`, so every file opened "in a new tab" from a picker joined the old tab too. `:tabe` was always fine because it creates the tab first.

**Change** - `~/.config/nvim/lua/plugins/snacks.lua`, final state:
```lua
local function open_in_new_tab(picker, item)
  if not item then
    return
  end
  if item.dir then
    return picker:action("confirm")
  end
  local items = picker:selected({ fallback = true })
  if picker.opts.jump and picker.opts.jump.close == false then
    vim.api.nvim_set_current_win(picker.main)
  else
    picker:close()
  end
  for _, it in ipairs(items) do
    local path = Snacks.picker.util.path(it)
    if path and not it.dir then
      vim.cmd.tabedit(vim.fn.fnameescape(path))
      if it.pos and it.pos[1] > 0 then
        pcall(vim.api.nvim_win_set_cursor, 0, { it.pos[1], it.pos[2] })
        vim.cmd("normal! zz")
      end
    end
  end
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        actions = {
          tab = open_in_new_tab,
        },
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  ["t"] = "tab",
                },
              },
            },
          },
        },
      },
    },
  },
}
```

**Notes**:
- Overriding works by name: Snacks resolves an action through `picker.opts.actions` before its built-ins, so one override covers every `<C-t>` and the explorer `t`.
- Verified headless: explorer `t` keeps tab 1 = `afile.txt`, tab 2 = `b.txt`; files-picker `<C-t>` opens a tab listing only that file; grep `<C-t>` lands on the match line (3); folders still expand/collapse with `t`; the explorer stays open in its tab.
- Tabs already polluted before the fix: switch to the stray file, `:setlocal nobuflisted`, switch away. It drops out of that tab only (verified; `<leader>bd` would close it everywhere). Sessions saved before the fix keep the polluted lists until cleaned this way.
- Multi-select (`<Tab>` in a picker, then `<C-t>`) should open one tab per file - the action loops over the selection, but this case was not tested.

