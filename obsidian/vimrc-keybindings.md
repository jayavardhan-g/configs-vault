# Obsidian vimrc: nvim-flavored keybindings, and the real dispatcher gotchas found along the way

**Date:** 2026-09-20 to 2026-09-21
**Category:** obsidian
**Files touched:** `.obsidian/.obsidian.vimrc` in the personal vault (`/mnt/study/vaults/personal`) (see

<!-- graph:begin -->
**Graph:** [[Neovim]] · [[Vim]] · [[Obsidian]]
<!-- graph:end -->

[[vault-setup-and-migration]] for why the file itself isn't duplicated here)

## What
Reworked the vault's existing `.obsidian.vimrc` (via the `obsidian-vimrc-support`
community plugin) to mix real vim motions, LazyVim-style conventions, and familiar
browser/VSCode muscle memory — then, over several rounds of things silently not working,
ended up reading the actual `codemirror-vim` engine source to find out why. Those findings
are the reusable part of this entry.

## Why
Same underlying goal as [[../zen-browser/vim-style-keyboard-shortcuts]] — Neovim-flavored
muscle memory across apps — but Obsidian's vimrc plugin is a much thinner wrapper around a
real (partial) vim emulation, `codemirror-vim`, which has its own hard rules that aren't
documented anywhere obvious. Getting several of these wrong (and then reading the real
source to find out why) produced findings worth keeping so they aren't rediscovered the
hard way again.

## Final keybinding table

**Vim motions / editing** (already worked or thin wrappers, no gotchas)
| Key | Action |
|---|---|
| `j` / `k` | Visual-line movement (`gj`/`gk`) |
| `H` / `L` | Start / end of line |
| `,` / `F9` | Clear search highlight (was previously a debug leftover on `,` that just echoed text — fixed) |
| yank | Goes to system clipboard (`set clipboard=unnamed`) |
| `Ctrl+O` / `Ctrl+I` | Back / forward (real vim jumplist keys) |

