# LeetCode in Neovim (leetcode.nvim)

**Category:** neovim
**Files touched:** `lua/plugins/leetcode.lua`, `lua/plugins/languages.lua` (all under `~/.config/nvim/`; copies in [`files/`](files/))

<!-- graph:begin -->
**Graph:** [[Neovim]]
<!-- graph:end -->

Solving LeetCode inside Neovim: setup, health check, run/submit keys, two-box sign-in, the swap-file fix, the console docked at the bottom, and the solution-file keys. Part of the LazyVim setup - see [[lazyvim-migration]] for the migration itself and the index of all topic files.

Entries are in the order they happened. They were split out of `lazyvim-migration.md` on 2026-09-23 without rewording, so "above" and "previous follow-up" refer to entries in this file unless a link says otherwise.

## Follow-up: leetcode.nvim - run, test and submit LeetCode from Neovim (2026-09-23)

**What**: asked whether page commands (e.g. LeetCode's `Ctrl+'` to run tests) could be
sent from Neovim through GhostText. They can't: the GhostText protocol carries only
text, selections, URL and a syntax hint - no channel back to the page. Building one
(forking the extension plus patching nvim-ghost, or a userscript polling a local
server) was estimated at half a day to a day, plus ongoing breakage from per-site DOM
selectors. Checked for an existing solution first instead: **kawre/leetcode.nvim**, an
actively maintained plugin that replaces the LeetCode browser tab entirely - `:Leet
run` / `test` / `submit` natively. Chosen over building anything.

It's also the better fit than GhostText for LeetCode specifically: solutions are real
`.cpp` files, so clangd / clang-format / format-on-save work with none of the ghost-
buffer workarounds.

**Findings while setting it up** (read the plugin's source rather than trusting its
README alone):
- **Picker**: it auto-detects in order snacks -> fzf-lua -> telescope -> mini. Its
  Snacks check is `assert(Snacks.config["picker"].enabled)` - ran that exact condition
  here: true, so it uses Snacks with no config.
- **`html` treesitter parser** is "optional, but highly recommended" (renders problem
  descriptions). It had been deliberately removed in the very first trim follow-up
  ("languages actually used", in [[languages-and-lsp]]). Restored in `languages.lua`, with a comment saying
  why, so it isn't trimmed again. Other web parsers (javascript/jsdoc/tsx/typescript)
  stay removed. Confirmed `html` is back in the merged `ensure_installed` list.
- **Upstream's `build = ":TSUpdate html"` fails here** ("Not an editor command: TSUpdate
  html") - treesitter isn't loaded at plugin-build time, and it would fail again on a
  fresh machine. Dropped: `ensure_installed` installs the parser instead.
- **C++ includes**: LeetCode compiles with `bits/stdc++.h` and `using namespace std`
  implicitly, so solutions use `vector`/`string` with no `#include`. I initially wrote
  an `injector` adding those two lines - then found the plugin **already injects exactly
  those by default** (`lua/leetcode/config/imports.lua`; `inject_imports()` returns the
  defaults when no `imports` override is set), folded out of the way. My version would
  have put them in every file twice. Removed. Also confirmed only the marked
  `@leet start`/`@leet end` code section is sent on run/test/submit
  (`console.lua:63`), so injected lines never get submitted.
- `bits/stdc++.h` exists on this system (`/usr/include/c++/16/...`, GCC libstdc++), so
  clangd can resolve it.

**Change** - `lua/plugins/leetcode.lua` (new): the plugin with `plenary.nvim` +
`nui.nvim` (both already installed), `lang = "cpp"` (its default, made explicit), no
injector override. `lua/plugins/languages.lua`: `html` no longer filtered out.

**Verified live**:
- `:Leet` command registered; config resolved `lang=cpp`, no injector override.
- A LeetCode-style solution file laid out as the plugin writes it (imports section +
  marked code section): clangd attached, **0 errors**. Same file without the imports
  section: **3 errors** ("No template named 'vector'") - i.e. exactly the problem the
  default imports solve.
- `nvim leetcode.nvim` launches cleanly: after `VimEnter` the working directory moved
  to `~/.local/share/nvim/leetcode` (its storage home), the menu buffer mounted
  (`ft=leetcode.nvim`), 0 errors in `:messages`. (Note for headless testing: `-c`
  commands run **before** `VimEnter`, and the plugin starts on `VimEnter` - checks must
  be deferred past it or they see nothing. The first attempt hit exactly that.)

**Not done, needs the user**: logging in. `:Leet cookie update` with the `Cookie` value
from the browser's **request** headers. The plugin stores it under its own cache dir;
no cookie value is in this repo. Cookies expire periodically, and the same "expired"
message appears when LeetCode throttles its API during contests.

**Cheatsheet**: new "LeetCode" category (6 entries: launching, login, run/test/submit,
console keys, finding problems, the cookie-expired case); GhostText entry points
LeetCode users here instead. Keymap coverage unchanged at 280/284 (no new global
keymaps - everything is under `:Leet`).

## Follow-up: leetcode.nvim health check, and the "cookie expired" error explained (2026-09-23)

**Is it still working?** Its last *tagged release* is v0.3.1 (2025-06-28), but commits
continued to 2026-04-28 (the installed version); not archived, ~2.2k stars, issues and
PRs active through this week. Caveat: nothing merged since April, nine community PRs
pending - fixes are slow. Tested live against LeetCode rather than inferring from dates:
problem lookup (GraphQL) returned correct data, the problem list returned all 4,060
problems, and unauthenticated POSTs to the run/submit endpoints reached LeetCode's own
server (Django's "403 CSRF verification failed" page - `server: cloudflare` is just the
CDN edge, not the bot check). So Cloudflare wasn't blocking this machine at the time.
Logged-in run/submit remain untested (needs the user's cookie).

(Testing note: a first probe used a zsh loop variable named `path`, which in zsh is tied
to `$PATH` - it wiped the command search path, so its "origin answered" output was
meaningless. Renamed the variable and re-ran.)

**The "cookie expired" message is a catch-all** - `api/utils.lua:153` shows it for any
401/403, so it can't distinguish its three real causes: a genuinely expired cookie
(fix: `:Leet cookie update`), LeetCode throttling its API during contests (fix: wait),
and Cloudflare flagging the request as a bot (fix: curl-impersonate). Documented a
diagnosis order: fresh cookie first; if a fresh cookie fails immediately outside
contest time, it's Cloudflare.

**curl-impersonate** (community-confirmed fix in issue #167, latest confirmation
2026-08-29): plenary.curl shells out to `curl`, and Cloudflare recognises curl by its
TLS handshake regardless of the User-Agent header. curl-impersonate is a curl build that
handshakes like a real browser. Verified before documenting it: plenary really reads
`vim.g.plenary_curl_bin_path` (`plenary/curl.lua:291`); the package is in the official
repos (`extra`, 2.2.2) so plain `pacman -S` works; and Arch's own file list for the
package confirms it installs `curl_chrome136` - the exact profile the reports used -
plus newer ones (`curl_chrome150`, `curl_firefox147`). **Not installed** - only needed
if the Cloudflare case actually occurs.

**Cheatsheet**: the LeetCode "cookie expired" entry now has the cause/diagnosis table,
plus new entries for the curl-impersonate fix and for what plenary is (and what its
announced end of active maintenance means). 153 entries; keymap coverage unchanged.

## Follow-up: LeetCode run/submit keys (2026-09-23)

**What**: leetcode.nvim ships **no** keys for run/test/submit - checked the source: its
configurable `keys` only cover its own windows (`q`, `<CR>`, `r`, `U`, `H`, `L`), and
nothing binds run or submit. Added `\r` (run) and `\s` (submit); `\` is the local
leader.

**Decision** (asked, with options checked first): `<leader>l...` was out (`<leader>l`
is Lazy, so a group under it would delay opening Lazy); `<leader>r` / `<leader>R` are
free today but reserved by the refactoring / REST extras; `Ctrl+'` / `Ctrl+Enter`
(LeetCode's website keys) only reach Neovim in terminals that support kitty's keyboard
protocol. Chose local-leader keys, bound **buffer-locally** to solution buffers only.

No test key: `:Leet test` and `:Leet run` hit the same endpoint (`urls.run` and
`urls.interpret` are both `/problems/%s/interpret_solution/`).

**Change** - `lua/plugins/leetcode.lua`: a `hooks.question_enter` function. That hook
fires in `Question:handle_mount()` right after `create_buffer()`, and again when
`:Leet lang` opens a new, not-yet-loaded solution buffer - so the keys follow a
language switch.

**Verified**: calling the registered hook on a buffer binds `\r` -> `<Cmd>Leet run<CR>`
and `\s` -> `<Cmd>Leet submit<CR>` there, while an unrelated buffer gets neither. In a
real `nvim leetcode.nvim` session (checked after `VimEnter`), `run` and `submit` are
both among its 23 subcommands. Not verified: pressing them on a live problem, which
needs the user's login. Cheatsheet "Run, test and submit" entry updated.

## Follow-up: LeetCode sign-in split into two boxes (2026-09-23)

**What**: first real sign-in failed with "Bad csrf token format". The user had copied
just the `LEETCODE_SESSION` value from dev tools' Cookies tab. `Cookie.parse`
(`lua/leetcode/cache/cookie.lua:88`) needs **both** `csrftoken=...` and
`LEETCODE_SESSION=...` as `name=value` pairs, checking csrftoken first - hence that exact
error. Asked for separate input boxes for the two values instead of one "paste the
whole Cookie header" box.

**Change** - `lua/plugins/leetcode.lua`: a `two_box_cookie_prompt` that asks for
csrftoken, then LEETCODE_SESSION, assembles `csrftoken=X; LEETCODE_SESSION=Y`, and hands
it to the plugin's **own** `cookie.set` - so saving and the login check are the
plugin's, unchanged. Uses the same nui popup style as the original prompt (wider, since
the tokens are long). Also strips a pasted `name=` prefix, trims whitespace, cancels on
an empty first box, and still accepts a full Cookie header in the first box (skipping
the second).

Done from config rather than editing the plugin's files, which are overwritten on every
plugin update. It had to reach **three** places, since two of them keep references
rather than looking the function up when called: `cmd.cookie_prompt` itself;
`cmd.commands.cookie.update[1]`, which the `:Leet cookie update` table captures when its
module loads, so it's patched directly; and the sign-in page's "Sign in" button, which
captures the prompt when that page first renders - after our `config` runs, so it picks
up the replacement. A custom `config` function calls `require("leetcode").setup(opts)`
first, then patches.

**Verified**: in a real `nvim leetcode.nvim` session, all three references point at the
new function (the sign-in page module was found holding it). Behaviour tested with a
fake popup feeding scripted answers and `cookie.set` stubbed (nothing written, no
network) - 5/5: two plain values; values pasted with their names; stray whitespace; a
full Cookie header in box 1 (one box only, passed through untouched); empty box 1
cancels. Real popups were also confirmed to show the right titles in order ("1/2
csrftoken" then "2/2 LEETCODE_SESSION").

**Testing notes** for next time: leetcode.nvim resolves its storage paths only once a
session starts, so its cookie module can't even be required in a plain Neovim (`field
'cache' (a nil value)`) - test inside `nvim leetcode.nvim` after `VimEnter`. And typing
into nui popups via feedkeys doesn't work when the whole test runs as one script
(`startinsert` only takes effect once control returns to the main loop), so keystrokes
landed as normal-mode commands - a fake `nui.input` gives a deterministic test instead.

Also confirmed the failed attempt didn't leave a bad cookie behind: `Cookie.set` parses
before writing, so a malformed paste never reaches disk.

## Follow-up: LeetCode questions failing to open - swap files (2026-09-23)

**What**: reopening a previously attempted problem showed a "code already found,
recover/delete?" prompt, and after either choice the question never appeared.

**Diagnosis**: the plugin has no such prompt (grepped) - it's Neovim's own swap-file
`ATTENTION` dialog. `nvim -r` showed the swap for `33.search-in-rotated-sorted-array.cpp`
owned by a **still-running** `nvim leetcode.nvim` (pid 48973), i.e. the same solution
file open in two places. Reproduced on a throwaway file with a second headless Neovim
holding it open: the plugin loads solutions via `vim.fn.bufload()`, which raises
**`E325: ATTENTION`** as an error rather than prompting. The buffer actually loads
(`loaded=true`), but the plugin treats the error as fatal - so the question never
opens whichever option is chosen.

**What didn't work, tested rather than assumed**: a `SwapExists` autocmd setting
`v:swapchoice` ('o' or 'e'), and `swapfile=false` per-buffer in `BufReadPre` - both still
got E325, because the swap check runs before either can intervene. (A first
reproduction attempt gave meaningless results: `-c "set directory=..."` runs *after*
the file loads, so the holder's swap went to the default directory and no conflict
existed. Fixed with `--cmd`, which runs before.) What works session-wide:
`shortmess+=A` and `noswapfile`.

**Decision** (asked): no swap files in LeetCode sessions. Chosen over `shortmess+=A`,
which keeps swap files but hides the warning - stale swaps from crashes would then pile
up unnoticed and ambush a normal Neovim later. Tradeoff accepted: a crash loses edits
since the last `:w`.

**Change** - `lua/plugins/leetcode.lua`: `hooks.enter` sets `vim.o.swapfile = false`.
`enter` fires in `leetcode.start()` before any question buffer exists, so every
solution buffer inherits it; normal Neovim sessions are untouched.

**Verified**: in a real `nvim leetcode.nvim` session, `swapfile` is `false` after
start, and loading a file that another Neovim holds with a swap succeeds (`ok=true`,
no E325, no own swap). A normal session still has `swapfile=true`. The other instance's
swap and the user's live problem-33 swap were left untouched.

## Follow-up: console docked at the bottom as real splits (2026-10-07)

**What**: asked for the default layout `[[question, code], [testcases at the bottom]]`.
Before, checking output meant `:Leet console`, reading, then going back to the code -
and the console vanished the moment focus left it, so output and code were never
visible together. It was also immune to window commands (no `<C-w>` resizing).

**Why it behaved that way** (read from the source, not assumed): the console is a
floating nui layout - an invisible container float plus two popups (Testcases,
Result), each with its own border float - centred over the editor
(`leetcode-ui/layout/console.lua`). `ConsolePopup.handle_leave`
(`leetcode-ui/popup/console/init.lua`) hides the whole console on any
`BufLeave`/`WinLeave` that doesn't land in the other console popup. The plugin has no
split mode for it: `console.size`/`console.dir` only shape the float.

**Approach**: let the plugin keep creating and owning its windows, then convert them.
Since Neovim 0.10, `nvim_win_set_config` turns a float into a split
(`{ split = "below", win = -1 }` = full-width bottom split). nui's border code checks
window validity before touching its border windows, so closing those and the
container float is safe. Re-implementing the console with `NuiSplit` was the
alternative - far more code duplicating the plugin, for the same result.

```text
  ┌─ description ─┬───── code ─────┐
  │               │                │
  ├── testcases ──┴──── result ────┤
  └────────────────────────────────┘
```

**Change** - `lua/plugins/leetcode.lua`:
- `dock_console(console)`: moves testcases to a full-width bottom split (30% of the
  screen height on first open, keeps a resized height on later re-docks), result to
  its right; closes the border floats and the container float; puts the old border
  titles in winbars drawn in `FloatBorder`.
- `patch_console()`, run from `hooks.enter` (guarded to run once):
  - `Console.show` wrapped to dock after every show - the plugin re-creates the
    windows as floats on each show.
  - `ConsolePopup.handle_leave` replaced with a no-op, so the console stays open.
    `q` inside it and `:Leet console` still hide it.
  - `Console.run` wrapped to return focus to the window you ran from (it used to jump
    into the result) - the result is visible below anyway; `L` focuses it.
  - `Description.show` wrapped to re-dock, since `:Leet desc` re-opens the
    description as a full-height editor-relative left split.
- `hooks.question_enter`: shows the console on open, focus back in the code.

**Gotcha - why `enter`, not `config()`**: the first version did the patches in the
lazy.nvim `config` function. Requiring `leetcode-ui.layout.console` there pulls in
`leetcode/cache/cookie.lua`, which indexes `config.storage.cache` - only set by the
plugin's own `config.setup()` at `VimEnter`. The require failed, and every later
require of the module failed with "loop or previous error loading module", so no
question could open. `hooks.enter` runs in `leetcode.start()` right after
`config.setup()`. Caught by the headless test below, before use.

**Verdict colour kept**: the plugin colours the verdict with
`border:set_highlight(hl)`, which re-links `FloatBorder` in the result window's
`winhighlight`. A winbar drawn with `%#FloatBorder#` follows that re-link - checked on
a drawn screen (UI attached via `--embed`): the winbar cell's attribute changed when
the window's `FloatBorder` was re-linked.

**Verified** - headless `nvim leetcode.nvim` with the real cookie, opening an
already-solved problem (`100.same-tree.cpp`, md5 identical before and after):
- opens as description 80 cols + code 119 cols on top, testcases + result as splits
  across the bottom (15 rows of 50), winbar titles set, no floats left, focus in code;
- focusing the testcases and back to code: console still visible;
- `:Leet desc` off / on: bottom row stays full width under both;
- `:Leet console` hides it, again re-shows it docked;
- `:Leet run` with the runner stubbed (no code sent): console shown docked, focus
  still in the code window.

**Cheatsheet**: new "Layout: test cases and results docked at the bottom" entry in the
LeetCode category (before "Console and test case keys"); `:Leet console` line now
says show / hide the docked console. Same edit in `cheatsheet.md` and
`cheatsheet.user.md`.

## Follow-up: more LeetCode keys in solution files (2026-10-07)

**What**: keys for the `:Leet` commands used often, next to `\r` run / `\s` submit -
chosen by the user from three proposed sets (full mnemonic set picked). All are
buffer-local to solution buffers via `hooks.question_enter`, so nothing outside a
LeetCode solution file changes. Checked first: no `<localleader>` maps existed in a C++
buffer at all.

**Change** - `lua/plugins/leetcode.lua`, `question_enter` hook (final state):

| Key | Command | |
|---|---|---|
| `\r` | `:Leet run` | existing |
| `\s` | `:Leet submit` | existing |
| `\e` | `:Leet desc` | description show/hide |
| `\c` | `:Leet console` | docked console show/hide |
| `\h` | `:Leet hints` | |
| `\i` | `:Leet info` | stats, topics |
| `\t` | `:Leet tabs` | jump to another open question |
| `\o` | `:Leet open` | problem in the browser |
| `\y` | `:Leet yank` | solution code only |
| `\R` | `:Leet reset` | starting template - capital, replaces code (`u` undoes) |
| `\L` | `:Leet last_submit` | last submission - capital, replaces code |

**Why `\e` for the description**: proposed as `\d`; the user wanted it to match the
explorer's `<leader>e`, since the description is a side panel too. `<leader>e`
itself (buffer-local, shadowing the explorer in solution files) was briefly
implemented, then the user chose `<localleader>e` instead - same mnemonic, explorer
left alone everywhere.

**Verified** in a headless `nvim leetcode.nvim` session on an existing problem
(file md5 unchanged): all 11 keys present on the solution buffer; `\e` toggled the
description visible → hidden → visible; `\c` hid the console.

**Cheatsheet**: new "More keys in a solution file" entry in the LeetCode category
(before the layout entry), in both `cheatsheet.md` and `cheatsheet.user.md`.

## Follow-up: docked console grew on every run/submit (2026-10-13)

**What**: each `\r` / `\s` made the testcases + result row taller, squeezing the code.

**Cause**: our own `dock_console`, not the plugin. `Console:run` calls `self:show()`
on every run/submit (`open_on_runcode`, on by default), and the `Console.show` wrapper
re-docks. Re-docking windows that are already splits goes through
`nvim_win_set_config`, which removes and re-inserts each window: pulling testcases out
gives its rows to result beside it, re-inserting it at the bottom with the remembered
`height` takes fresh rows from above, and moving result back next to it hands result's
rows to testcases again. Reproduced headless with the same calls: 15 -> 23 -> 35 -> 38
-> 41 -> 44 rows over six re-docks, the code window down to 3 rows. The first dock
(from floats) was always right, which is why opening a question looked fine.

**Fix** - `lua/plugins/leetcode.lua`, `dock_console`: after the two moves, pin the
row with `vim.api.nvim_win_set_height(tc.winid, height)`. `height` is still read
before moving, so a height you set by resizing is kept. Verified with the same
reproduction: 15 rows on all six re-docks, also after a `:Leet desc`-style full-height
left split, with the code window getting its space back.
