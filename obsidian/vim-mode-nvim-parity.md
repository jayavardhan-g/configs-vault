# Obsidian vim mode matching the nvim/LazyVim keymaps

**Date:** 2026-10-02
**Category:** obsidian
**Files touched:** `/mnt/study/vaults/personal/.obsidian/.obsidian.vimrc`, `/mnt/study/vaults/personal/.obsidian/hotkeys.json`,

<!-- graph:begin -->
**Graph:** [[Neovim]] · [[Vim]] · [[Obsidian]]
<!-- graph:end -->

`/mnt/study/vaults/personal/.obsidian/community-plugins.json`, `/mnt/study/vaults/personal/.obsidian/plugins/mrj-jump-to-link/`
(stored copies under `obsidian/files/mnt/study/vaults/personal/.obsidian/`)

## What
Obsidian's vim mode (vault `/mnt/study/vaults/personal`) remapped so the same keys do the same thing as in
`~/.config/nvim` (see [[keybindings-and-editing]]), via the Vimrc Support plugin's
`.obsidian.vimrc`. Added the Jump to link plugin as the stand-in for flash.nvim.

## Why
Wanted Obsidian to feel like nvim. The vimrc from 2026-09-20 had drifted to browser/VSCode
keys and Obsidian-only choices (H/L = ^/$, surround on `s`, Alt+hjkl focus) that did
something different in nvim.

## Change
Prereqs (vault-local, travel with the vault in the `vaults` repo):
- Settings → Editor → Vim key bindings on (`"vimMode": true` in `app.json`).
- Community plugins: **Vimrc Support** (`obsidian-vimrc-support`, 0.10.2), **Omnisearch**,
  **Git** (`obsidian-git`), **Jump to link** (`mrj-jump-to-link`, 0.6.1 — installed from
  the GitHub release: `gh release download 0.6.1 -R mrjackphil/obsidian-jump-to-link`
  into `.obsidian/plugins/mrj-jump-to-link/`, then added to `community-plugins.json`),
  **Hotkeys for specific files** (`obsidian-hotkeys-for-specific-files`, 1.4.1 — same
  install route from `vinzent03/obsidian-hotkeys-for-specific-files`; its `data.json`
  registers `Tools/Obsidian-Cheatsheet.md`).
- Cheatsheet note `/mnt/study/vaults/personal/Tools/Obsidian-Cheatsheet.md` (copy:
  `obsidian/files/mnt/study/vaults/personal/Tools/Obsidian-Cheatsheet.md`), opened with `<Space>h` like
  nvim's cheatsheet. Same `## Category` / `### Entry` layout; search it with `<Space>sb`.
- Default hotkeys cleared in `hotkeys.json` because Obsidian hotkeys fire *before*
  vimrc maps: Ctrl+O (quick switcher), Ctrl+I/B (italic/bold), Ctrl+H (search & replace),
  Ctrl+K (insert link), Ctrl+L (toggle checklist), Ctrl+D (delete paragraph — otherwise
  Ctrl+D deletes text instead of scrolling).

Key map (nvim key → Obsidian action):