**Surround** (select text, or cursor on a word, then)
| Key | Wraps with |
|---|---|
| `s"` `s'` `` s` `` `s(` `s[` `s{` | quotes/brackets, pre-existing |
| `sm` | `$...$` (math) |
| `si` | `*...*` (italic) |
| `sb` | `**...**` (bold) |
| `sw` | `[[...]]` (wiki-link) — moved here from `[[` itself, see Notes |

**App actions** (deliberately matches browser/VSCode, not vim, since these have no vim equivalent anyway)
| Key | Action |
|---|---|
| `Ctrl+T` | New tab |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / previous tab (also `gt`/`gT`) |
| `Ctrl+W` | Close tab |
| `Ctrl+Shift+P` | Command palette |
| `Ctrl+P` | Quick switcher |
| `Ctrl+B` / `Ctrl+Shift+B` | Toggle left / right sidebar |
| `Ctrl+Shift+F` | Global search |
| `Space` then `-` | Split horizontal (real nvim/LazyVim two-key sequence) |
| `Space` then `\|` | Split vertical |
| `Ctrl+Shift+M` | Move file |
| `Alt+h/j/k/l` | Move focus between split panes |

**Folding / misc**
| Key | Action |
|---|---|
| `zo` / `zc` | Toggle fold (Obsidian only exposes one toggle command, not separate open/close — `za` was removed as a pointless third name for the same action) |
| `zR` / `zM` | Unfold all / fold all |
| `Alt+p` | Paste clipboard as hyperlink over selection |

## The real gotchas (read `codemirror-vim`'s actual source for all of these — `replit/codemirror-vim`, `packages/codemirror-vim-core/vim.js` on GitHub, ~7100 lines; the wrapper plugin's own README documents some *unreleased* behavior as if shipped, don't trust it blind)

### 1. `let mapleader` / `<leader>` doesn't exist in the installed version
The installed `obsidian-vimrc-support` is `0.10.2` (published 2024-11-03 — confirmed via
the GitHub Releases API). A real `feat: Add <leader> key support` commit was merged
**2026-02-16** (refined further 2026-03-26) — genuinely working code, confirmed by reading
the actual commit list — but it has never been packaged into any release, draft or
otherwise. `grep -c "leader" main.js` on the installed plugin returns 0. The README on the
`master` branch documents this feature as if it's available; it isn't, for anyone who
hasn't manually built from source.
- **To actually get it**: `npm install && npm run build` in a clone of the repo produces a
  fresh `main.js` you can drop into
  `<vault>/.obsidian/plugins/obsidian-vimrc-support/` in place of the published one.
  Obsidian doesn't distinguish manually-placed plugin files from ones its Community
  Plugins browser downloaded — it just loads whatever's in that folder, and its
  update-checker only compares against the latest *published* release tag, so it won't
  try to "fix" a manually-updated install back to 0.10.2. Not done here — this system had
  no `npm` at all (Node wasn't even installed via `pacman`), installing it needs `sudo`,
  and a working alternative was found without it (see #3).

### 2. The `<...>` bracket-notation parser requires a word character
The regex that tokenizes key notation is `/<(?:[CSMA]-)*\w+>|./gi` — the `\w+` after the
modifier prefix means only letters/digits/underscore are valid *inside* `<...>`. `|` and
`\` are not word characters, so `<A-Bar>` and `<A-|>` are **structurally invalid**, not
just wrong names — confirmed by also checking the full special-key table (`specialKey`
object, ~line 1201): it only contains `CR`, `BS`, `Del`, `Esc`, `Ins`, `Left`/`Right`/`Up`/
`Down`, `Space`. No `Bar`, no `Minus` (though `-` alone, *outside* brackets, is fine — it's
just matched by the regex's `.` fallback as a literal single character).
- Checked whether `|`'s common role as vim's command-separator would cause it to get
  split out of a `nmap` line even as a bare unbracketed character — it doesn't: the
  generic ex-command argument parser (`parseCommandArgs_`) grabs the rest of the line with
  `inputStream.match(/.*/)`  and only splits on whitespace, no special-casing for `|`
  anywhere in that path, and the plugin's own vimrc-file line reader doesn't split on it
  either.
- **Practical result**: matching Zen's literal `-`/`|` characters exactly isn't possible
  here for a Alt-modified key. Settled on real vim's own command abbreviations instead —
  `Alt+V` for `:vsplit`, `Alt+S` for `:split` — before landing on the actually-correct fix
  in #3.

### 3. The dispatcher fires the first full match immediately — no deferral for a longer partial match
This is the one that actually explains most of what "wasn't working": `matchCommand`
(~line 1599) does `var bestMatch = matches.full[0]; if (!bestMatch) { ...check partial... }`
— **if any full match exists at all, it fires immediately**, without ever checking whether
a longer sequence is also possible. Unlike real vim (which waits `timeoutlen` when a
longer completion is still possible even after a shorter full match exists), this
emulation just commits to the first thing that matches completely.
- Bare `<Space>` already has a built-in full match: `{ keys: '<Space>', type: 'keyToKey',
  toKeys: 'l' }` (real vim: Space = move right). So `nmap <Space>- ...` could never
  complete — every Space press fired "move right" instantly, before the `-` had a chance
  to matter.
- **Fix**: `unmap <Space>` before defining anything Space-prefixed. This is the *exact*
  reason the file already had `nunmap s` before the `s`-prefixed surround mappings
  (`s` alone is real vim's substitute-character command) — and in fact the **original**
  inherited vimrc already had `unmap <Space>` for this same reason, before it got removed
  during an earlier redesign pass and had to be re-added.
- **General rule going forward**: before binding any multi-key sequence, check whether its
  *first* key already has a bare full match in the real `defaultKeymap` (search
  `keys:\s*['"]<that-key>['"]` in the source). If it does, `unmap` it first or the longer
  sequence can never complete. Verified this way (all clean, no bare full-match) for every
  other multi-key sequence in this vimrc — `[[`, `zo`/`zc`/`zR`/`zM`, `gt`/`gT` all start
  with `[`, `z`, `g`, none of which are ever standalone commands in real vim either, so
  none of them needed unmapping.

### 4. `Ctrl+B` collided with a native Obsidian hotkey the plugin-level checks didn't catch
Checking whether an obcommand ID (e.g. `app:toggle-left-sidebar`) has a *default* hotkey
isn't the same as checking whether the raw key combo is already claimed by something else
entirely. `app:toggle-left-sidebar` genuinely has no default — but `Ctrl+B` was already
natively bound to **Toggle bold** (`editor:toggle-bold`), found only by having the user
screenshot their actual live Settings → Hotkeys list. Resolved by clearing the native
"Toggle bold" binding (bold now lives on the `sb` surround mapping) rather than picking a
different sidebar key — same reasoning as `si` replacing native Ctrl+I.
- **General lesson**: "does obcommand X have a default hotkey" and "is this key combo
  already used by something" are two different questions — checking only the former
  missed a real conflict. The live Settings → Hotkeys list is the authoritative source for
  the latter; static analysis of default hotkeys alone isn't enough.
- Also found via the same screenshots: **"Close current tab" had its native Ctrl+W
  hotkey cleared entirely** (shown as Blank + a revert icon) — not a vim-shadowing issue
  as first assumed, just genuinely unbound. Re-assigned it back to Ctrl+W in Settings.
  Quick Switcher and Toggle Italic were *already* cleared from their Ctrl+O/Ctrl+I
  defaults by the same mechanism, which is why those two needed no further action.

### 5. `[[`/`]]` bracket symmetry
Wiki-link-wrap was originally bound to `[[` itself, overriding the plugin's own default
(jump to previous heading) while `]]` kept its default (jump to next heading) — an
asymmetric pair doing unrelated things depending on direction. Moved wiki-link-wrap to
`sw` instead (matching the `si`/`sb`/`sm` pattern) so `[[`/`]]` both fall back to their
real, symmetric defaults untouched.

## Notes
- **Superseded keymap (2026-10-02):** the vimrc was reworked to mirror the nvim/LazyVim
  keys — see [[vim-mode-nvim-parity]] for the current mappings. The `codemirror-vim`
  dispatcher findings in this entry still apply.
- `F11 → zen-mode:toggle` was in the *original* inherited vimrc and was removed outright —
  `zen-mode` doesn't exist anywhere in this Obsidian install, not core (`core-plugins.json`
  has no such key), not any installed community plugin. It was very likely silently
  failing on Windows too, since the plugin's own commands-that-fail-are-silent behavior
  means a dead binding like this produces no visible error ever.
- **Still open, not done**: `obsidian.nvim` (the real Neovim plugin, not this Obsidian
  plugin) for editing the vault directly from Neovim with wiki-link/daily-note awareness —
  discussed and researched (feature list, LazyVim fit) but deliberately deferred in favor
  of finishing the in-app vimrc first. Worth returning to if Neovim becomes the primary
  editor for this vault day-to-day rather than Obsidian's own vim-emulated editor.
- A handful of Obsidian's other native formatting commands (`editor:toggle-strikethrough`,
  `editor:toggle-highlight`, `editor:toggle-comment`) don't have surround mappings yet —
  same trivial pattern as `sb`/`si` if ever wanted, just not done since nothing forced the
  issue the way bold/italic's hotkey conflicts did.
