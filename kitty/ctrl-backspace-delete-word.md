# Ctrl+Backspace deletes the previous word (kitty-wide)

**Date:** 2026-10-02
**Category:** kitty
**Files touched:** `~/.config/kitty/kitty.conf` (copy in [`files/`](files/.config/kitty/kitty.conf)), `~/.config/nvim/lua/config/keymaps.lua` (mapping removed; it was never in the stored copy), `~/.config/nvim/cheatsheet.md` (copy in [`neovim/files/`](../neovim/files/.config/nvim/cheatsheet.md))

<!-- graph:begin -->
**Graph:** [[kitty]] · [[Neovim]] · [[Antigravity CLI]]
<!-- graph:end -->

## What
kitty now turns Ctrl+Backspace into Ctrl+W (`\x17`) for every program running in it,
so it deletes the previous word everywhere — shell, Neovim insert/command-line mode,
and TUI apps like `agy` (Antigravity CLI).

## Why
Ctrl+Backspace didn't delete a word in `agy`. By default kitty sends `^H` (`0x08`) for
Ctrl+Backspace in legacy mode, or a distinct `CSI 127;5u` to apps that enable the kitty
keyboard protocol. Apps vary: `agy` (a Go/charmbracelet TUI) treats `^H` as a one-char
backspace and only deletes a word on Ctrl+W or Alt+Backspace. Neovim had no default for
`<C-BS>` at all. Ctrl+W is the near-universal "delete word before cursor" key, so
sending it from the terminal fixes every app at once instead of one config per app.

## Change
`~/.config/kitty/kitty.conf`:
```conf
# Ctrl+Backspace deletes the previous word in every program (sends Ctrl+W)
map ctrl+backspace send_text all \x17
```
Reload: Ctrl+Shift+F5 in a kitty window, or `pkill -USR1 -x kitty` to reload all of them.

**Verified live**: sent a real Ctrl+Backspace (via Hyprland's `send_shortcut`) to a
kitty window running `head -c 1 | od -tx1`; it received `17`.

## Notes
- **Supersedes a Neovim-only fix (2026-09-23)**: `keymaps.lua` had mapped `<C-BS>` and
  `<C-h>` to `<C-w>` in insert/command-line mode, deliberately avoiding this kitty
  mapping. That record sat unmerged on branch `worktree-nvim-ctrl-backspace`. When `agy`
  showed the same problem, the global kitty mapping was chosen instead and the nvim
  mappings were removed as redundant (nvim now just receives `<C-w>`). This also gives
  insert-mode `<C-h>` back its default one-char backspace.
- **Trade-offs accepted**:
  - Ctrl+Backspace now does whatever Ctrl+W means in each app. In Neovim normal mode
    that is the window-command prefix. In fish it is `backward-kill-path-component`,
    which stops at `/` and similar separators rather than at punctuation.
  - No program can see a real Ctrl+Backspace any more.
  - The fix only applies inside kitty, so a different terminal would need its own
    equivalent.
- **Narrower alternative, if the global mapping ever gets in the way**: kitty ≥ 0.36
  can scope a mapping to the focused program — `map --when-focus-on cmdline:agy
  ctrl+backspace send_text all \x17` (untested here).
- A claim that "zsh maps `^H` to backward-kill-word by default" is wrong: stock zsh and
  oh-my-zsh bind `^H` to a single-char backspace. The login shell here is fish anyway.
