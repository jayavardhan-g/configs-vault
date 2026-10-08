# CachyOS's shell configs are package-owned — never edit them directly

**Date:** 2026-09-21
**Category:** system
**Files touched:** none persisted here — this entry records what *not* to edit. The alias that triggered it (since removed in favour of [[utf8-locale-name]]) is recorded in [[btop-force-utf-alias]].

## What
CachyOS ships its shell defaults as root-owned files inside pacman packages:

| Package | File |
|---|---|
| `cachyos-fish-config` | `/usr/share/cachyos-fish-config/cachyos-config.fish` |
| `cachyos-zsh-config` | `/usr/share/cachyos-zsh-config/cachyos-config.zsh` |

The stock `~/.config/fish/config.fish` and `~/.zshrc` are each nearly empty — one
`source` line pointing at the file above. That makes the package file *look* like "the"
shell config, so it's the tempting place to add an alias. It isn't: pacman owns those
paths and will overwrite them on the next update of either package, silently reverting
anything added there.

## Why
Hit this while adding a `btop --force-utf` alias: it went into
`/usr/share/cachyos-zsh-config/cachyos-config.zsh` (via `sudo nvim`), which both required
root for a personal preference *and* put it on a file that pacman would later reset.

## Change
Add personal aliases/settings to the **user-owned** rc file, *after* the `source` line so
they override the CachyOS defaults:

```fish
# ~/.config/fish/config.fish
source /usr/share/cachyos-fish-config/cachyos-config.fish

alias btop="btop --force-utf"
```
```zsh
# ~/.zshrc
source /usr/share/cachyos-zsh-config/cachyos-config.zsh

alias btop="btop --force-utf"
```

Check whether a package file has already been hand-edited (a checksum mismatch means it
was, and that the edit is living on borrowed time):
```bash
pacman -Qkk cachyos-zsh-config cachyos-fish-config
```

Restore an edited one back to the packaged version:
```bash
sudo pacman -S --overwrite '*' cachyos-zsh-config
```

## Notes
- `pacman -Qkk` reports `SHA256 checksum mismatch` / `Size mismatch` for a modified file —
  a quick way to audit which system files have been hand-edited over time.
- These are plain files under `/usr/share`, **not** pacman `backup=` entries, so an update
  overwrites them outright — there's no `.pacnew`/`.pacsave` left behind and no prompt.
  The change just disappears, which is what makes this worth writing down.
- Classified here rather than in a shell folder because the trap is created by CachyOS's
  packaging choice specifically — a plain Arch or any non-CachyOS install has no
  `cachyos-*-config` package and no root-owned file in the sourcing path.
