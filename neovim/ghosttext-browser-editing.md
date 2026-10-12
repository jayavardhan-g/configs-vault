# Neovim: edit browser text fields with GhostText

**Date:** 2026-09-16
**Category:** neovim
**Files touched:** `~/.config/nvim/lua/plugins/ghosttext.lua` (new)

<!-- graph:begin -->
**Graph:** [[Neovim]] · [[GhostText]]
<!-- graph:end -->

## What
Installed the `subnut/nvim-ghost.nvim` plugin (via LazyVim's `lua/plugins/` spec
convention) so the [GhostText](https://github.com/GhostText/GhostText) browser
extension can send any textarea/contenteditable field to a live-synced buffer in a
running Neovim instance, instead of editing directly in the browser.

## Why
Previously used the GhostText Chrome extension paired with a GUI/other editor;
switched to routing it through terminal Neovim instead. `nvim-ghost.nvim` was chosen
over the alternatives (Textern, Tridactyl) because it needs zero native-messaging-host
setup — no script to write or register, just the extension plus this one plugin — and
ships a bundled Linux binary so no Python dependency either. Works identically with any
GhostText-compatible browser (Chrome, Firefox, Zen), not just one.

## Change
`~/.config/nvim/lua/plugins/ghosttext.lua`:
```lua
return {
  {
    "subnut/nvim-ghost.nvim",
    lazy = false,
  },
}
```
`lazy = false` is required — the plugin needs to start listening on port 4001
immediately on Neovim startup, not on some lazy-load trigger.

Install the GhostText extension in the browser (Chrome Web Store / Firefox Add-ons —
works in Zen too, since it's Firefox-based). No other browser-side config needed; the
extension defaults to port 4001, matching this plugin's default.

## Notes
- **Superseded 2026-10-12**: `nvim-ghost.nvim` was replaced by a Lua server in
  `lua/ghosttext/` and the AMO extension by a patched build - see the last entry in
  [[ghosttext]]. The `Change` above is the original 2026-09-16 state, kept for
  history; the current `lua/plugins/ghosttext.lua` is in `files/`.
- Usage: open a Neovim instance (leave it running), then click the GhostText icon in
  the browser toolbar while focused in a textarea/contenteditable field. It opens as a
  synced buffer in that Neovim instance.
- Only works on fields the extension recognizes as textarea/contenteditable — not
  single-line `<input>` boxes (e.g. search bars).
- Zero dependencies on Linux (bundled binary in the plugin's `nvim-ghost-linux.tar.gz`),
  so no extra system packages needed.
- Per-site settings (e.g. auto-set filetype to markdown for a given domain) are
  possible via the `nvim_ghost_user_autocommands` augroup — see the plugin's own
  README, not reproduced here since it wasn't configured.
- This machine's live `~/.config/nvim` runs LazyVim (`lua/plugins/*.lua` spec files) —
  see [[neovim-minimal-ssh-friendly-setup]] for the fuller Neovim writeup. That entry
  currently documents an older hand-rolled plugin loader that's no longer accurate (the
  config was switched to LazyVim at some point without being recorded); that discrepancy
  is deliberately not fixed here, flagged for a future session.
