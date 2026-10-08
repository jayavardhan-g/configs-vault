# Vim-flavored Zen keyboard shortcuts (LazyVim-inspired)

**Date:** 2026-09-20
**Category:** zen-browser
**Files touched:** `~/.var/app/app.zen_browser.zen/.zen/nnwin01.Nani/zen-keyboard-shortcuts.json` (live), mirrored in `~/dotfiles/zen/zen-keyboard-shortcuts.json`

<!-- graph:begin -->
**Graph:** [[Neovim]] · [[Zen Browser]]
<!-- graph:end -->

## What
Remapped a handful of Zen's in-browser keyboard shortcuts to echo conventions from
Jayavardhan's actual LazyVim setup ([[../neovim/lazyvim-migration]]), decided one item at a
time against real evidence rather than generic vim folklore. See [[windows-profile-migration]]
for how the Nani profile (where these live) got here in the first place.

## Why
Wanted muscle-memory overlap between Neovim and browsing. Two things made this trickier
than "just copy vim's keys":
1. Zen's shortcut system only supports single simultaneous chords — no vim-style
   leader-key two-step sequences (`<leader>-`, `<leader>|`), so literal key characters had
   to be re-paired with a modifier that doesn't collide with anything already bound.
2. This machine's WM (Mango, not Hyprland — see `cachyos/keybindings/`) intercepts some
   modifier+arrow combos globally before they ever reach the browser, so a couple of
   Zen's own *default* shortcuts (workspace forward/backward) were silently dead already,
   independent of any vim styling.

## Change

Compared against LazyVim's actual defaults, fetched from
`https://raw.githubusercontent.com/LazyVim/LazyVim/main/lua/lazyvim/config/keymaps.lua`
(not assumed from memory) — confirmed `<leader>-`/`<leader>|` really do mean split-below /
split-right there.

