# Screenshots: fixed the broken satty pipeline

**Date:** 2026-09-14
**Category:** mango
**Files touched:** none (package install only — `~/.config/noctalia/config.toml` and

<!-- graph:begin -->
**Graph:** [[Mango]] · [[Noctalia]] · [[Monitors]]
<!-- graph:end -->

`~/.config/satty/config.toml` were already correctly set up, just missing the binary)

## What
`Print` / `SUPER+SHIFT+P` (full screen), `SUPER+ALT+P` (all monitors), and `F6` (region)
all capture a screenshot and open it in `satty` for annotation, where `Ctrl+S` saves to
`~/Pictures/satty-<timestamp>.png` and `Ctrl+C` copies to clipboard — same flow for both
full-screen and region, by user's choice (no auto-save/auto-copy bypass).

## Why
This machine uses `noctalia`'s built-in screenshot commands (`noctalia msg
screenshot-fullscreen` / `screenshot-region`), not the raw `grim`/`slurp` binds shown in
Mango's own docs (`https://mangowm.github.io/docs/screenshot`) — those docs describe a
DIY approach that isn't what's actually configured here. The real config
(`~/.config/noctalia/config.toml`'s `[shell.screenshot]` section) was already fully
correct — `pipe_to_command = true`, `pipe_command = "satty -f -"` — and `satty`'s own
config (`~/.config/satty/config.toml`) already had `copy-command = "wl-copy"` and a
sensible `output-filename` set. The only actual problem: **`satty` itself was never
installed**, so every screenshot silently vanished (captured, then piped into a
nonexistent command). Fixed with `sudo pacman -S satty` (official `extra` repo, no AUR
needed).

## Change
```
sudo pacman -S satty
```
No config files needed editing — everything was already correctly configured, just
missing the binary.

## Notes
- Considered making `Print` auto-save-and-copy without opening satty (bypassing
  annotation for the "just capture everything" case), via a custom `grim`+`wl-copy`
  script. Built and then explicitly discarded — user wants satty's manual Ctrl+S/Ctrl+C
  choice for every screenshot, full-screen included, not just region.
- No OCR/"extract text" feature exists anywhere in this stack (`grim`/`slurp`/`satty`) —
  confirmed via Mango's own docs page and satty's feature set (pure annotation, no text
  recognition). That's a KDE Spectacle-specific feature. `normcap` is the standalone
  equivalent if ever wanted — not set up.
- Confirmed live: `noctalia msg screenshot-fullscreen` now successfully launches
  `satty -f -` (previously failed silently with no visible error, no saved file, no
  clipboard content, nothing).
