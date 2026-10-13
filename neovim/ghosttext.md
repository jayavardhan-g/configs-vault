# GhostText (edit browser text in Neovim)

**Category:** neovim
**Files touched:** `lua/plugins/ghosttext.lua`, `lua/config/keymaps.lua` (all under `~/.config/nvim/`; copies in [`files/`](files/))

<!-- graph:begin -->
**Graph:** [[Neovim]] · [[GhostText]]
<!-- graph:end -->

nvim-ghost.nvim setup: per-site languages, formatting and LSP in ghost buffers, and the `<leader>cL` language picker. Part of the LazyVim setup - see [[lazyvim-migration]] for the migration itself and the index of all topic files.

Entries are in the order they happened. They were split out of `lazyvim-migration.md` on 2026-09-23 without rewording, so "above" and "previous follow-up" refer to entries in this file unless a link says otherwise.

## Follow-up: GhostText buffers get a language, formatting and LSP (2026-09-23)

**What**: text opened from the browser via GhostText (`nvim-ghost.nvim`) had no file
extension, so formatting, indentation and the LSP didn't work in it. Asked for either a
way to give the temporary buffer an extension, or at least apply a language's rules.

**Also found: nvim-ghost was never recorded here.** `lua/plugins/ghosttext.lua` existed
in the live config but was absent from `files/` and from every changelog entry, so a
fresh-machine rebuild from this repo would have silently dropped GhostText entirely.
Now tracked.