| Key | Action |
|---|---|
| `<Space><Space>`, `<Space>ff`, `<Space>fr` | quick switcher |
| `<Space>/`, `<Space>sg` / `<Space>sb` | Omnisearch vault / this note |
| `<Space>e` / `<Space>E` | toggle left sidebar (explorer) / right sidebar (backlinks, outline, tags, git) |
| `<Space>bd`, `<Space>wd` / `<Space>bo` | close tab / close others |
| `<Space>fn`, `<Space>fN`, `<Space>cr`, `<Space>ul` | new note, new folder, rename note, toggle line numbers |
| `<Space>fe`, `<Space>fd` | reveal note in explorer, delete note (Obsidian confirms) |
| `<Space>m` | move note to another folder (restored from the original leader block) |
| `<Space>bp`, `<Space>bu`, `<Space>ba` | pin tab, reopen closed tab, bookmark note |
| `<Space>um` | toggle reading view / live preview |
| `<Space>x`, `<Space>>` | tick checkbox, toggle blockquote (line or selection) |
| `<Space>od`, `[d` / `]d` | today's daily note, prev / next daily note |
| `<Space>ob` (also `gr`), `<Space>oB` | backlinks sidebar, backlinks at bottom of note |
| `<Space>oo` (also `gO`, `<Space>cs`), `<Space>ot` | outline, tags |
| `<Space>og` / `<Space>oG` | graph / local graph |
| `<Space>oi`, `<Space>om` | insert template, bookmarks list |
| `<Space>sr` | search & replace in this note |
| `<Space>ce`, `<Space>cl` | extract heading into new note, cycle list type (plain → `-` → `1.` → `[ ]`) |
| `<Space>ghs` / `<Space>ghr` / `<Space>ghp` | stage / reset / preview git hunk |
| `<Space>op` / `<Space>oP` | fold frontmatter / open properties panel |
| `<Space>gg`, `<Space>gb`, `]h` / `[h` | obsidian-git view, blame, next/prev hunk |
| `<Space>gl`, `<Space>gd`, `<Space>gc` | git history view, diff view, commit-and-sync (commit + pull + push) |
| `gf`, `go`, `gD` | follow link, open link in new tab, open link in split |
| `za`, `zm` / `zr` | toggle fold, fold more / less |
| `<C-d>` / `<C-u>`, `n` / `N` | half-page scroll / search jump, kept centered (`zz`) |
| `:w`, `:q`, `:wq`, `:vs`, `:sp` | save, close tab, close tab, split right, split below |
| `<Space>y` / `<Space>Y`, `<Space>-` / `<Space>\|` | `"+y` / `"+y$`, split below / right |
| `H` / `L`, `[b` / `]b`, `gt` / `gT` | prev / next tab |
| `<C-h/j/k/l>` | focus pane left/down/up/right |
| `<A-j>` / `<A-k>` | move line down / up |
| `gd`, `gx` | follow link under cursor |
| `s` | Lightspeed jump (type 2 chars, then label) — flash stand-in |
| `gsa"` `gsa'` ``gsa` `` `gsa(` `gsa[` `gsa{` `gsam` `gsai` `gsab` `gsaw` | surround with quotes/brackets/`$`/`*`/`**`/`[[ ]]` |
| `<Esc>` | clear search highlight |
| `x` | `"_x` |

Kept from before: Ctrl+T/W/Tab/Shift+Tab, Ctrl+P / Ctrl+Shift+P, Ctrl+B / Ctrl+Shift+B,
Ctrl+Shift+F, Ctrl+Shift+M, Ctrl+O/I history, zo/zc/zR/zM folds, Alt+P paste-as-link,
`set clipboard=unnamed`. Full file: `obsidian/files/mnt/study/vaults/personal/.obsidian/.obsidian.vimrc`.

## Notes
- `set clipboard=unnamed` stays: nvim locally uses LazyVim's `clipboard=unnamedplus`, so
  plain `y` hits the system clipboard there too. In this engine `"+y`/`"+p` call
  `navigator.clipboard` directly, and `"_` is a real black hole register (checked in
  `/usr/lib/obsidian/obsidian.asar` → `lib/codemirror/vim.js`).
- A multi-key map can't share its first key with a built-in single-key command. The
  dispatcher fires the full match first, which is why `unmap <Space>` / `nunmap s` come
  before the sequences.
- Surround is add-only (the plugin's `surround` ex command), so there's no `gsd`/`gsr`.
  `gsa…` wraps the selection, or the word under the cursor; it doesn't take a motion
  like mini.surround.
- `s` is normal-mode only; visual `s` is native substitute. No `S` (flash treesitter)
  equivalent.
- Lost with the cleared hotkeys: Ctrl+L checklist toggle and Ctrl+K insert link (use
  `gsaw`, or the command palette). Search & replace is still in the palette, and `:s` works.
- Superseded: the 2026-09-20 layout had H/L = `^`/`$`, Alt+hjkl pane focus, `,` = `:nohl`,
  surround on `s"`/`sb`/`sw`…, and a truncated `map <A-p> :pasteinto` with no `<CR>` (fixed).
- Splits are on the leader only (`<Space>|` / `<Space>-`). Ctrl+- / Ctrl+| hotkeys were
  briefly added on 2026-10-02 and then dropped at the user's request, which also kept
  Ctrl+- as zoom-out. If they're ever wanted: Ctrl+- overrides zoom-out (an app-menu
  accelerator; a matched Obsidian hotkey calls `preventDefault`), and Ctrl+| has to go in
  `hotkeys.json` as `Mod+Shift` + `\`. A vimrc map can't express it.
- Original bindings, for reference. The user's pre-2026-09-20 vimrc leader block:
  `<Space>h/l` sidebars, `<Space>m` move file, `<Space>q` close, `<Space>z` zen
  (plugin not installed), `<Space>/` search, `<Space>|`/`<Space>-` splits. Older
  `hotkeys.json` (removed in the vault's 2026-04-10 backup commit): Ctrl+M move,
  Ctrl+D delete file, Alt+N / Alt+Shift+N new file, Alt+D new folder, Alt+C / Alt+B
  sidebars, Ctrl+\ / Ctrl+Shift+F6 splits. On 2026-10-02 only `<Space>m` was
  brought back.
- Centered scrolling (`nnoremap n nzz` etc.) is the one deliberate difference from nvim,
  which doesn't center. It must be `nnoremap`: the engine's keyToKey recursion guard
  (`vim.js` `doKeyToKey`) drops a mapping's own key, so `nmap n nzz` would only do `zz`.
- Ex aliases work because `matchCommand_` looks up the exact typed name first, so `:q`
  isn't shadowed by `:quickswitch`. Only `:w` (and `:image`) existed before, and the
  built-in `:w` calls `CodeMirror.commands.save`, which Obsidian never defines, so it
  was a silent no-op until `exmap w` pointed it at `editor:save-file`.
- `<Space>h` → `obcommand obsidian-hotkeys-for-specific-files:Tools/Obsidian-Cheatsheet.md`.
  That plugin's command id is the note path, and Vimrc Support's `obcommand` takes exactly
  one argument split on whitespace (no quoting), so the path can't contain a space —
  hence the hyphen. Chosen over enabling the Vimrc plugin's JS commands (flagged risky
  by the plugin, and the vimrc syncs via git) to open the note with one line of JS.
- Keep the cheatsheet note in sync when keys change.
- Declined from a second review: `<Space>bb` for bookmarks (nvim: other buffer),
  `<Space>ol` insert wikilink (`[[` in insert mode already opens the picker), a canvas key,
  and `<Space>hs/hr/hp` (moved to LazyVim's `<Space>gh…`; `<Space>h` is the nvim cheatsheet).
- Ideas taken from a popular community vimrc: ex aliases, gf/go, blockquote toggle, a
  checkbox key. Skipped: the parts needing Pane Relief / VimEx / obsidian-zoom / Stille /
  JS commands, and `[`/`]` → `{`/`}`, which would break `[b`, `[h` and `[[`.
- Alternative not taken (for now): editing the vault from nvim with
  [obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim), the maintained fork.
- 2026-11-05: the vault these paths name (`/mnt/study/vaults/personal`) was split (see
  [[vaults-repo-migration]]), and the vim setup was then copied into **every** vault:
  `study/study`, `personal/personal`, `configs`, `projects`, `study/mtp` (all under
  `/mnt/study/vaults/`). Each has the same `.obsidian/.obsidian.vimrc`, `hotkeys.json`,
  `vimMode: true`, the five plugins the vimrc calls (Vimrc Support, Jump to link,
  Omnisearch, Git with every auto-commit/pull/push off, Hotkeys for specific files) and
  its own copy of `Tools/Obsidian-Cheatsheet.md` for `<Space>h`. Style Settings and Image
  Converter stayed in study/personal only (not vim). In configs the cheatsheet is listed
  in `SKIP` in `scripts/build-graph.py` (a reference copy, not an entry).
- **Keep the five copies identical**: when a key changes, edit the vimrc and the
  cheatsheet in one vault, then copy both files to the other four vaults (each is its own
  repo: commit and push each).
