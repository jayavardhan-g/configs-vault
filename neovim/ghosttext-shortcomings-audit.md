# GhostText shortcomings audit

**Date:** 2026-10-12
**Category:** neovim
**Files touched:** none by the audit itself - the fixes are in [[ghosttext]] (server) and [[ghosttext-extension|the patched extension]]

<!-- graph:begin -->
**Graph:** [[Neovim]] · [[Zen Browser]] · [[GhostText]]
<!-- graph:end -->

## What
A read-through of the whole GhostText chain - the Zen add-on (GhostText 26.5.12),
`nvim-ghost.nvim` (server v0.5.2) and `lua/plugins/ghosttext.lua` - listing every
shortcoming found, and what became of each.

## Why
Two known bugs prompted it: pressing Escape cleared the website's text box, and
commenting several lines in a web code editor arrived in Neovim as one commented line.
Asked to find what else was wrong, then to fix whatever could be fixed.

## Change
Status per shortcoming. *Server* = fixed by the Lua server that replaced nvim-ghost,
*Add-on* = fixed in the patched extension, *Config* = fixed in `ghosttext.lua`.

### The two reported bugs
| Shortcoming | Cause | Status |
|---|---|---|
| Multi-line comment arrives as one line | Bridge throttle kept the first call's arguments; Ace fires one change per line | Add-on |
| Escape clears the field | Rich editors discard `innerHTML` writes and restore their own (empty) model; the next keystroke then wiped Neovim's copy too | Add-on. React `<textarea>`s were suspected first but tested fine in Firefox |

### Browser add-on
| Shortcoming | Status |
|---|---|
| Contenteditable read/written as HTML (`<p>`, `&amp;` in Neovim; `<b>` typed in Neovim renders) | Add-on: plain text both ways |
| Monaco/CM6 replaced the whole document per keystroke - cursor jumps, Monaco undo wiped | Add-on: changed span only |
| CodeMirror 6 polled every 500 ms | Add-on: 100 ms |
| Current CodeMirror 6 not detected at all (`cmView` renamed `cmTile`) | Add-on (found while testing) |
| Ace ignored changes the page made itself | Add-on |
| Monaco/CM5 checked only the first event per 50 ms window | Add-on |
| Plain textareas written via `.value` + fake key events | Add-on: real input events (`execCommand`), fallback kept |
| Language never sent (`syntax: ""`) | Add-on + Server: editor language -> filetype |
| Listeners leaked on reconnect (CM5/Monaco/Ace) | Add-on |
| Keep-alive ping every 5 s forever | Add-on |
| "Disconnect GhostText on this page" / Disconnect shortcut threw | Add-on (found while reading `background.js`) |
| Refused WebSocket reported "ready", then silently dropped | Add-on |
| No single-line `<input>`, no shadow-DOM fields | Not fixable without a redesign |
| Pages in the back/forward cache keep their session open | Not fixed (browser behaviour) |

### nvim-ghost server
| Shortcoming | Status |
|---|---|
| Thread race on the "skip next event" flag: lost Neovim edits or bounced stale text | Server: single-threaded, compares against last agreed text |
| Each change sent twice | Server: one message per tick |
| Whole buffer rewritten per browser message (undo, cursor, marks churn) | Server: changed lines only |
| Cursor sent in bytes/code points; browsers use UTF-16 | Server: UTF-16 both ways |
| Any web page could open a WebSocket to Neovim | Server: Origin check (found during the audit) |
| `tabe` steals focus; `:q` ends the session; no reconnect | Kept as-is (behaviour choice) |
| Crash when no Neovim focused; `.remove()` on non-list; `ValueError` on unknown session | Server (rewritten) |
| Unmaintained since Nov 2024 | Server replaced |

### `ghosttext.lua`
| Shortcoming | Status |
|---|---|
| `User` autocmd tagged whichever buffer was current (two fields at once -> wrong buffer) | Config: `GhostTextOpen` carries the buffer |
| Hostname-shaped event names needed a heuristic filter | Config: gone with the new event |
| `:w` errors in ghost buffers (`nofile`) | Kept; use `<leader>cf` (documented earlier) |

## Notes
- Test evidence: the e2e suite in `neovim/ghosttext-extension/tests/` scores 34/34 on
  the patched add-on and 15/34 on stock 26.5.12, and those failures reproduce both
  reported bugs.
- The site where Escape cleared the field was never named, so it's inferred, not
  confirmed. If it recurs, check whether that site uses a rich editor other than
  Lexical/ProseMirror.
- Superseded setup: [[ghosttext-browser-editing]] (original nvim-ghost install).