**Root cause - two separate problems, found by testing each in isolation**:
- nvim-ghost creates each textarea as an **unnamed `nofile` scratch buffer**, and sets
  the filetype from the browser's `syntax` hint (`binary.py`: `filetype =
  data["syntax"]`) - usually empty for a plain textarea, sometimes a MIME type such as
  `text/x-c++src` that isn't a Neovim filetype at all.
- With a filetype set, **formatting already works** (conform ran `clang-format` on the
  scratch buffer fine). The **LSP does not**: it stays at 0 clients. Tested the
  variants: unnamed+`nofile` no; named+`nofile` no; named+normal buftype **yes**. The
  gate is in Neovim itself - `$VIMRUNTIME/lua/vim/lsp.lua`, `lsp_enable_callback`:
  "Only ever attach to buffers ... that represent an actual file", rejecting any
  `buftype` other than `""` / `help`.

**Why not just make it a normal buffer**: nvim-ghost closes ghost buffers with a plain
`:bdelete N` (`binary.py`, `handle_close`), which **refuses** a modified normal buffer
("No write since last change") - the tab would get stuck open when the page closes.
Instead: keep it `nofile`, give it a real **name with the right extension**
(`~/.cache/nvim/nvim-ghost/<host>-<bufnr>.<ext>`, bufnr so two textareas from one site
don't collide), and **start the matching servers by hand** with
`vim.lsp.start(config, { bufnr })` for each `vim.lsp.get_configs({ enabled = true,
filetype = ft })` - that path has no buftype gate. Verified `bdelete` still succeeds
afterwards. Nothing is written to disk.

Also needed: `nvim-lspconfig` is lazy-loaded on file-open events (LazyVim's `LazyFile`
= `BufReadPost`/`BufNewFile`), which a ghost buffer never fires - so a Neovim started
purely to serve GhostText would never load it. `require("lazy").load(...)` handles it.
(Note while testing: `doautocmd User LazyFile` does **not** trigger that - `LazyFile`
is a lazy.nvim event alias, not a real User event.)

**Decisions** (asked, per the preference rule): per-site defaults + a picker;
**`leetcode.com` -> C++** as the only site default for now; picker on **`<leader>cL`**
(checked free at runtime *and* by grepping LazyVim core + extras - and the runtime
probe was sanity-checked against known-taken keys this time); picker works in **every**
buffer, not just ghost ones - which also fixes the earlier-reported odd
indentation/autopairs in plain `:enew` scratch buffers, since they have no filetype
either.

**Change**:
- `lua/plugins/ghosttext.lua` - `site_filetypes` table (host -> filetype); a `User`
  autocmd in nvim-ghost's own `nvim_ghost_user_autocommands` group (the plugin only
  creates that group if it doesn't already exist, so ours isn't clobbered) that tags
  the buffer with its host and applies the site default when the browser hint isn't a
  real filetype; a `FileType` autocmd that, for tagged buffers, names the buffer and
  (re)attaches servers - detaching ones that don't serve the new filetype.
- `lua/config/keymaps.lua` - `<leader>cL`: `Snacks.picker.select` over your languages
  first (cpp, c, python, markdown, text) then every other filetype. Calls Snacks
  directly because `vim.ui.select` is the stock numbered prompt in this setup (checked).

**A real bug caught by testing before it shipped**: the first version's `User`
autocmd used pattern `*`, which fires for **every** plugin's plain `doautocmd User
Foo`, not just nvim-ghost's - lazy.nvim alone fires `VeryLazy`, `LazyRender`,
`LazyDone`. In testing, a ghost buffer got retagged with host `LazyRender` and renamed
`LazyRender-4.py`; worse, any unnamed `nofile` plugin UI buffer that happened to be
current (the `:Lazy` window is one) could have been tagged and renamed. Fixed by only
accepting an event whose name looks like a hostname (has a dot, or is `localhost`).
Re-verified: a plugin UI buffer hit with foreign `User` events stays untagged and
unnamed, and the ghost buffer keeps its real host.

**Verified live** (simulating nvim-ghost's exact buffer creation + event):
leetcode.com -> `ft=cpp`, `buftype=nofile`, named `leetcode.com-2.cpp`, clangd
attached, error diagnostic reported; github.com (no default) stays plain; switching a
ghost buffer cpp -> python detaches clangd and attaches ruff; `bdelete` clean. Picker:
opens with cpp/c/python/markdown/text first, choosing python sets `ft=python`, and
Python auto-indent then works after `def f():` in an `:enew` buffer. (Headless tests
must force the picker to re-match after setting its input - an earlier "chose python,
got cpp" result was that artifact, confirmed by checking the filtered list before
confirming.)

**Cheatsheet**: new "GhostText & buffer language" category (3 entries), plus
`<leader>cL` in the customizations summary. Keymap coverage 280/284, same four known
non-gaps. Note: format-on-save never fires in ghost buffers (never written) - documented
to use `<leader>cf` before submitting.

## Follow-up: own GhostText server + patched extension (2026-10-12)

**What**: replaced `nvim-ghost.nvim` with a Lua GhostText server in the config
(`lua/ghosttext/init.lua` + `protocol.lua`), and replaced the AMO GhostText add-on with
a patched build ([[ghosttext-extension]]). Asked to
analyse both for shortcomings after two known bugs: pressing Escape cleared the page's
text box, and commenting several lines in a web editor arrived in Neovim as one
commented line. Then: "fix whatever we can", custom extension OK.

Full list of what the audit found and the status of each: [[ghosttext-shortcomings-audit]].

**Root causes of the two reported bugs** (both in the extension, reproduced in a
headless-Firefox suite against the stock add-on):
- *One line commented*: the page-world bridge's throttle kept the **first** call's
  arguments in each 50 ms window. Ace reports a multi-line toggle as one change per
  line, so only the first-line state was sent - and the next Neovim keystroke then
  pushed that stale text back, undoing the other comments in the page. Monaco and
  CodeMirror 6 weren't affected by this one.
- *Escape clears the field*: contenteditable fields were written as `innerHTML`. Rich
  editors (Lexical, ProseMirror, Slate...) keep their own model and throw such DOM
  writes away on their next update - and the next browser keystroke then sent the
  editor's (empty) text back, wiping Neovim's copy too. React `<textarea>`s were tested
  and are **not** a cause in Firefox (content-script writes already bypass React's value
  tracker); the exact site wasn't identified.

**Server: why replace rather than patch nvim-ghost** - its Python server ran the
WebSocket and Neovim listener on separate threads, with a "skip the next buffer event"
flag set *after* the buffer write: depending on timing it swallowed the next real edit
in Neovim or bounced a stale browser state back. It also sent each change twice,
rewrote the whole buffer per keystroke (undo/cursor/marks churn), measured the cursor in
bytes vs code points (browsers use UTF-16), had several crash paths, accepted
WebSocket connections from any web page, and the plugin is unmaintained since Nov 2024.
Its Python deps aren't installed system-wide (it ships a PyInstaller binary), so a
patched `binary.py` would have needed a venv anyway.

**New server design** (single-threaded on Neovim's loop, no dependencies):
- each UI Neovim listens for WebSockets on a random localhost port; one "hub" also owns
  port 4001 and answers the extension's `GET /` with the port of whichever Neovim last
  had focus (`FocusGained` -> `GET /focus?port=N`). Hub gone -> the next instance to
  gain focus, or a 3 s watchdog, takes 4001 over. An old nvim-ghost binary on 4001 is
  asked to `/exit` first;
- WebSocket handshakes/requests with a web-page `Origin` get 403 (extensions and our own
  instances only);
- echo suppression = "last text both sides agreed on", so no race; changes in one tick
  (a `:s`, a comment toggle, a formatter) go out as one message;
- browser -> Neovim replaces only the changed run of lines; cursor offsets are UTF-16 both
  ways; the page's editor language (Monaco/Ace/CodeMirror, sent by the patched add-on)
  sets the filetype and follows language switches unless the filetype was changed by
  hand;
- opening a field fires `User GhostTextOpen` with `data = { buf, host, title }` inside
  the new buffer - replaces nvim-ghost's `User <hostname>` events, so the "only accept
  names that look like hostnames" workaround above is gone, and the wrong-buffer case
  (two fields connecting together) can't happen.
- `:GhostTextStatus` prints port / hub / connected fields.

`lua/plugins/ghosttext.lua` is now a lazy.nvim `virtual = true` spec (nothing to
install) that calls `require("ghosttext").setup()` and keeps the site defaults, LSP
naming and `<leader>cL` behaviour from the entries above. `nvim-ghost.nvim` removed with
`:Lazy clean` (also gone from `lazy-lock.json`).

**Extension**: see the fix table in
[[ghosttext-extension]] - besides the two bugs:
current CodeMirror 6 wasn't detected at all (`cmView` renamed `cmTile`), Monaco's undo
history was wiped on every Neovim keystroke, the "Disconnect" menu item/shortcut threw
(minifier renamed `stopGT`), Ace ignored page-made changes, and listeners leaked on
reconnect.

**Install** (manual, per Zen profile - Nani and Study have GhostText):
`about:config` `xpinstall.signatures.required=false` -> `about:addons` -> *Install
Add-on From File* -> `neovim/ghosttext-extension/ghosttext-patched-26.5.12.2.xpi` ->
remove the original GhostText. Zen allows unsigned add-ons (built without
`MOZ_REQUIRE_SIGNING`, checked in its `omni.ja`); stock Firefox release wouldn't.

**Verified**: `ghosttext-extension/tests/` - server 22/22, multi-instance/hub 7/7
(incl. killing the real nvim-ghost binary on a spare port), real config headless
(LeetCode -> cpp + clangd, Monaco `python` hint overrides the site default, GitHub
plain), end-to-end in headless Firefox 34/34 patched vs 15/34 stock.

**Gotcha**: after updating, restart Neovim instances; the first new one shuts the old
nvim-ghost server down. Still-running old instances keep sending nvim-ghost's
`/focus?focus=` requests, which the new hub ignores.

## Follow-up: characters lost when typing fast (2026-10-13)

**What**: typing quickly in Neovim sometimes left text one character behind - "the
quick brown" + " fox" became "the quick browfox n".

**Root cause**: a stale copy of the text coming back from the page and rewinding the
buffer mid-typing. The "n" vanished, came back after the cursor, and the next keys went
in before it. Reproduced with a new key-by-key typing test: on CodeMirror 6 our own
bridge polled the editor, saw text that Neovim had just written as a page edit, and
sent it back - five stale copies per sentence, one of which ate a character.
Ace/Monaco/textarea/ProseMirror/Lexical sent nothing back. The real config
(`FULLCONFIG=1`) behaved the same, so it wasn't a plugin.

**Fix** (both sides, so no editor or site can cause it again):
- extension v26.5.12.2: the CM6 bridge remembers the document it wrote;
- server: browser texts that exactly match something Neovim sent in the last 3 s - but
  has since moved past - are dropped as stale echoes (`stale` in the trace). This also
  covers the Study profile, which still had the stock add-on. Trade-off: undoing in the
  page to a text Neovim sent within those 3 s is ignored; the next Neovim edit re-syncs.
- server: when a real browser edit lands, every window's cursor is moved with the text
  around it. `nvim_buf_set_lines`/`set_text` leave the cursor column where it was, so
  an insert earlier on the cursor's line used to leave it behind its text.
- debugging aid: `:let g:ghosttext_debug = 1`, reproduce, `:GhostTextLog` shows the
  last 200 messages each way.

**Verified**: server 26/26; `ONLY=typing` 27/27 with `--clean` and with the real
config; full e2e still 34/34.

**Install**: in Zen, *Install Add-on From File* `ghosttext-patched-26.5.12.2.xpi` over
the old one (Nani; Study still needs the original swap), and restart Neovim so the new
server code loads.

**Confirmed** working in daily use after installing v26.5.12.2 (2026-10-13).

**Upstream status** (checked 2026-10-13): fregante/GhostText is maintained but slow -
releases 24.7.6, 24.8.10, 26.5.12 (2026-05-12), 40 open issues. Related open issues:
#296 "CodeMirror 6 only works on the first connection" and #261 "Improve UX
expectations for `contentEditable`"; nothing filed yet for the throttle, `cmTile`,
`stopGT` or stale-echo bugs. Whether to fork the source and send these upstream was
raised the same day - see the next entry if one gets made.

## Follow-up: fork with our commits, built by GitHub Actions (2026-10-13)

**What**: the add-on's source of truth moved to a fork,
[jayavardhan-g/GhostText](https://github.com/jayavardhan-g/GhostText), branch `patched`
(clone: `~/claude/GhostText`, `upstream` remote = fregante/GhostText; fork `main` stays
an untouched mirror). Each fix is one commit on top of upstream: throttle, `cmTile`,
Disconnect, WebSocket error, bridge rewrite (minimal/echo-free edits), syntax hint,
real-input writes + plain-text contenteditable, keep-alive, fork identity.

**Why**: `build.py` patches minified code with exact-string matches, which breaks on
every upstream release and duplicates the fixes. A fork makes them readable commits
and an upstream update a rebase. No npm on this machine (asked for explicitly), so
builds run on GitHub.

**Release process**: `.github/workflows/build-xpi.yml` on the fork runs **only on `v*`
tags** - it sets the manifest version from the tag, runs `npm ci && npm run build` on
GitHub's runner, and attaches `ghosttext-patched-<version>.xpi` to a GitHub Release:
```sh
git -C ~/claude/GhostText/.claude/worktrees/patched tag -a v26.5.12.4 -m "..."
git -C ~/claude/GhostText/.claude/worktrees/patched push origin v26.5.12.4
gh release download v26.5.12.4 -R jayavardhan-g/GhostText   # then install in Zen
```
Upstream's `CI` workflow is disabled on the fork (`gh workflow disable CI`) so plain
pushes build nothing; its Lint job fails on our code style, its Build job passed.

**Notes**:
- Skip upstream's `npm run pre:build`: it rewrites `web_accessible_resources` into the
  Manifest V2 shape, which Parcel rejects for this V3 manifest (upstream CI skips it too).
- First release `v26.5.12.3` (2026-10-13): GitHub build passed e2e 34/34 and typing 27/27.
- `build.py` (patch approach) was retired the same day, once the GitHub-built v26.5.12.3
  was confirmed in daily use; the committed `.xpi` and bridge copy went with it (still
  in git history). Install paths in the entries above refer to that old approach.

## Follow-up: E367 error on `:q` while a field was open (2026-10-14)

**What**: with a GhostText field open, `:q` (e.g. closing the dashboard tab, or `:tabonly`)
showed a big noice error:
```
Error in BufWipeout Autocommands for "<buffer=1>":
...snacks/dashboard.lua:262: Vim:E367: No such group: "--Deleted--"
```

**Cause**: the server opened each field with `tab sbuffer N`. That splits the *current*
window first, so the new tab briefly showed the current buffer - usually the Snacks
dashboard (buffer 1, `bufhidden=wipe`). Snacks reacted to the dashboard appearing in the
extra window and ended up with its BufDelete/BufWipeout cleanup registered twice; when
the dashboard was later wiped, the second call deleted an already-deleted augroup.
Isolated in a real UI (`nvim --remote-ui` under `script`; headless never showed it): a
plain `tab sbuffer` of a scratch buffer reproduces it with GhostText out of the picture,
`:tabnew` doesn't.

**Fix** - `lua/ghosttext/init.lua`, `Session:open`: `tabnew`, put the field's buffer in
that window, delete the empty placeholder. Verified in the real UI: `:tabonly`, `:q` on
the dashboard tab, `:q` on the GhostText tab and quitting Neovim are all clean; server
tests 26/26.

**Notes**: first suspected the exit path (the `VimLeavePre` cleanup wiping buffers);
changing that made no difference and was reverted.
