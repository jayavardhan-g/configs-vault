# Patched GhostText extension

<!-- graph:begin -->
**Graph:** [[Neovim]] · [[Zen Browser]]
<!-- graph:end -->

A rebuilt [GhostText](https://github.com/fregante/GhostText) 26.5.12 with the
bugs below fixed, installed in Zen in place of the AMO version. Pairs with the
Lua GhostText server in `~/.config/nvim/lua/ghosttext/` - see
[[ghosttext]] for the whole story.

- `build.py` - takes the upstream `.xpi`, applies exact-match patches to the
  minified `ghost-text.js` / `background*.js`, swaps in our
  `advanced-editors-messenger.js`, renames the add-on, zips it.
- `advanced-editors-messenger.js` - full replacement for upstream's page-world
  bridge to CodeMirror 5/6, Monaco and Ace (readable source, not minified).
- `ghosttext-patched-<version>.xpi` - the built add-on (unsigned).
- `tests/` - server tests and a headless-Firefox end-to-end suite.

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
| Bridges for CM5/Monaco/Ace never removed their listeners | Reconnecting a field duplicated every message | All bridges honour `gt:kill`; one bridge per element |
| `syntax` was always `""` | Neovim never learned the language | Sends Monaco language id / Ace mode / CodeMirror mode; the server maps it to a filetype |
| Minifier renamed `stopGT()` to `l()` inside the injected function | "Disconnect GhostText on this page" and the Disconnect shortcut threw `ReferenceError` | Call `stopGT()` |
| A refused WebSocket still reported "ready" | Field silently disconnected instead of showing "Unable to connect" | Throw when the socket didn't open |
| Keep-alive message every 5 s forever | Wasted wake-ups after disconnecting | Only while a field is connected |

Not fixable in the extension: single-line `<input>` fields, fields inside
shadow DOM, and pages kept in the back-forward cache keep their session open
until evicted.

## Build

```sh
python3 build.py ~/.var/app/app.zen_browser.zen/.zen/<profile>/extensions/ghosttext@bfred.it.xpi
```
The upstream `.xpi` is also downloadable from addons.mozilla.org. `build.py`
refuses any upstream version other than the one the patches were written
against (`UPSTREAM_VERSION`); after an upstream update, bump it, rebuild, and
fix whichever patch reports a match count other than 1.

## Install (Zen)

Zen is built without `MOZ_REQUIRE_SIGNING`, so unsigned add-ons can be
installed permanently (stock Firefox release builds can't do this):

1. `about:config` -> `xpinstall.signatures.required` = `false` (per profile).
2. `about:addons` -> gear -> *Install Add-on From File...* -> the `.xpi`.
   (Flatpak: the file chooser goes through the portal, so any path works.)
3. Remove the original GhostText (same `Ctrl+Shift+H` shortcut).
4. The add-on id is `ghosttext-patched@configs.local`, so its settings start at
   the defaults (port 4001), which is what the server uses.

## Tests

```sh
python3 tests/test_server.py      # Lua server, one Neovim (22 checks)
python3 tests/test_hub.py         # several Neovims + legacy nvim-ghost takeover
python3 tests/test_e2e.py ghosttext-patched-26.5.12.1.xpi patched
```
`test_e2e.py` drives headless Firefox over Marionette, loads the build as a
temporary add-on, clicks its toolbar action from chrome context (the real
injection path), and checks Ace, Monaco, CodeMirror 6, a React textarea,
ProseMirror, Lexical and a plain contenteditable against a headless Neovim.
2026-10-12: patched 34/34; upstream 26.5.12 15/34.
