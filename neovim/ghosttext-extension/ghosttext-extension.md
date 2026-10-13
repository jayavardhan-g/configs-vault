# Patched GhostText extension

<!-- graph:begin -->
**Graph:** [[Neovim]] · [[Zen Browser]] · [[GhostText]]
<!-- graph:end -->

[GhostText](https://github.com/fregante/GhostText) 26.5.12 with the bugs below
fixed, installed in Zen in place of the AMO version as "GhostText (patched)"
(`ghosttext-patched@configs.local`). Pairs with the Lua GhostText server in
`~/.config/nvim/lua/ghosttext/` - see [[ghosttext]] for the whole story and
[[ghosttext-shortcomings-audit]] for everything the audit found.

- **Source**: fork [jayavardhan-g/GhostText](https://github.com/jayavardhan-g/GhostText),
  branch `patched` - one commit per fix on top of upstream; `main` mirrors
  upstream. Local clone `~/claude/GhostText` (`upstream` remote = fregante),
  worked on in its `.claude/worktrees/patched` worktree.
- **Builds**: GitHub Actions only, on `v*` tags (`.github/workflows/build-xpi.yml`
  in the fork) - nothing is built on this PC, and npm isn't installed here.
- **Releases**: [github.com/jayavardhan-g/GhostText/releases](https://github.com/jayavardhan-g/GhostText/releases).
- `tests/` (this folder) - server tests and a headless-Firefox end-to-end suite.

## What's fixed

| Upstream bug | Symptom | Fix |
|---|---|---|
| Throttle kept the **first** call's arguments in each 50 ms window | Commenting several lines in an Ace editor reached Neovim as one commented line (and the next Neovim keystroke reverted the rest in the page) | Throttle reads the editor when it fires |
| Ace bridge only forwarded edits made through an Ace command | Page-made changes (reset button, templates, language switch) never reached Neovim | Forward every change; our own writes are skipped with a flag instead |
| Contenteditable fields read and written as `innerHTML` | Neovim showed `<p>`, `&amp;`; typing `<b>` in Neovim made bold; rich editors (Lexical, ProseMirror, Slate...) discarded the write, so the page "cleared" on the next key/Escape and the next browser keystroke wiped Neovim's text too | Read as plain text (blocks/`<br>` -> newlines); write by selecting the field and `execCommand("insertText")`, which editors accept as real input |
| Textareas written with `.value =` plus fake key events | Works on React in Firefox, but bypasses undo and frameworks that only trust real input | Replace only the changed span via `execCommand("insertText")`; fall back to `.value` + `input` |
| CodeMirror 6 looked for `.cmView` | Current `@codemirror/view` (6.39+) renamed it `cmTile`: field connected but never sent anything | Resolve the view like `EditorView.findFromDOM` does |
| Monaco / CM6 / Ace replaced the whole document on every Neovim keystroke | Page cursor jumped to the top, Monaco's undo history was wiped | Replace only the changed span (`pushEditOperations`, CM6 `dispatch`, Ace `session.replace`) |
| CodeMirror 6 polled every 500 ms | Up to half a second lag | 100 ms, comparing immutable docs by identity |
| (ours, v26.5.12.1) CM6 poll saw text written from Neovim as a page edit | Stale copies bounced back while typing fast in Neovim: characters lost or landing behind the cursor ("browfox n") | Bridge records the doc it wrote; fixed in v26.5.12.2 |
| Bridges for CM5/Monaco/Ace never removed their listeners | Reconnecting a field duplicated every message | All bridges honour `gt:kill`; one bridge per element |
| `syntax` was always `""` | Neovim never learned the language | Sends Monaco language id / Ace mode / CodeMirror mode; the server maps it to a filetype |
| Minifier renamed `stopGT` inside the injected function | "Disconnect GhostText on this page" and the Disconnect shortcut threw `ReferenceError` | Call `globalThis.stopGT()` |
| A refused WebSocket still reported "ready" | Field silently disconnected instead of showing "Unable to connect" | Throw when the socket didn't open |
| Keep-alive message every 5 s forever | Wasted wake-ups after disconnecting | Only while a field is connected |

Not fixable in the extension: single-line `<input>` fields, fields inside
shadow DOM, and pages kept in the back-forward cache keep their session open
until evicted.

## Release a new version

```sh
cd ~/claude/GhostText/.claude/worktrees/patched
# commit to `patched`, then:
git tag -a v26.5.12.4 -m "GhostText (patched) 26.5.12.4"
git push origin patched v26.5.12.4
```
The workflow sets the manifest version from the tag (at most four numbers),
runs `npm ci && npm run build` on GitHub, and attaches
`ghosttext-patched-<version>.xpi` to a release. It skips upstream's
`pre:build`, which rewrites `web_accessible_resources` into the Manifest V2
shape that Parcel rejects. Upstream's `CI` workflow is disabled on the fork,
so plain pushes build nothing.

After an upstream release: `git fetch upstream`, rebase `patched` onto the
new upstream tag, fix conflicts, tag.

## Install (Zen)

Zen is built without `MOZ_REQUIRE_SIGNING`, so unsigned add-ons can be
installed permanently (stock Firefox release builds can't do this):

1. `about:config` -> `xpinstall.signatures.required` = `false` (per profile).
2. Open the release page and click the `.xpi` (or `gh release download <tag>
   -R jayavardhan-g/GhostText`, then `about:addons` -> gear -> *Install Add-on
   From File...*). A higher version installs as an update.
3. First time only: remove the original GhostText (same `Ctrl+Shift+H`
   shortcut). Settings start at the defaults (port 4001), which is what the
   server uses.

## Tests

```sh
gh release download v26.5.12.3 -R jayavardhan-g/GhostText -D /tmp/gt
python3 tests/test_server.py      # Lua server, one Neovim (26 checks)
python3 tests/test_hub.py         # several Neovims + legacy nvim-ghost takeover
python3 tests/test_e2e.py /tmp/gt/ghosttext-patched-26.5.12.3.xpi release
ONLY=typing python3 tests/test_e2e.py /tmp/gt/ghosttext-patched-26.5.12.3.xpi release
FULLCONFIG=1 ONLY=typing python3 tests/test_e2e.py /tmp/gt/ghosttext-patched-26.5.12.3.xpi release
```
`test_e2e.py` drives headless Firefox over Marionette, loads the `.xpi` as a
temporary add-on, clicks its toolbar action from chrome context (the real
injection path), and checks Ace, Monaco, CodeMirror 6, a React textarea,
ProseMirror, Lexical and a plain contenteditable against a headless Neovim.
`ONLY=typing` types a sentence into Neovim key by key (and into the page) for
every editor and requires both sides to match with nothing sent back from the
page meanwhile; `FULLCONFIG=1` runs Neovim with the real `~/.config/nvim`
instead of `--clean`. Lexical's browser-typing check is skipped: Lexical
drops Marionette's synthetic keys even without GhostText.

Results: upstream 26.5.12 15/34 (2026-10-12); GitHub-built v26.5.12.3 34/34
and typing 27/27 (2026-10-13).

## Notes

- Superseded 2026-10-13: until the fork existed, this folder held `build.py`,
  which unzipped the official `.xpi`, patched its minified JS with exact-string
  replacements and swapped in our bridge script (v26.5.12.1-.2). Retired once
  the GitHub-built v26.5.12.3 was confirmed in daily use: the patches broke on
  every upstream release and duplicated the fork's commits. It's in this repo's
  git history if ever needed.