| Action | Before | After |
|---|---|---|
| Back (added, didn't replace existing Alt+←/Ctrl+[) | — | **Alt+H** |
| Forward (added, didn't replace existing Alt+→/Ctrl+]) | — | **Alt+L** |
| Split view horizontal | Ctrl+Shift+\\ | **Alt+-** |
| Split view vertical | Ctrl+\\ | **Alt+\|** (Alt+Shift+\\) |
| Save page | Ctrl+Alt+Shift+S | **Ctrl+S** |
| Zen workspace backward | Ctrl+Alt+← (dead — see below) | **Ctrl+Alt+H** |
| Zen workspace forward | Ctrl+Alt+→ (dead — see below) | **Ctrl+Alt+L** |

Deliberately left unchanged: restore-closed-tab (stayed Ctrl+Shift+T only, declined adding
Ctrl+U), and all 10 workspace-switch-N slots (stayed unbound — no real vim analog, and
Ctrl+1-9 was already claimed by an earlier tab-switching customization).

**Second pass, same day — compact mode / sidebar / split-view cleanup:**

| Action | Before | After |
|---|---|---|
| Compact mode toggle | Ctrl+Alt+C | **Alt+C** |
| Legacy generic sidebar toggle (`toggleSidebarKb`, pre-dates Zen's own sidebar concept) | Ctrl+Alt+Z | **disabled** (redundant with `zen-toggle-sidebar` = Ctrl+B) |
| Split view: close/unsplit | Ctrl+/ | **Alt+/** |
| Split view: new empty split | Ctrl+Shift+* | **Alt+N** |

The new-empty-split key deliberately avoided `Alt+\` even though it was free — that would
have shared a physical key with the existing `Alt+|` (= Alt+Shift+\\) vertical-split
binding, differing only by whether Shift is held. Technically valid (Firefox treats
Shift-state as part of the chord, same mechanism already used by its own default
Ctrl+=/Ctrl+Shift+= zoom bindings), but too easy to mis-press in practice — picked `Alt+N`
(free, no shared key, mnemonic "New") instead.

Also surveyed the full sidebar-related shortcut family before deciding what (not) to
touch: `zen-toggle-sidebar` (Ctrl+B, main sidebar), `key_gotoHistory` (Ctrl+H, history
sidebar), and `viewBookmarksSidebarKb` (Ctrl+Alt+B, bookmarks sidebar) were all left
alone — already coherent from the first pass. `viewGenaiChatSidebarKb` (Ctrl+Alt+X, AI
chat sidebar) was suggested a move to Ctrl+Alt+A but not decided on yet. `viewOpenTabsSidebarKb`
(a vertical-tabs-style sidebar) is disabled/unbound by default in stock Zen — noted as a
real dead feature, not yet enabled either way.

Applied via a small Python script editing the shortcuts JSON directly (Zen was fully
closed at the time — profile lock/`.parentlock` checked clear first), then verified by
launching `-P Nani --new-instance` and confirming a real process tree spawned (systemd
journal showed `1.5G memory peak`, `13.2s CPU / 6s wall` — a genuine full startup, not a
crash) before mirroring the result into `~/dotfiles` and pushing.

**Third pass, same day — propagating to Nightmare/Study/Fake.** All testing above was
against Nani only. Jayavardhan then tested in the **Study** profile and found none of the
changes present — each of the four imported profiles has its own fully independent
`zen-keyboard-shortcuts.json`; editing Nani's file never touches the other three.

Before fixing this, diffed Nightmare/Study/Fake against each other and found they were
**not** on stock Windows defaults either — each already had its own divergent
customizations, different from both the Zen defaults *and* from each other (e.g. Study's
original file already had `zen-split-view-horizontal` on `Alt+-` and `goBackKb` on
`Alt+h`, coincidentally close to but not identical with today's Nani choices — most likely
prior independent experimentation on Windows, given the profile names Nightmare/Study/Fake
read as test/throwaway profiles versus Nani as the real daily driver). Flagged this to
Jayavardhan before touching anything since overwriting would discard whatever was actually
in there — confirmed **overwrite anyway**, since these three were being treated as
disposable. Copied Nani's finished `zen-keyboard-shortcuts.json` over all three verbatim
(profile lock checked clear on all four first), then verified each with a real
`-P <name> --new-instance` launch before closing. `~/dotfiles` still only tracks Nani's
copy — matches the Windows-side `sync.ps1`'s own single-profile scope (see that repo's
README), so Nightmare/Study/Fake's shortcuts exist on disk only, not mirrored to git.

## Notes
- **Collision-checked at both layers before committing to anything:**
  - *Zen-internal*: `zen-glance-expand` already defaults to Ctrl+O, which blocked an
    earlier plan to bind Back to Ctrl+O (vim's literal jump-back command) — resolved by
    using Alt+H instead and leaving glance-expand untouched.
  - *WM-level*: read the live `~/.config/mango/cfg/keybinds.conf` (not just the `cachyos/`
    docs, which reference the separate/older `~/.config/hypr/config/binds.lua` — this
    machine runs Mango day-to-day, not Hyprland) to confirm every new binding was actually
    free. Found that `bind = CTRL+ALT, Left/Right, resizewin` globally intercepts the
    exact combo Zen's default workspace forward/backward shortcuts use — meaning those
    two shortcuts were non-functional from the moment Nani was imported, unrelated to
    this session's changes. Fixed as part of this pass since it was already broken.
  - All WM-level `hjkl` binds require `SUPER` as part of the combo, so bare `Alt+H`/`Alt+L`
    and `Ctrl+Alt+H`/`Ctrl+Alt+L` were safe from that whole family of binds.
- **Why not port `Shift+H`/`Shift+L` (LazyVim buffer-prev/next) or `Ctrl+hjkl`
  (LazyVim window-pane focus)?** Checked Zen's full default action list — it exposes no
  "next/previous tab" cycling command and no "move focus between split-view panes"
  command at all in this shortcut system. Not a collision issue, the hooks just don't
  exist yet.
- **Shortcut file is not duplicated into this repo's `files/` tree.** Unlike other
  zen-browser entries, the canonical stored copy lives in the dedicated
  `~/dotfiles` repo (`zen/zen-keyboard-shortcuts.json`, synced via manual `cp` + commit
  each time it's edited — see that repo's own README for the Windows-side `sync.ps1`
  equivalent). Storing the same ~34KB blob a third time here would just drift out of sync
  with the actual source of truth; this entry documents the *decisions*, `~/dotfiles`
  holds the *file*.
